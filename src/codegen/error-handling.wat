;; Error Propagation Code Generation
;; Handles code generation for error propagation patterns in match statements
;; This module provides utilities for generating code that automatically propagates
;; errors when matching on Result and Option types

(module $codegen_error_handling
  ;; Import memory for code generation workspace
  (import "lexer_memory" "memory" (memory 1))

  ;; Import core code generation utilities
  (import "codegen_core" "write_output" (func $write_output (param i32 i32) (result i32)))
  (import "codegen_core" "push_stack" (func $push_stack))
  (import "codegen_core" "pop_stack" (func $pop_stack))
  (import "codegen_core" "get_wasm_type_string" (func $get_wasm_type_string (param i32 i32)))
  (import "codegen_core" "get_current_function_return_type" (func $get_current_function_return_type (result i32)))

  ;; Import expression generation
  (import "codegen_expressions" "generate_expression" (func $generate_expression (param i32) (result i32)))

  ;; Import AST utilities
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "ast_node_core" "get_child_count" (func $get_child_count (param i32) (result i32)))
  (import "ast_node_core" "get_child" (func $get_child (param i32 i32) (result i32)))
  (import "ast_node_core" "get_node_value" (func $get_node_value (param i32) (result i32)))

  ;; Import AST node types
  (import "ast_node_types" "CTRL_MATCH" (global $CTRL_MATCH i32))
  (import "ast_node_types" "CTRL_MATCH_ARM" (global $CTRL_MATCH_ARM i32))
  (import "ast_node_types" "PAT_RESULT_OK" (global $PAT_RESULT_OK i32))
  (import "ast_node_types" "PAT_RESULT_ERR" (global $PAT_RESULT_ERR i32))
  (import "ast_node_types" "PAT_OPTION_SOME" (global $PAT_OPTION_SOME i32))
  (import "ast_node_types" "PAT_OPTION_NONE" (global $PAT_OPTION_NONE i32))
  (import "ast_node_types" "CTRL_RETURN" (global $CTRL_RETURN i32))

  ;; Import type checker for type information
  (import "typechecker_main" "get_node_type_info" (func $get_node_type_info (param i32) (result i32)))
  (import "typechecker_main" "TYPE_RESULT" (global $TYPE_RESULT i32))
  (import "typechecker_main" "TYPE_OPTION" (global $TYPE_OPTION i32))

  ;; String constants for error handling patterns
  (data (i32.const 0x9000) "      ;; Error propagation pattern\n")
  (data (i32.const 0x9020) "      ;; Check if error should propagate\n")
  (data (i32.const 0x9040) "      ;; Return error immediately\n")
  (data (i32.const 0x9060) "      ;; Construct error result\n")
  (data (i32.const 0x9080) "      ;; Allocate error memory\n")
  (data (i32.const 0x90A0) "      call $alloc_result_error\n")
  (data (i32.const 0x90C0) "      return\n")
  (data (i32.const 0x90E0) "      ;; Option none propagation\n")
  (data (i32.const 0x9100) "      ;; Return none immediately\n")
  (data (i32.const 0x9120) "      call $alloc_option_none\n")
  (data (i32.const 0x9140) "      ;; Early return detected\n")
  (data (i32.const 0x9160) "      ;; Propagate error value\n")
  (data (i32.const 0x9180) "      i32.const 0\n")
  (data (i32.const 0x91A0) "      i32.const 1\n")

  ;; Global state for error propagation
  (global $error_propagation_depth (mut i32) (i32.const 0))
  (global $current_error_label (mut i32) (i32.const 0))

  ;; Check if a match statement contains error propagation patterns
  ;; @param match_node: i32 - AST node for match statement
  ;; @returns i32 - 1 if contains error propagation, 0 otherwise
  (func $has_error_propagation_pattern (param $match_node i32) (result i32)
    (local $child_count i32)
    (local $i i32)
    (local $arm_node i32)
    (local $pattern_node i32)
    (local $body_node i32)
    (local $has_propagation i32)

    (local.set $child_count (call $get_child_count (local.get $match_node)))
    (local.set $i (i32.const 1)) ;; Skip first child (match expression)
    (local.set $has_propagation (i32.const 0))

    (loop $check_arms
      (if (i32.lt_u (local.get $i) (local.get $child_count))
        (then
          (local.set $arm_node (call $get_child (local.get $match_node) (local.get $i)))
          (local.set $pattern_node (call $get_child (local.get $arm_node) (i32.const 0)))
          (local.set $body_node (call $get_child (local.get $arm_node) (i32.const 1)))

          ;; Check if this arm propagates errors
          (if (call $arm_propagates_error (local.get $pattern_node) (local.get $body_node))
            (then
              (local.set $has_propagation (i32.const 1))
            )
          )

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $check_arms)
        )
      )
    )

    (local.get $has_propagation)
  )

  ;; Check if a match arm propagates errors
  ;; @param pattern_node: i32 - AST node for pattern
  ;; @param body_node: i32 - AST node for match arm body
  ;; @returns i32 - 1 if propagates error, 0 otherwise
  (func $arm_propagates_error (param $pattern_node i32) (param $body_node i32) (result i32)
    (local $pattern_type i32)
    (local $body_type i32)
    (local $propagates i32)

    (local.set $pattern_type (call $get_node_type (local.get $pattern_node)))
    (local.set $body_type (call $get_node_type (local.get $body_node)))
    (local.set $propagates (i32.const 0))

    ;; Check if pattern is error pattern and body is return statement
    (if (i32.eq (local.get $pattern_type) (global.get $PAT_RESULT_ERR))
      (then
        (if (i32.eq (local.get $body_type) (global.get $CTRL_RETURN))
          (then
            (local.set $propagates (i32.const 1))
          )
        )
      )
    )

    ;; Check if pattern is none pattern and body is return statement
    (if (i32.eq (local.get $pattern_type) (global.get $PAT_OPTION_NONE))
      (then
        (if (i32.eq (local.get $body_type) (global.get $CTRL_RETURN))
          (then
            (local.set $propagates (i32.const 1))
          )
        )
      )
    )

    (local.get $propagates)
  )

  ;; Generate code for error propagation in match statement
  ;; @param match_node: i32 - AST node for match statement
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_error_propagation_match (param $match_node i32) (result i32)
    (local $result i32)
    (local $match_expr i32)
    (local $expr_type i32)

    ;; Get the expression being matched
    (local.set $match_expr (call $get_child (local.get $match_node) (i32.const 0)))
    (local.set $expr_type (call $get_node_type_info (local.get $match_expr)))

    ;; Write comment
    (local.set $result (call $write_output
      (i32.const 0x9000)  ;; "      ;; Error propagation pattern\n"
      (i32.const 32)))

    ;; Generate different code based on the type being matched
    (if (i32.eq (local.get $expr_type) (global.get $TYPE_RESULT))
      (then
        (local.set $result (call $generate_result_propagation (local.get $match_node)))
      )
      (else
        (if (i32.eq (local.get $expr_type) (global.get $TYPE_OPTION))
          (then
            (local.set $result (call $generate_option_propagation (local.get $match_node)))
          )
          (else
            ;; Not a propagation type, generate normal match
            (local.set $result (i32.const 0))
          )
        )
      )
    )

    (local.get $result)
  )

  ;; Generate code for Result type error propagation
  ;; @param match_node: i32 - AST node for match statement
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_result_propagation (param $match_node i32) (result i32)
    (local $result i32)
    (local $match_expr i32)
    (local $child_count i32)
    (local $i i32)
    (local $arm_node i32)
    (local $pattern_node i32)
    (local $body_node i32)
    (local $pattern_type i32)
    (local $has_error_arm i32)
    (local $has_ok_arm i32)

    ;; Generate match expression
    (local.set $match_expr (call $get_child (local.get $match_node) (i32.const 0)))
    (local.set $result (call $generate_expression (local.get $match_expr)))

    ;; Check what arms are present
    (local.set $child_count (call $get_child_count (local.get $match_node)))
    (local.set $i (i32.const 1))
    (local.set $has_error_arm (i32.const 0))
    (local.set $has_ok_arm (i32.const 0))

    (loop $check_arms
      (if (i32.lt_u (local.get $i) (local.get $child_count))
        (then
          (local.set $arm_node (call $get_child (local.get $match_node) (local.get $i)))
          (local.set $pattern_node (call $get_child (local.get $arm_node) (i32.const 0)))
          (local.set $pattern_type (call $get_node_type (local.get $pattern_node)))

          (if (i32.eq (local.get $pattern_type) (global.get $PAT_RESULT_ERR))
            (then
              (local.set $has_error_arm (i32.const 1))
            )
          )
          (if (i32.eq (local.get $pattern_type) (global.get $PAT_RESULT_OK))
            (then
              (local.set $has_ok_arm (i32.const 1))
            )
          )

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $check_arms)
        )
      )
    )

    ;; Generate the appropriate pattern matching code
    (if (i32.and (local.get $has_error_arm) (local.get $has_ok_arm))
      (then
        (local.set $result (call $generate_result_full_match (local.get $match_node)))
      )
      (else
        (if (local.get $has_error_arm)
          (then
            (local.set $result (call $generate_result_error_only_match (local.get $match_node)))
          )
          (else
            (local.set $result (call $generate_result_ok_only_match (local.get $match_node)))
          )
        )
      )
    )

    (local.get $result)
  )

  ;; Generate code for Option type error propagation
  ;; @param match_node: i32 - AST node for match statement
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_option_propagation (param $match_node i32) (result i32)
    (local $result i32)
    (local $match_expr i32)
    (local $child_count i32)
    (local $i i32)
    (local $arm_node i32)
    (local $pattern_node i32)
    (local $body_node i32)
    (local $pattern_type i32)
    (local $has_none_arm i32)
    (local $has_some_arm i32)

    ;; Generate match expression
    (local.set $match_expr (call $get_child (local.get $match_node) (i32.const 0)))
    (local.set $result (call $generate_expression (local.get $match_expr)))

    ;; Check what arms are present
    (local.set $child_count (call $get_child_count (local.get $match_node)))
    (local.set $i (i32.const 1))
    (local.set $has_none_arm (i32.const 0))
    (local.set $has_some_arm (i32.const 0))

    (loop $check_arms
      (if (i32.lt_u (local.get $i) (local.get $child_count))
        (then
          (local.set $arm_node (call $get_child (local.get $match_node) (local.get $i)))
          (local.set $pattern_node (call $get_child (local.get $arm_node) (i32.const 0)))
          (local.set $pattern_type (call $get_node_type (local.get $pattern_node)))

          (if (i32.eq (local.get $pattern_type) (global.get $PAT_OPTION_NONE))
            (then
              (local.set $has_none_arm (i32.const 1))
            )
          )
          (if (i32.eq (local.get $pattern_type) (global.get $PAT_OPTION_SOME))
            (then
              (local.set $has_some_arm (i32.const 1))
            )
          )

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $check_arms)
        )
      )
    )

    ;; Generate the appropriate pattern matching code
    (if (i32.and (local.get $has_none_arm) (local.get $has_some_arm))
      (then
        (local.set $result (call $generate_option_full_match (local.get $match_node)))
      )
      (else
        (if (local.get $has_none_arm)
          (then
            (local.set $result (call $generate_option_none_only_match (local.get $match_node)))
          )
          (else
            (local.set $result (call $generate_option_some_only_match (local.get $match_node)))
          )
        )
      )
    )

    (local.get $result)
  )

  ;; Generate code for full Result match (both Ok and Error arms)
  ;; @param match_node: i32 - AST node for match statement
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_result_full_match (param $match_node i32) (result i32)
    (local $result i32)

    ;; Write comment
    (local.set $result (call $write_output
      (i32.const 0x9020)  ;; "      ;; Check if error should propagate\n"
      (i32.const 37)))

    ;; Load result tag (first 4 bytes)
    (local.set $result (call $write_output
      (i32.const 0x100F0)  ;; "      i32.load\n"
      (i32.const 15)))

    ;; Compare with error tag (0)
    (local.set $result (call $write_output
      (i32.const 0x9180)  ;; "      i32.const 0\n"
      (i32.const 17)))
    (local.set $result (call $write_output
      (i32.const 0x10110)  ;; "      i32.eq\n"
      (i32.const 13)))

    ;; If error, propagate it
    (local.set $result (call $write_output
      (i32.const 0x10120)  ;; "      if\n"
      (i32.const 10)))

    ;; Generate error propagation code
    (local.set $result (call $generate_error_return_code (local.get $match_node)))

    ;; Else handle Ok case
    (local.set $result (call $write_output
      (i32.const 0x10130)  ;; "      else\n"
      (i32.const 12)))

    ;; Generate Ok case code
    (local.set $result (call $generate_ok_case_code (local.get $match_node)))

    ;; End if
    (local.set $result (call $write_output
      (i32.const 0x10140)  ;; "      end\n"
      (i32.const 11)))

    (local.get $result)
  )

  ;; Generate code for error-only Result match
  ;; @param match_node: i32 - AST node for match statement
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_result_error_only_match (param $match_node i32) (result i32)
    (local $result i32)

    ;; Write comment
    (local.set $result (call $write_output
      (i32.const 0x9020)  ;; "      ;; Check if error should propagate\n"
      (i32.const 37)))

    ;; Load result tag (first 4 bytes)
    (local.set $result (call $write_output
      (i32.const 0x100F0)  ;; "      i32.load\n"
      (i32.const 15)))

    ;; Compare with error tag (0)
    (local.set $result (call $write_output
      (i32.const 0x9180)  ;; "      i32.const 0\n"
      (i32.const 17)))
    (local.set $result (call $write_output
      (i32.const 0x10110)  ;; "      i32.eq\n"
      (i32.const 13)))

    ;; If error, propagate it
    (local.set $result (call $write_output
      (i32.const 0x10120)  ;; "      if\n"
      (i32.const 10)))

    ;; Generate error propagation code
    (local.set $result (call $generate_error_return_code (local.get $match_node)))

    ;; End if
    (local.set $result (call $write_output
      (i32.const 0x10140)  ;; "      end\n"
      (i32.const 11)))

    (local.get $result)
  )

  ;; Generate code for ok-only Result match
  ;; @param match_node: i32 - AST node for match statement
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_result_ok_only_match (param $match_node i32) (result i32)
    (local $result i32)

    ;; Write comment
    (local.set $result (call $write_output
      (i32.const 0x9020)  ;; "      ;; Check if error should propagate\n"
      (i32.const 37)))

    ;; Load result tag (first 4 bytes)
    (local.set $result (call $write_output
      (i32.const 0x100F0)  ;; "      i32.load\n"
      (i32.const 15)))

    ;; Compare with ok tag (1)
    (local.set $result (call $write_output
      (i32.const 0x91A0)  ;; "      i32.const 1\n"
      (i32.const 17)))
    (local.set $result (call $write_output
      (i32.const 0x10110)  ;; "      i32.eq\n"
      (i32.const 13)))

    ;; If ok, handle it
    (local.set $result (call $write_output
      (i32.const 0x10120)  ;; "      if\n"
      (i32.const 10)))

    ;; Generate Ok case code
    (local.set $result (call $generate_ok_case_code (local.get $match_node)))

    ;; End if
    (local.set $result (call $write_output
      (i32.const 0x10140)  ;; "      end\n"
      (i32.const 11)))

    (local.get $result)
  )

  ;; Generate code for full Option match (both Some and None arms)
  ;; @param match_node: i32 - AST node for match statement
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_option_full_match (param $match_node i32) (result i32)
    (local $result i32)

    ;; Write comment
    (local.set $result (call $write_output
      (i32.const 0x90E0)  ;; "      ;; Option none propagation\n"
      (i32.const 30)))

    ;; Load option tag (first 4 bytes)
    (local.set $result (call $write_output
      (i32.const 0x100F0)  ;; "      i32.load\n"
      (i32.const 15)))

    ;; Compare with none tag (0)
    (local.set $result (call $write_output
      (i32.const 0x9180)  ;; "      i32.const 0\n"
      (i32.const 17)))
    (local.set $result (call $write_output
      (i32.const 0x10110)  ;; "      i32.eq\n"
      (i32.const 13)))

    ;; If none, propagate it
    (local.set $result (call $write_output
      (i32.const 0x10120)  ;; "      if\n"
      (i32.const 10)))

    ;; Generate none propagation code
    (local.set $result (call $generate_none_return_code (local.get $match_node)))

    ;; Else handle Some case
    (local.set $result (call $write_output
      (i32.const 0x10130)  ;; "      else\n"
      (i32.const 12)))

    ;; Generate Some case code
    (local.set $result (call $generate_some_case_code (local.get $match_node)))

    ;; End if
    (local.set $result (call $write_output
      (i32.const 0x10140)  ;; "      end\n"
      (i32.const 11)))

    (local.get $result)
  )

  ;; Generate code for none-only Option match
  ;; @param match_node: i32 - AST node for match statement
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_option_none_only_match (param $match_node i32) (result i32)
    (local $result i32)

    ;; Write comment
    (local.set $result (call $write_output
      (i32.const 0x90E0)  ;; "      ;; Option none propagation\n"
      (i32.const 30)))

    ;; Load option tag (first 4 bytes)
    (local.set $result (call $write_output
      (i32.const 0x100F0)  ;; "      i32.load\n"
      (i32.const 15)))

    ;; Compare with none tag (0)
    (local.set $result (call $write_output
      (i32.const 0x9180)  ;; "      i32.const 0\n"
      (i32.const 17)))
    (local.set $result (call $write_output
      (i32.const 0x10110)  ;; "      i32.eq\n"
      (i32.const 13)))

    ;; If none, propagate it
    (local.set $result (call $write_output
      (i32.const 0x10120)  ;; "      if\n"
      (i32.const 10)))

    ;; Generate none propagation code
    (local.set $result (call $generate_none_return_code (local.get $match_node)))

    ;; End if
    (local.set $result (call $write_output
      (i32.const 0x10140)  ;; "      end\n"
      (i32.const 11)))

    (local.get $result)
  )

  ;; Generate code for some-only Option match
  ;; @param match_node: i32 - AST node for match statement
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_option_some_only_match (param $match_node i32) (result i32)
    (local $result i32)

    ;; Write comment
    (local.set $result (call $write_output
      (i32.const 0x90E0)  ;; "      ;; Option none propagation\n"
      (i32.const 30)))

    ;; Load option tag (first 4 bytes)
    (local.set $result (call $write_output
      (i32.const 0x100F0)  ;; "      i32.load\n"
      (i32.const 15)))

    ;; Compare with some tag (1)
    (local.set $result (call $write_output
      (i32.const 0x91A0)  ;; "      i32.const 1\n"
      (i32.const 17)))
    (local.set $result (call $write_output
      (i32.const 0x10110)  ;; "      i32.eq\n"
      (i32.const 13)))

    ;; If some, handle it
    (local.set $result (call $write_output
      (i32.const 0x10120)  ;; "      if\n"
      (i32.const 10)))

    ;; Generate Some case code
    (local.set $result (call $generate_some_case_code (local.get $match_node)))

    ;; End if
    (local.set $result (call $write_output
      (i32.const 0x10140)  ;; "      end\n"
      (i32.const 11)))

    (local.get $result)
  )

  ;; Generate code to return error from current function
  ;; @param match_node: i32 - AST node for match statement
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_error_return_code (param $match_node i32) (result i32)
    (local $result i32)
    (local $child_count i32)
    (local $i i32)
    (local $arm_node i32)
    (local $pattern_node i32)
    (local $body_node i32)
    (local $pattern_type i32)

    ;; Find the error arm and generate its body
    (local.set $child_count (call $get_child_count (local.get $match_node)))
    (local.set $i (i32.const 1))

    (loop $find_error_arm
      (if (i32.lt_u (local.get $i) (local.get $child_count))
        (then
          (local.set $arm_node (call $get_child (local.get $match_node) (local.get $i)))
          (local.set $pattern_node (call $get_child (local.get $arm_node) (i32.const 0)))
          (local.set $pattern_type (call $get_node_type (local.get $pattern_node)))

          (if (i32.eq (local.get $pattern_type) (global.get $PAT_RESULT_ERR))
            (then
              ;; Found error arm, generate its body
              (local.set $body_node (call $get_child (local.get $arm_node) (i32.const 1)))
              (local.set $result (call $generate_error_propagation_body (local.get $pattern_node) (local.get $body_node)))
              (return (local.get $result))
            )
          )

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $find_error_arm)
        )
      )
    )

    ;; No error arm found, generate default error propagation
    (local.set $result (call $generate_default_error_propagation))
    (local.get $result)
  )

  ;; Generate code to return none from current function
  ;; @param match_node: i32 - AST node for match statement
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_none_return_code (param $match_node i32) (result i32)
    (local $result i32)
    (local $child_count i32)
    (local $i i32)
    (local $arm_node i32)
    (local $pattern_node i32)
    (local $body_node i32)
    (local $pattern_type i32)

    ;; Find the none arm and generate its body
    (local.set $child_count (call $get_child_count (local.get $match_node)))
    (local.set $i (i32.const 1))

    (loop $find_none_arm
      (if (i32.lt_u (local.get $i) (local.get $child_count))
        (then
          (local.set $arm_node (call $get_child (local.get $match_node) (local.get $i)))
          (local.set $pattern_node (call $get_child (local.get $arm_node) (i32.const 0)))
          (local.set $pattern_type (call $get_node_type (local.get $pattern_node)))

          (if (i32.eq (local.get $pattern_type) (global.get $PAT_OPTION_NONE))
            (then
              ;; Found none arm, generate its body
              (local.set $body_node (call $get_child (local.get $arm_node) (i32.const 1)))
              (local.set $result (call $generate_none_propagation_body (local.get $pattern_node) (local.get $body_node)))
              (return (local.get $result))
            )
          )

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $find_none_arm)
        )
      )
    )

    ;; No none arm found, generate default none propagation
    (local.set $result (call $generate_default_none_propagation))
    (local.get $result)
  )

  ;; Generate code for Ok case
  ;; @param match_node: i32 - AST node for match statement
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_ok_case_code (param $match_node i32) (result i32)
    (local $result i32)
    (local $child_count i32)
    (local $i i32)
    (local $arm_node i32)
    (local $pattern_node i32)
    (local $body_node i32)
    (local $pattern_type i32)

    ;; Find the ok arm and generate its body
    (local.set $child_count (call $get_child_count (local.get $match_node)))
    (local.set $i (i32.const 1))

    (loop $find_ok_arm
      (if (i32.lt_u (local.get $i) (local.get $child_count))
        (then
          (local.set $arm_node (call $get_child (local.get $match_node) (local.get $i)))
          (local.set $pattern_node (call $get_child (local.get $arm_node) (i32.const 0)))
          (local.set $pattern_type (call $get_node_type (local.get $pattern_node)))

          (if (i32.eq (local.get $pattern_type) (global.get $PAT_RESULT_OK))
            (then
              ;; Found ok arm, generate its body
              (local.set $body_node (call $get_child (local.get $arm_node) (i32.const 1)))
              (local.set $result (call $generate_expression (local.get $body_node)))
              (return (local.get $result))
            )
          )

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $find_ok_arm)
        )
      )
    )

    (i32.const 1)
  )

  ;; Generate code for Some case
  ;; @param match_node: i32 - AST node for match statement
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_some_case_code (param $match_node i32) (result i32)
    (local $result i32)
    (local $child_count i32)
    (local $i i32)
    (local $arm_node i32)
    (local $pattern_node i32)
    (local $body_node i32)
    (local $pattern_type i32)

    ;; Find the some arm and generate its body
    (local.set $child_count (call $get_child_count (local.get $match_node)))
    (local.set $i (i32.const 1))

    (loop $find_some_arm
      (if (i32.lt_u (local.get $i) (local.get $child_count))
        (then
          (local.set $arm_node (call $get_child (local.get $match_node) (local.get $i)))
          (local.set $pattern_node (call $get_child (local.get $arm_node) (i32.const 0)))
          (local.set $pattern_type (call $get_node_type (local.get $pattern_node)))

          (if (i32.eq (local.get $pattern_type) (global.get $PAT_OPTION_SOME))
            (then
              ;; Found some arm, generate its body
              (local.set $body_node (call $get_child (local.get $arm_node) (i32.const 1)))
              (local.set $result (call $generate_expression (local.get $body_node)))
              (return (local.get $result))
            )
          )

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $find_some_arm)
        )
      )
    )

    (i32.const 1)
  )

  ;; Generate error propagation body code
  ;; @param pattern_node: i32 - AST node for error pattern
  ;; @param body_node: i32 - AST node for match arm body
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_error_propagation_body (param $pattern_node i32) (param $body_node i32) (result i32)
    (local $result i32)

    ;; Write comment
    (local.set $result (call $write_output
      (i32.const 0x9040)  ;; "      ;; Return error immediately\n"
      (i32.const 31)))

    ;; Load error value from result (offset 4)
    (local.set $result (call $write_output
      (i32.const 0x100E0)  ;; "      i32.const 4\n"
      (i32.const 17)))
    (local.set $result (call $write_output
      (i32.const 0x100D0)  ;; "      i32.add\n"
      (i32.const 13)))
    (local.set $result (call $write_output
      (i32.const 0x100F0)  ;; "      i32.load\n"
      (i32.const 15)))

    ;; Generate the body expression (which should be a return statement)
    (local.set $result (call $generate_expression (local.get $body_node)))

    (local.get $result)
  )

  ;; Generate none propagation body code
  ;; @param pattern_node: i32 - AST node for none pattern
  ;; @param body_node: i32 - AST node for match arm body
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_none_propagation_body (param $pattern_node i32) (param $body_node i32) (result i32)
    (local $result i32)

    ;; Write comment
    (local.set $result (call $write_output
      (i32.const 0x9100)  ;; "      ;; Return none immediately\n"
      (i32.const 29)))

    ;; Generate the body expression (which should be a return statement)
    (local.set $result (call $generate_expression (local.get $body_node)))

    (local.get $result)
  )

  ;; Generate default error propagation (when no explicit error arm exists)
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_default_error_propagation (result i32)
    (local $result i32)

    ;; Write comment
    (local.set $result (call $write_output
      (i32.const 0x9160)  ;; "      ;; Propagate error value\n"
      (i32.const 28)))

    ;; Load error value from result (offset 4)
    (local.set $result (call $write_output
      (i32.const 0x100E0)  ;; "      i32.const 4\n"
      (i32.const 17)))
    (local.set $result (call $write_output
      (i32.const 0x100D0)  ;; "      i32.add\n"
      (i32.const 13)))
    (local.set $result (call $write_output
      (i32.const 0x100F0)  ;; "      i32.load\n"
      (i32.const 15)))

    ;; Return the error
    (local.set $result (call $write_output
      (i32.const 0x90C0)  ;; "      return\n"
      (i32.const 13)))

    (local.get $result)
  )

  ;; Generate default none propagation (when no explicit none arm exists)
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_default_none_propagation (result i32)
    (local $result i32)

    ;; Write comment
    (local.set $result (call $write_output
      (i32.const 0x9100)  ;; "      ;; Return none immediately\n"
      (i32.const 29)))

    ;; Allocate none value
    (local.set $result (call $write_output
      (i32.const 0x9120)  ;; "      call $alloc_option_none\n"
      (i32.const 26)))

    ;; Return the none
    (local.set $result (call $write_output
      (i32.const 0x90C0)  ;; "      return\n"
      (i32.const 13)))

    (local.get $result)
  )

  ;; Validate that error propagation patterns are correctly structured
  ;; @param match_node: i32 - AST node for match statement
  ;; @returns i32 - 1 if valid, 0 if invalid
  (func $validate_error_propagation (param $match_node i32) (result i32)
    (local $return_type i32)
    (local $match_type i32)
    (local $match_expr i32)
    (local $valid i32)

    ;; Get the return type of the current function
    (local.set $return_type (call $get_current_function_return_type))

    ;; Get the type of the match expression
    (local.set $match_expr (call $get_child (local.get $match_node) (i32.const 0)))
    (local.set $match_type (call $get_node_type_info (local.get $match_expr)))

    ;; Error propagation is valid if:
    ;; 1. Function returns Result type and matching on Result type
    ;; 2. Function returns Option type and matching on Option type
    (local.set $valid (i32.const 0))

    (if (i32.eq (local.get $return_type) (global.get $TYPE_RESULT))
      (then
        (if (i32.eq (local.get $match_type) (global.get $TYPE_RESULT))
          (then
            (local.set $valid (i32.const 1))
          )
        )
      )
    )

    (if (i32.eq (local.get $return_type) (global.get $TYPE_OPTION))
      (then
        (if (i32.eq (local.get $match_type) (global.get $TYPE_OPTION))
          (then
            (local.set $valid (i32.const 1))
          )
        )
      )
    )

    (local.get $valid)
  )

  ;; Helper function to write arm label (simple implementation)
  ;; @param label: i32 - Label number to write
  ;; @returns i32 - Success (1) or failure (0)
  (func $write_arm_label (param $label i32) (result i32)
    ;; TODO: Convert label number to string and write
    ;; For now, write a placeholder
    (call $write_output (i32.const 0x9180) (i32.const 1))  ;; "0"
  )

  ;; Export functions for use by other modules
  (export "has_error_propagation_pattern" (func $has_error_propagation_pattern))
  (export "generate_error_propagation_match" (func $generate_error_propagation_match))
  (export "validate_error_propagation" (func $validate_error_propagation))
  (export "arm_propagates_error" (func $arm_propagates_error))
)
