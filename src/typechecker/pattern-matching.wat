;; Pattern Matching Type Checker - Core Logic
;; Handles match statements and pattern type checking

(module $typechecker_pattern_matching
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import type checker infrastructure
  (import "typechecker_main" "get_node_type_info" (func $get_node_type_info (param i32) (result i32)))
  (import "typechecker_main" "set_node_type_info" (func $set_node_type_info (param i32 i32) (result i32)))
  (import "typechecker_main" "types_compatible" (func $types_compatible (param i32 i32) (result i32)))
  (import "typechecker_main" "add_symbol" (func $add_symbol (param i32 i32 i32) (result i32)))
  (import "typechecker_main" "enter_scope" (func $enter_scope))
  (import "typechecker_main" "exit_scope" (func $exit_scope))
  (import "typechecker_expressions" "typecheck_expression" (func $check_expression (param i32) (result i32)))

  ;; Import AST functions
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "ast_node_core" "get_child_count" (func $get_child_count (param i32) (result i32)))
  (import "ast_node_core" "get_child" (func $get_child (param i32 i32) (result i32)))

  ;; Import node type constants
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

  ;; Import type constants
  (import "typechecker_main" "TYPE_UNKNOWN" (global $TYPE_UNKNOWN i32))
  (import "typechecker_main" "TYPE_ERROR" (global $TYPE_ERROR i32))
  (import "typechecker_main" "TYPE_BOOL" (global $TYPE_BOOL i32))

  ;; Type check a match statement
  ;; @param $match_node i32 - Pointer to match AST node
  ;; @returns i32 - Result type (0 = success, 1 = error)
  (func $check_match_statement (export "check_match_statement") (param $match_node i32) (result i32)
    (local $expression_node i32)
    (local $expression_type i32)
    (local $arm_count i32)
    (local $i i32)
    (local $arm_node i32)
    (local $result i32)

    (if (i32.eqz (local.get $match_node))
      (then (return (i32.const 1))))

    ;; Get the expression being matched (first child)
    (local.set $expression_node (call $get_child (local.get $match_node) (i32.const 0)))
    (if (i32.eqz (local.get $expression_node))
      (then (return (i32.const 1))))

    ;; Type check the expression
    (local.set $result (call $check_expression (local.get $expression_node)))
    (if (local.get $result)
      (then (return (local.get $result))))

    ;; Get the type of the expression
    (local.set $expression_type (call $get_node_type_info (local.get $expression_node)))
    (if (i32.eq (local.get $expression_type) (global.get $TYPE_ERROR))
      (then (return (i32.const 1))))

    ;; Type check all match arms
    (local.set $arm_count (call $get_child_count (local.get $match_node)))
    (local.set $i (i32.const 1)) ;; Start from 1 (skip expression)

    (loop $arm_loop
      (if (i32.ge_u (local.get $i) (local.get $arm_count))
        (then (br $arm_loop))) ;; Exit loop

      (local.set $arm_node (call $get_child (local.get $match_node) (local.get $i)))
      (local.set $result (call $check_match_arm (local.get $arm_node) (local.get $expression_type)))

      (if (local.get $result)
        (then (return (local.get $result))))

      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $arm_loop)
    )

    ;; All arms type checked successfully
    (i32.const 0)
  )

  ;; Type check a match arm (pattern + body)
  ;; @param $arm_node i32 - Pointer to match arm AST node
  ;; @param $expression_type i32 - Type of the matched expression
  ;; @returns i32 - Result (0 = success, 1 = error)
  (func $check_match_arm (export "check_match_arm") (param $arm_node i32) (param $expression_type i32) (result i32)
    (local $pattern_node i32)
    (local $body_node i32)
    (local $result i32)

    (if (i32.eqz (local.get $arm_node))
      (then (return (i32.const 1))))

    ;; Get pattern (first child) and body (second child)
    (local.set $pattern_node (call $get_child (local.get $arm_node) (i32.const 0)))
    (local.set $body_node (call $get_child (local.get $arm_node) (i32.const 1)))

    (if (i32.eqz (local.get $pattern_node))
      (then (return (i32.const 1))))
    (if (i32.eqz (local.get $body_node))
      (then (return (i32.const 1))))

    ;; Enter new scope for pattern variables
    (call $enter_scope)

    ;; Type check the pattern against the expression type
    (local.set $result (call $check_pattern (local.get $pattern_node) (local.get $expression_type)))

    (if (local.get $result)
      (then
        (call $exit_scope)
        (return (local.get $result))))

    ;; Type check the body expression
    (local.set $result (call $check_expression (local.get $body_node)))

    ;; Exit pattern variable scope
    (call $exit_scope)

    (local.get $result)
  )

  ;; Type check a pattern against an expected type
  ;; @param $pattern_node i32 - Pointer to pattern AST node
  ;; @param $expected_type i32 - Expected type for the pattern
  ;; @returns i32 - Result (0 = success, 1 = error)
  (func $check_pattern (export "check_pattern") (param $pattern_node i32) (param $expected_type i32) (result i32)
    (local $pattern_type i32)

    (if (i32.eqz (local.get $pattern_node))
      (then (return (i32.const 1))))

    (local.set $pattern_type (call $get_node_type (local.get $pattern_node)))

    ;; Check pattern based on type
    (if (i32.eq (local.get $pattern_type) (global.get $PAT_LITERAL))
      (then (return (call $check_literal_pattern (local.get $pattern_node) (local.get $expected_type)))))

    (if (i32.eq (local.get $pattern_type) (global.get $PAT_VARIABLE))
      (then (return (call $check_variable_pattern (local.get $pattern_node) (local.get $expected_type)))))

    (if (i32.eq (local.get $pattern_type) (global.get $PAT_WILDCARD))
      (then (return (call $check_wildcard_pattern (local.get $pattern_node) (local.get $expected_type)))))

    (if (i32.eq (local.get $pattern_type) (global.get $PAT_OPTION_SOME))
      (then (return (call $check_option_some_pattern (local.get $pattern_node) (local.get $expected_type)))))

    (if (i32.eq (local.get $pattern_type) (global.get $PAT_OPTION_NONE))
      (then (return (call $check_option_none_pattern (local.get $pattern_node) (local.get $expected_type)))))

    (if (i32.eq (local.get $pattern_type) (global.get $PAT_RESULT_OK))
      (then (return (call $check_result_ok_pattern (local.get $pattern_node) (local.get $expected_type)))))

    (if (i32.eq (local.get $pattern_type) (global.get $PAT_RESULT_ERR))
      (then (return (call $check_result_err_pattern (local.get $pattern_node) (local.get $expected_type)))))

    (if (i32.eq (local.get $pattern_type) (global.get $PAT_TUPLE))
      (then (return (call $check_tuple_pattern (local.get $pattern_node) (local.get $expected_type)))))

    (if (i32.eq (local.get $pattern_type) (global.get $PAT_RECORD))
      (then (return (call $check_record_pattern (local.get $pattern_node) (local.get $expected_type)))))

    (if (i32.eq (local.get $pattern_type) (global.get $PAT_VARIANT))
      (then (return (call $check_variant_pattern (local.get $pattern_node) (local.get $expected_type)))))

    ;; Unknown pattern type
    (i32.const 1)
  )

  ;; Check literal pattern
  (func $check_literal_pattern (export "check_literal_pattern") (param $pattern_node i32) (param $expected_type i32) (result i32)
    (local $literal_type i32)

    ;; Get the type of the literal from the AST node
    (local.set $literal_type (call $get_node_type_info (local.get $pattern_node)))

    ;; Check if literal type is compatible with expected type
    (if (i32.eq (local.get $literal_type) (global.get $TYPE_UNKNOWN))
      (then
        ;; Infer literal type from context
        (call $set_node_type_info (local.get $pattern_node) (local.get $expected_type))
        (return (i32.const 0))))

    ;; Check type compatibility
    (call $types_compatible (local.get $literal_type) (local.get $expected_type))
  )

  ;; Check variable pattern - binds variable to the expected type
  (func $check_variable_pattern (export "check_variable_pattern") (param $pattern_node i32) (param $expected_type i32) (result i32)
    (local $variable_name_ptr i32)
    (local $variable_name_len i32)
    (local $result i32)

    ;; Variable patterns always match and bind the variable to the expected type
    ;; Extract variable name from the pattern node (would need AST helper for this)
    ;; For now, we use a placeholder approach
    (local.set $variable_name_ptr (i32.const 1000)) ;; Mock address
    (local.set $variable_name_len (i32.const 8))     ;; Mock length

    ;; Add the variable to the current scope's symbol table
    (local.set $result (call $add_symbol (local.get $variable_name_ptr) (local.get $variable_name_len) (local.get $expected_type)))

    ;; Set the pattern node's type info for later reference
    (drop (call $set_node_type_info (local.get $pattern_node) (local.get $expected_type)))

    (i32.const 0) ;; Success - ignore add_symbol result for now
  )

  ;; Check wildcard pattern - matches any type
  (func $check_wildcard_pattern (export "check_wildcard_pattern") (param $pattern_node i32) (param $expected_type i32) (result i32)
    ;; Wildcard patterns always match
    (i32.const 0)
  )

  ;; Check option some pattern
  (func $check_option_some_pattern (export "check_option_some_pattern") (param $pattern_node i32) (param $expected_type i32) (result i32)
    (local $inner_pattern i32)
    (local $inner_type i32)
    (local $result i32)

    ;; Verify that expected_type is an option type
    ;; For now, we use a simplified check - in a complete implementation,
    ;; we would have proper type introspection to check if it's option<T>

    ;; Get the inner pattern (first child of the some pattern)
    (local.set $inner_pattern (call $get_child (local.get $pattern_node) (i32.const 0)))
    (if (i32.eqz (local.get $inner_pattern))
      (then (return (i32.const 1)))) ;; Error: some pattern must have inner pattern

    ;; Extract the inner type from the option type
    ;; For now, assume expected_type points to the inner type
    ;; In a complete implementation, we would extract T from option<T>
    (local.set $inner_type (local.get $expected_type))

    ;; Recursively check the inner pattern
    (local.set $result (call $check_pattern (local.get $inner_pattern) (local.get $inner_type)))

    ;; Set pattern type info
    (if (i32.eq (local.get $result) (i32.const 0))
      (then (drop (call $set_node_type_info (local.get $pattern_node) (local.get $expected_type)))))

    (local.get $result)
  )

  ;; Check option none pattern
  (func $check_option_none_pattern (export "check_option_none_pattern") (param $pattern_node i32) (param $expected_type i32) (result i32)
    ;; Verify that expected_type is an option type
    ;; None patterns don't have inner patterns, so we just need to verify
    ;; that the expected type is compatible with an option type

    ;; For now, we assume any option type is valid for none patterns
    ;; In a complete implementation, we would verify that expected_type is option<T>

    ;; Set pattern type info
    (drop (call $set_node_type_info (local.get $pattern_node) (local.get $expected_type)))

    (i32.const 0) ;; Success
  )

  ;; Check result ok pattern
  (func $check_result_ok_pattern (export "check_result_ok_pattern") (param $pattern_node i32) (param $expected_type i32) (result i32)
    (local $inner_pattern i32)
    (local $inner_type i32)
    (local $result i32)

    ;; Verify that expected_type is a result type
    ;; For now, we use a simplified check - in a complete implementation,
    ;; we would have proper type introspection to check if it's result<T, E>

    ;; Get the inner pattern (first child of the ok pattern)
    (local.set $inner_pattern (call $get_child (local.get $pattern_node) (i32.const 0)))
    (if (i32.eqz (local.get $inner_pattern))
      (then (return (i32.const 1)))) ;; Error: ok pattern must have inner pattern

    ;; Extract the success type from the result type
    ;; For now, assume expected_type points to the success type
    ;; In a complete implementation, we would extract T from result<T, E>
    (local.set $inner_type (local.get $expected_type))

    ;; Recursively check the inner pattern
    (local.set $result (call $check_pattern (local.get $inner_pattern) (local.get $inner_type)))

    ;; Set pattern type info
    (if (i32.eq (local.get $result) (i32.const 0))
      (then (drop (call $set_node_type_info (local.get $pattern_node) (local.get $expected_type)))))

    (local.get $result)
  )

  ;; Check result error pattern
  (func $check_result_err_pattern (export "check_result_err_pattern") (param $pattern_node i32) (param $expected_type i32) (result i32)
    (local $inner_pattern i32)
    (local $inner_type i32)
    (local $result i32)

    ;; Verify that expected_type is a result type
    ;; For now, we use a simplified check - in a complete implementation,
    ;; we would have proper type introspection to check if it's result<T, E>

    ;; Get the inner pattern (first child of the err pattern)
    (local.set $inner_pattern (call $get_child (local.get $pattern_node) (i32.const 0)))
    (if (i32.eqz (local.get $inner_pattern))
      (then (return (i32.const 1)))) ;; Error: err pattern must have inner pattern

    ;; Extract the error type from the result type
    ;; For now, assume expected_type points to the error type
    ;; In a complete implementation, we would extract E from result<T, E>
    (local.set $inner_type (local.get $expected_type))

    ;; Recursively check the inner pattern
    (local.set $result (call $check_pattern (local.get $inner_pattern) (local.get $inner_type)))

    ;; Set pattern type info
    (if (i32.eq (local.get $result) (i32.const 0))
      (then (drop (call $set_node_type_info (local.get $pattern_node) (local.get $expected_type)))))

    (local.get $result)
  )

  ;; Check tuple pattern
  (func $check_tuple_pattern (export "check_tuple_pattern") (param $pattern_node i32) (param $expected_type i32) (result i32)
    (local $child_count i32)
    (local $i i32)
    (local $child_pattern i32)
    (local $child_type i32)
    (local $result i32)

    ;; Get number of pattern elements
    (local.set $child_count (call $get_child_count (local.get $pattern_node)))

    ;; Type check each element pattern
    (local.set $i (i32.const 0))
    (loop $element_loop
      (if (i32.ge_u (local.get $i) (local.get $child_count))
        (then (br $element_loop))) ;; Exit loop

      (local.set $child_pattern (call $get_child (local.get $pattern_node) (local.get $i)))

      ;; For now, assume all tuple elements have the same type as expected_type
      ;; In a complete implementation, we would extract the proper element type
      (local.set $child_type (local.get $expected_type))

      (local.set $result (call $check_pattern (local.get $child_pattern) (local.get $child_type)))
      (if (local.get $result)
        (then (return (local.get $result))))

      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $element_loop)
    )

    ;; Set pattern type info
    (drop (call $set_node_type_info (local.get $pattern_node) (local.get $expected_type)))

    (i32.const 0) ;; Success
  )

  ;; Check record pattern
  (func $check_record_pattern (export "check_record_pattern") (param $pattern_node i32) (param $expected_type i32) (result i32)
    (local $child_count i32)
    (local $i i32)
    (local $field_pattern i32)
    (local $field_type i32)
    (local $result i32)

    ;; Get number of field patterns
    (local.set $child_count (call $get_child_count (local.get $pattern_node)))

    ;; Type check each field pattern
    (local.set $i (i32.const 0))
    (loop $field_loop
      (if (i32.ge_u (local.get $i) (local.get $child_count))
        (then (br $field_loop))) ;; Exit loop

      (local.set $field_pattern (call $get_child (local.get $pattern_node) (local.get $i)))

      ;; For now, assume all record fields have the same type as expected_type
      ;; In a complete implementation, we would extract the proper field type
      (local.set $field_type (local.get $expected_type))

      (local.set $result (call $check_pattern (local.get $field_pattern) (local.get $field_type)))
      (if (local.get $result)
        (then (return (local.get $result))))

      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $field_loop)
    )

    ;; Set pattern type info
    (drop (call $set_node_type_info (local.get $pattern_node) (local.get $expected_type)))

    (i32.const 0) ;; Success
  )

  ;; Check variant pattern
  (func $check_variant_pattern (export "check_variant_pattern") (param $pattern_node i32) (param $expected_type i32) (result i32)
    (local $child_count i32)
    (local $inner_pattern i32)
    (local $inner_type i32)
    (local $result i32)

    ;; Get number of children (should be 0 for unit variants, 1 for variants with data)
    (local.set $child_count (call $get_child_count (local.get $pattern_node)))

    (if (i32.gt_u (local.get $child_count) (i32.const 0))
      (then
        ;; Variant with associated data
        (local.set $inner_pattern (call $get_child (local.get $pattern_node) (i32.const 0)))

        ;; For now, assume variant data has the same type as expected_type
        ;; In a complete implementation, we would extract the proper variant data type
        (local.set $inner_type (local.get $expected_type))

        (local.set $result (call $check_pattern (local.get $inner_pattern) (local.get $inner_type)))
        (if (local.get $result)
          (then (return (local.get $result))))
      )
    )

    ;; Set pattern type info
    (drop (call $set_node_type_info (local.get $pattern_node) (local.get $expected_type)))

    (i32.const 0) ;; Success
  )
)
