;; Pattern Matching Code Generation
;; Handles code generation for pattern matching constructs (match statements, pattern testing)

(module $codegen_patterns
  ;; Import memory for code generation workspace
  (import "lexer_memory" "memory" (memory 1))

  ;; Import core code generation utilities
  (import "codegen_core" "write_output" (func $write_output (param i32 i32) (result i32)))
  (import "codegen_core" "push_stack" (func $push_stack))
  (import "codegen_core" "pop_stack" (func $pop_stack))
  (import "codegen_core" "get_wasm_type_string" (func $get_wasm_type_string (param i32 i32)))
  (import "codegen_core" "lookup_local_var" (func $lookup_local_var (param i32 i32) (result i32)))

  ;; Import expression generation
  (import "codegen_expressions" "generate_expression" (func $generate_expression (param i32) (result i32)))

  ;; Import AST utilities
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "ast_node_core" "get_child_count" (func $get_child_count (param i32) (result i32)))
  (import "ast_node_core" "get_child" (func $get_child (param i32 i32) (result i32)))
  (import "ast_node_core" "get_node_value" (func $get_node_value (param i32) (result i32)))

  ;; Import AST pattern node types
  (import "ast_node_types" "CTRL_MATCH" (global $CTRL_MATCH i32))
  (import "ast_node_types" "CTRL_MATCH_ARM" (global $CTRL_MATCH_ARM i32))
  (import "ast_node_types" "PAT_LITERAL" (global $PAT_LITERAL i32))
  (import "ast_node_types" "PAT_VARIABLE" (global $PAT_VARIABLE i32))
  (import "ast_node_types" "PAT_TUPLE" (global $PAT_TUPLE i32))
  (import "ast_node_types" "PAT_RECORD" (global $PAT_RECORD i32))
  (import "ast_node_types" "PAT_VARIANT" (global $PAT_VARIANT i32))
  (import "ast_node_types" "PAT_OPTION_SOME" (global $PAT_OPTION_SOME i32))
  (import "ast_node_types" "PAT_OPTION_NONE" (global $PAT_OPTION_NONE i32))
  (import "ast_node_types" "PAT_RESULT_OK" (global $PAT_RESULT_OK i32))
  (import "ast_node_types" "PAT_RESULT_ERR" (global $PAT_RESULT_ERR i32))
  (import "ast_node_types" "PAT_LIST" (global $PAT_LIST i32))
  (import "ast_node_types" "PAT_WILDCARD" (global $PAT_WILDCARD i32))

  ;; Import type checker for type information
  (import "typechecker_main" "get_node_type_info" (func $get_node_type_info (param i32) (result i32)))
  (import "typechecker_main" "TYPE_I32" (global $TYPE_I32 i32))
  (import "typechecker_main" "TYPE_I64" (global $TYPE_I64 i32))
  (import "typechecker_main" "TYPE_F32" (global $TYPE_F32 i32))
  (import "typechecker_main" "TYPE_F64" (global $TYPE_F64 i32))
  (import "typechecker_main" "TYPE_BOOL" (global $TYPE_BOOL i32))
  (import "typechecker_main" "TYPE_STRING" (global $TYPE_STRING i32))
  (import "typechecker_main" "TYPE_OPTION" (global $TYPE_OPTION i32))
  (import "typechecker_main" "TYPE_RESULT" (global $TYPE_RESULT i32))

  ;; Pattern matching state
  (global $pattern_depth (mut i32) (i32.const 0))
  (global $match_label_counter (mut i32) (i32.const 0))
  (global $arm_label_counter (mut i32) (i32.const 0))

  ;; Pattern match buffer for temporary values
  (global $PATTERN_BUFFER_START i32 (i32.const 47104))  ;; After expression buffer
  (global $PATTERN_BUFFER_SIZE i32 (i32.const 2048))
  (global $pattern_buffer_pos (mut i32) (i32.const 0))

  ;; String constants for pattern matching code generation
  (data (i32.const 0x8000) "(block $match_")      ;; 0x8000-0x800E
  (data (i32.const 0x8010) "\n")                   ;; 0x8010
  (data (i32.const 0x8020) "    unreachable\n")   ;; 0x8020-0x802E
  (data (i32.const 0x8030) "  )\n")                ;; 0x8030-0x8033
  (data (i32.const 0x8040) "    (block $arm_")     ;; 0x8040-0x804F
  (data (i32.const 0x8050) "      local.get $match_val\n")  ;; 0x8050-0x8069
  (data (i32.const 0x8060) "      br $match_")     ;; 0x8060-0x806E
  (data (i32.const 0x8070) "    )\n")              ;; 0x8070-0x8073
  (data (i32.const 0x8080) "      i32.const 42\n") ;; 0x8080-0x8091
  (data (i32.const 0x8090) "      i32.ne\n")       ;; 0x8090-0x809A
  (data (i32.const 0x80A0) "      br_if $arm_")    ;; 0x80A0-0x80AF
  (data (i32.const 0x80B0) "      ;; Variable pattern binding\n")  ;; 0x80B0-0x80D0
  (data (i32.const 0x80C0) "      local.set $pattern_var\n")  ;; 0x80C0-0x80DB
  (data (i32.const 0x80D0) "      i32.add\n")      ;; 0x80D0-0x80D8
  (data (i32.const 0x80E0) "      i32.const 4\n")  ;; 0x80E0-0x80ED
  (data (i32.const 0x80F0) "      i32.load\n")     ;; 0x80F0-0x80FD
  (data (i32.const 0x8100) "      i32.const 1\n")  ;; 0x8100-0x8110
  (data (i32.const 0x8110) "      i32.ne\n")       ;; 0x8110-0x811A
  (data (i32.const 0x8120) "      if\n")           ;; 0x8120-0x8127
  (data (i32.const 0x8130) "      else\n")         ;; 0x8130-0x8139
  (data (i32.const 0x8140) "      end\n")          ;; 0x8140-0x8149
  (data (i32.const 0x8150) "      ;; Test for Ok result\n")  ;; 0x8150-0x816A
  (data (i32.const 0x8160) "      ;; Test inner Ok pattern\n")  ;; 0x8160-0x817E
  (data (i32.const 0x8190) "0")                    ;; 0x8190

  ;; Generate code for pattern matching constructs
  ;; @param pattern_node: i32 - AST node pointer for the pattern matching construct
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_pattern_matching (export "generate_pattern_matching") (param $pattern_node i32) (result i32)
    (local $node_type i32)
    (local $result i32)

    ;; Get the node type to determine which pattern matching construct to generate
    (local.set $node_type (call $get_node_type (local.get $pattern_node)))
    (local.set $result (i32.const 0))

    ;; Dispatch based on pattern matching type
    (if (i32.eq (local.get $node_type) (global.get $CTRL_MATCH))
      (then
        (local.set $result (call $generate_match_statement (local.get $pattern_node)))
      )
      (else
        ;; Unsupported pattern matching type
        (local.set $result (i32.const 0))
      )
    )

    (local.get $result)
  )

  ;; Generate WASM code for match statement
  ;; Structure: match expr { pattern1 => expr1, pattern2 => expr2, ... }
  ;; @param match_node: i32 - AST node for match statement
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_match_statement (param $match_node i32) (result i32)
    (local $child_count i32)
    (local $match_expr i32)
    (local $match_label i32)
    (local $arm_count i32)
    (local $i i32)
    (local $arm_node i32)
    (local $result i32)

    ;; Get child count (should have at least match expression + arms)
    (local.set $child_count (call $get_child_count (local.get $match_node)))
    (if (i32.lt_u (local.get $child_count) (i32.const 2))
      (then
        ;; Invalid match statement - need at least expression and one arm
        (return (i32.const 0))
      )
    )

    ;; Get unique label for this match statement
    (local.set $match_label (global.get $match_label_counter))
    (global.set $match_label_counter (i32.add (global.get $match_label_counter) (i32.const 1)))

    ;; First child is the match expression
    (local.set $match_expr (call $get_child (local.get $match_node) (i32.const 0)))

    ;; Generate the match expression (value to match against)
    (if (i32.eqz (call $generate_expression (local.get $match_expr)))
      (then
        ;; Failed to generate match expression
        (return (i32.const 0))
      )
    )

    ;; Store the match value on stack for pattern testing
    (call $push_stack)

    ;; Start match block with label
    (local.set $result (call $write_output
      (i32.const 0x8000)  ;; "(block $match_"
      (i32.const 12)))
    (local.set $result (call $write_match_label (local.get $match_label)))
    (local.set $result (call $write_output
      (i32.const 0x8010)  ;; "\n"
      (i32.const 1)))

    ;; Generate code for each match arm
    (local.set $arm_count (i32.sub (local.get $child_count) (i32.const 1)))
    (local.set $i (i32.const 1))
    (loop $arm_loop
      (if (i32.lt_u (local.get $i) (local.get $child_count))
        (then
          ;; Get match arm node
          (local.set $arm_node (call $get_child (local.get $match_node) (local.get $i)))

          ;; Generate code for this arm
          (if (i32.eqz (call $generate_match_arm (local.get $arm_node) (local.get $match_label)))
            (then
              ;; Failed to generate match arm
              (return (i32.const 0))
            )
          )

          ;; Move to next arm
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $arm_loop)
        )
      )
    )

    ;; If no patterns matched, generate unreachable (should be caught by exhaustiveness checking)
    (local.set $result (call $write_output
      (i32.const 0x8020)  ;; "    unreachable\n"
      (i32.const 15)))

    ;; End match block
    (local.set $result (call $write_output
      (i32.const 0x8030)  ;; "  )\n"
      (i32.const 4)))

    ;; Pop the match value from stack
    (call $pop_stack)

    (i32.const 1)
  )

  ;; Generate WASM code for a single match arm
  ;; Structure: pattern => expression
  ;; @param arm_node: i32 - AST node for match arm
  ;; @param match_label: i32 - Label for the containing match block
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_match_arm (param $arm_node i32) (param $match_label i32) (result i32)
    (local $child_count i32)
    (local $pattern_node i32)
    (local $body_node i32)
    (local $arm_label i32)
    (local $result i32)

    ;; Get child count (should have pattern + body)
    (local.set $child_count (call $get_child_count (local.get $arm_node)))
    (if (i32.ne (local.get $child_count) (i32.const 2))
      (then
        ;; Invalid match arm - need pattern and body
        (return (i32.const 0))
      )
    )

    ;; Get pattern and body nodes
    (local.set $pattern_node (call $get_child (local.get $arm_node) (i32.const 0)))
    (local.set $body_node (call $get_child (local.get $arm_node) (i32.const 1)))

    ;; Get unique label for this arm
    (local.set $arm_label (global.get $arm_label_counter))
    (global.set $arm_label_counter (i32.add (global.get $arm_label_counter) (i32.const 1)))

    ;; Start arm block
    (local.set $result (call $write_output
      (i32.const 0x8040)  ;; "    (block $arm_"
      (i32.const 15)))
    (local.set $result (call $write_arm_label (local.get $arm_label)))
    (local.set $result (call $write_output
      (i32.const 0x8010)  ;; "\n"
      (i32.const 1)))

    ;; Generate pattern test (duplicate match value on stack for testing)
    (local.set $result (call $write_output
      (i32.const 0x8050)  ;; "      local.get $match_val\n"
      (i32.const 26)))

    ;; Generate pattern matching logic
    (if (i32.eqz (call $generate_pattern_test (local.get $pattern_node) (local.get $arm_label)))
      (then
        ;; Failed to generate pattern test
        (return (i32.const 0))
      )
    )

    ;; If pattern matches, generate the arm body
    (if (i32.eqz (call $generate_expression (local.get $body_node)))
      (then
        ;; Failed to generate arm body
        (return (i32.const 0))
      )
    )

    ;; Break out of match after successful arm
    (local.set $result (call $write_output
      (i32.const 0x8060)  ;; "      br $match_"
      (i32.const 15)))
    (local.set $result (call $write_match_label (local.get $match_label)))
    (local.set $result (call $write_output
      (i32.const 0x8010)  ;; "\n"
      (i32.const 1)))

    ;; End arm block
    (local.set $result (call $write_output
      (i32.const 0x8070)  ;; "    )\n"
      (i32.const 6)))

    (i32.const 1)
  )

  ;; Generate pattern testing logic
  ;; @param pattern_node: i32 - AST node for the pattern
  ;; @param arm_label: i32 - Label to break to if pattern doesn't match
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_pattern_test (param $pattern_node i32) (param $arm_label i32) (result i32)
    (local $pattern_type i32)
    (local $result i32)

    ;; Get the pattern type to determine how to test it
    (local.set $pattern_type (call $get_node_type (local.get $pattern_node)))
    (local.set $result (i32.const 0))

    ;; Dispatch based on pattern type
    (if (i32.eq (local.get $pattern_type) (global.get $PAT_LITERAL))
      (then
        (local.set $result (call $generate_literal_pattern_test (local.get $pattern_node) (local.get $arm_label)))
      )
      (else
        (if (i32.eq (local.get $pattern_type) (global.get $PAT_VARIABLE))
          (then
            (local.set $result (call $generate_variable_pattern_test (local.get $pattern_node) (local.get $arm_label)))
          )
          (else
            (if (i32.eq (local.get $pattern_type) (global.get $PAT_WILDCARD))
              (then
                (local.set $result (call $generate_wildcard_pattern_test (local.get $pattern_node) (local.get $arm_label)))
              )
              (else
                (if (i32.eq (local.get $pattern_type) (global.get $PAT_OPTION_SOME))
                  (then
                    (local.set $result (call $generate_option_some_pattern_test (local.get $pattern_node) (local.get $arm_label)))
                  )
                  (else
                    (if (i32.eq (local.get $pattern_type) (global.get $PAT_OPTION_NONE))
                      (then
                        (local.set $result (call $generate_option_none_pattern_test (local.get $pattern_node) (local.get $arm_label)))
                      )
                      (else
                        (if (i32.eq (local.get $pattern_type) (global.get $PAT_RESULT_OK))
                          (then
                            (local.set $result (call $generate_result_ok_pattern_test (local.get $pattern_node) (local.get $arm_label)))
                          )
                          (else
                            (if (i32.eq (local.get $pattern_type) (global.get $PAT_RESULT_ERR))
                              (then
                                (local.set $result (call $generate_result_err_pattern_test (local.get $pattern_node) (local.get $arm_label)))
                              )
                              (else
                                ;; Unsupported pattern type
                                (local.set $result (i32.const 0))
                              )
                            )
                          )
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    )

    (local.get $result)
  )

  ;; Generate test for literal pattern (number, string, boolean)
  ;; @param pattern_node: i32 - AST node for literal pattern
  ;; @param arm_label: i32 - Label to break to if pattern doesn't match
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_literal_pattern_test (param $pattern_node i32) (param $arm_label i32) (result i32)
    (local $token_pos i32)
    (local $result i32)

    ;; Get the token position from pattern node data
    (local.set $token_pos (call $get_node_value (local.get $pattern_node)))

    ;; Generate literal value for comparison
    ;; TODO: This should generate the actual literal value based on token
    (local.set $result (call $write_output
      (i32.const 0x8080)  ;; "      i32.const 42\n"  ;; Placeholder literal
      (i32.const 19)))

    ;; Compare with match value
    (local.set $result (call $write_output
      (i32.const 0x8090)  ;; "      i32.ne\n"
      (i32.const 13)))

    ;; Break to next arm if not equal
    (local.set $result (call $write_output
      (i32.const 0x80A0)  ;; "      br_if $arm_"
      (i32.const 17)))
    (local.set $result (call $write_arm_label (local.get $arm_label)))
    (local.set $result (call $write_output
      (i32.const 0x8010)  ;; "\n"
      (i32.const 1)))

    (i32.const 1)
  )

  ;; Generate test for variable pattern (always matches, binds value)
  ;; @param pattern_node: i32 - AST node for variable pattern
  ;; @param arm_label: i32 - Label to break to if pattern doesn't match
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_variable_pattern_test (param $pattern_node i32) (param $arm_label i32) (result i32)
    (local $token_pos i32)
    (local $result i32)

    ;; Get the token position from pattern node data
    (local.set $token_pos (call $get_node_value (local.get $pattern_node)))

    ;; Variable patterns always match - just bind the value
    ;; TODO: Generate proper variable binding code
    (local.set $result (call $write_output
      (i32.const 0x80B0)  ;; "      ;; Variable pattern binding\n"
      (i32.const 35)))

    ;; Store match value in local variable
    (local.set $result (call $write_output
      (i32.const 0x80C0)  ;; "      local.set $pattern_var\n"
      (i32.const 29)))

    (i32.const 1)
  )

  ;; Generate test for wildcard pattern (always matches, no binding)
  ;; @param pattern_node: i32 - AST node for wildcard pattern
  ;; @param arm_label: i32 - Label to break to if pattern doesn't match
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_wildcard_pattern_test (param $pattern_node i32) (param $arm_label i32) (result i32)
    (local $result i32)

    ;; Wildcard patterns always match - no additional code needed
    (local.set $result (call $write_output
      (i32.const 0x80D0)  ;; "      ;; Wildcard pattern (always matches)\n"
      (i32.const 44)))

    (i32.const 1)
  )

  ;; Generate test for Option::Some pattern
  ;; @param pattern_node: i32 - AST node for Some pattern
  ;; @param arm_label: i32 - Label to break to if pattern doesn't match
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_option_some_pattern_test (param $pattern_node i32) (param $arm_label i32) (result i32)
    (local $inner_pattern i32)
    (local $result i32)

    ;; Test if option is Some (tag = 1)
    (local.set $result (call $write_output
      (i32.const 0x80E0)  ;; "      ;; Test for Some option\n"
      (i32.const 29)))

    ;; Load option tag (first 4 bytes)
    (local.set $result (call $write_output
      (i32.const 0x80F0)  ;; "      i32.load\n"
      (i32.const 15)))

    ;; Compare with Some tag (1)
    (local.set $result (call $write_output
      (i32.const 0x8100)  ;; "      i32.const 1\n"
      (i32.const 17)))
    (local.set $result (call $write_output
      (i32.const 0x8110)  ;; "      i32.ne\n"
      (i32.const 13)))

    ;; Break to next arm if not Some
    (local.set $result (call $write_output
      (i32.const 0x80A0)  ;; "      br_if $arm_"
      (i32.const 17)))
    (local.set $result (call $write_arm_label (local.get $arm_label)))
    (local.set $result (call $write_output
      (i32.const 0x8010)  ;; "\n"
      (i32.const 1)))

    ;; TODO: Generate code for inner pattern if it exists
    (local.set $inner_pattern (call $get_node_value (local.get $pattern_node)))
    (if (local.get $inner_pattern)
      (then
        ;; Load option value and test inner pattern
        (local.set $result (call $write_output
          (i32.const 0x8120)  ;; "      ;; Test inner pattern\n"
          (i32.const 27)))
      )
    )

    (i32.const 1)
  )

  ;; Generate test for Option::None pattern
  ;; @param pattern_node: i32 - AST node for None pattern
  ;; @param arm_label: i32 - Label to break to if pattern doesn't match
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_option_none_pattern_test (param $pattern_node i32) (param $arm_label i32) (result i32)
    (local $result i32)

    ;; Test if option is None (tag = 0)
    (local.set $result (call $write_output
      (i32.const 0x8130)  ;; "      ;; Test for None option\n"
      (i32.const 29)))

    ;; Load option tag (first 4 bytes)
    (local.set $result (call $write_output
      (i32.const 0x80F0)  ;; "      i32.load\n"
      (i32.const 15)))

    ;; Compare with None tag (0)
    (local.set $result (call $write_output
      (i32.const 0x8140)  ;; "      i32.const 0\n"
      (i32.const 17)))
    (local.set $result (call $write_output
      (i32.const 0x8110)  ;; "      i32.ne\n"
      (i32.const 13)))

    ;; Break to next arm if not None
    (local.set $result (call $write_output
      (i32.const 0x80A0)  ;; "      br_if $arm_"
      (i32.const 17)))
    (local.set $result (call $write_arm_label (local.get $arm_label)))
    (local.set $result (call $write_output
      (i32.const 0x8010)  ;; "\n"
      (i32.const 1)))

    (i32.const 1)
  )

  ;; Generate test for Result::Ok pattern
  ;; @param pattern_node: i32 - AST node for Ok pattern
  ;; @param arm_label: i32 - Label to break to if pattern doesn't match
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_result_ok_pattern_test (param $pattern_node i32) (param $arm_label i32) (result i32)
    (local $inner_pattern i32)
    (local $result i32)

    ;; Test if result is Ok (tag = 1)
    (local.set $result (call $write_output
      (i32.const 0x8150)  ;; "      ;; Test for Ok result\n"
      (i32.const 27)))

    ;; Load result tag (first 4 bytes)
    (local.set $result (call $write_output
      (i32.const 0x80F0)  ;; "      i32.load\n"
      (i32.const 15)))

    ;; Compare with Ok tag (1)
    (local.set $result (call $write_output
      (i32.const 0x8100)  ;; "      i32.const 1\n"
      (i32.const 17)))
    (local.set $result (call $write_output
      (i32.const 0x8110)  ;; "      i32.ne\n"
      (i32.const 13)))

    ;; Break to next arm if not Ok
    (local.set $result (call $write_output
      (i32.const 0x80A0)  ;; "      br_if $arm_"
      (i32.const 17)))
    (local.set $result (call $write_arm_label (local.get $arm_label)))
    (local.set $result (call $write_output
      (i32.const 0x8010)  ;; "\n"
      (i32.const 1)))

    ;; TODO: Generate code for inner pattern if it exists
    (local.set $inner_pattern (call $get_node_value (local.get $pattern_node)))
    (if (local.get $inner_pattern)
      (then
        ;; Load result value and test inner pattern
        (local.set $result (call $write_output
          (i32.const 0x8160)  ;; "      ;; Test inner Ok pattern\n"
          (i32.const 31)))
      )
    )

    (i32.const 1)
  )

  ;; Generate test for Result::Error pattern
  ;; @param pattern_node: i32 - AST node for Error pattern
  ;; @param arm_label: i32 - Label to break to if pattern doesn't match
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_result_err_pattern_test (param $pattern_node i32) (param $arm_label i32) (result i32)
    (local $inner_pattern i32)
    (local $result i32)

    ;; Test if result is Error (tag = 0)
    (local.set $result (call $write_output
      (i32.const 0x10170)  ;; "      ;; Test for Error result\n"
      (i32.const 30)))

    ;; Load result tag (first 4 bytes)
    (local.set $result (call $write_output
      (i32.const 0x80F0)  ;; "      i32.load\n"
      (i32.const 15)))

    ;; Compare with Error tag (0)
    (local.set $result (call $write_output
      (i32.const 0x8140)  ;; "      i32.const 0\n"
      (i32.const 17)))
    (local.set $result (call $write_output
      (i32.const 0x8110)  ;; "      i32.ne\n"
      (i32.const 13)))

    ;; Break to next arm if not Error
    (local.set $result (call $write_output
      (i32.const 0x80A0)  ;; "      br_if $arm_"
      (i32.const 17)))
    (local.set $result (call $write_arm_label (local.get $arm_label)))
    (local.set $result (call $write_output
      (i32.const 0x8010)  ;; "\n"
      (i32.const 1)))

    ;; TODO: Generate code for inner pattern if it exists
    (local.set $inner_pattern (call $get_node_value (local.get $pattern_node)))
    (if (local.get $inner_pattern)
      (then
        ;; Load result error and test inner pattern
        (local.set $result (call $write_output
          (i32.const 0x10180)  ;; "      ;; Test inner Error pattern\n"
          (i32.const 33)))
      )
    )

    (i32.const 1)
  )

  ;; Utility function to write match label
  ;; @param label: i32 - Match label number
  ;; @returns i32 - Success (1) or failure (0)
  (func $write_match_label (param $label i32) (result i32)
    ;; TODO: Convert label number to string and write
    ;; For now, write a placeholder
    (call $write_output (i32.const 0x8190) (i32.const 1))  ;; "0"
  )

  ;; Utility function to write arm label
  ;; @param label: i32 - Arm label number
  ;; @returns i32 - Success (1) or failure (0)
  (func $write_arm_label (param $label i32) (result i32)
    ;; TODO: Convert label number to string and write
    ;; For now, write a placeholder
    (call $write_output (i32.const 0x8190) (i32.const 1))  ;; "0"
  )

  ;; Check if match statement is exhaustive (basic implementation)
  ;; @param match_node: i32 - AST node for match statement
  ;; @returns i32 - 1 if exhaustive, 0 if not
  (func $check_exhaustiveness (export "check_exhaustiveness") (param $match_node i32) (result i32)
    (local $child_count i32)
    (local $has_wildcard i32)
    (local $i i32)
    (local $arm_node i32)
    (local $pattern_node i32)
    (local $pattern_type i32)

    ;; Get child count
    (local.set $child_count (call $get_child_count (local.get $match_node)))
    (if (i32.lt_u (local.get $child_count) (i32.const 2))
      (then
        ;; No arms - not exhaustive
        (return (i32.const 0))
      )
    )

    ;; Check if any arm has a wildcard pattern (makes match exhaustive)
    (local.set $has_wildcard (i32.const 0))
    (local.set $i (i32.const 1))  ;; Skip match expression
    (loop $check_loop
      (if (i32.lt_u (local.get $i) (local.get $child_count))
        (then
          ;; Get arm and its pattern
          (local.set $arm_node (call $get_child (local.get $match_node) (local.get $i)))
          (local.set $pattern_node (call $get_child (local.get $arm_node) (i32.const 0)))
          (local.set $pattern_type (call $get_node_type (local.get $pattern_node)))

          ;; Check if this is a wildcard or variable pattern (both catch all)
          (if (i32.or
            (i32.eq (local.get $pattern_type) (global.get $PAT_WILDCARD))
            (i32.eq (local.get $pattern_type) (global.get $PAT_VARIABLE)))
            (then
              (local.set $has_wildcard (i32.const 1))
            )
          )

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $check_loop)
        )
      )
    )

    ;; For now, consider exhaustive if there's a wildcard/variable pattern
    ;; TODO: Implement proper exhaustiveness checking for specific types
    (local.get $has_wildcard)
  )
)
