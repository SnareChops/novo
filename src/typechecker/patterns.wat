;; Pattern Matching Type Checker
;; Handles type checking for match statements and pattern destructuring

(module $typechecker_patterns
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import type checker infrastructure
  (import "typechecker_main" "get_node_type_info" (func $get_node_type_info (param i32) (result i32)))
  (import "typechecker_main" "set_node_type_info" (func $set_node_type_info (param i32 i32) (result i32)))
  (import "typechecker_main" "types_compatible" (func $types_compatible (param i32 i32) (result i32)))
  (import "typechecker_main" "add_symbol" (func $add_symbol (param i32 i32 i32) (result i32)))
  (import "typechecker_main" "enter_scope" (func $enter_scope))
  (import "typechecker_main" "exit_scope" (func $exit_scope))

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
    (local $is_exhaustive i32)

    ;; Validate node type
    (if (i32.ne (call $get_node_type (local.get $match_node)) (global.get $CTRL_MATCH))
      (then (return (i32.const 1))))

    ;; Get and type check the match expression (first child)
    (local.set $expression_node (call $get_child (local.get $match_node) (i32.const 0)))
    (if (i32.eqz (local.get $expression_node))
      (then (return (i32.const 1))))

    ;; Get the type of the expression being matched
    (local.set $expression_type (call $get_node_type_info (local.get $expression_node)))
    (if (i32.eq (local.get $expression_type) (global.get $TYPE_UNKNOWN))
      (then (return (i32.const 1))))

    ;; Check each match arm
    (local.set $arm_count (call $get_child_count (local.get $match_node)))
    (local.set $i (i32.const 1)) ;; Skip expression (first child)
    (local.set $is_exhaustive (i32.const 0))

    (loop $arm_loop
      (if (i32.lt_u (local.get $i) (local.get $arm_count))
        (then
          (local.set $arm_node (call $get_child (local.get $match_node) (local.get $i)))

          ;; Type check this arm
          (local.set $result (call $check_match_arm (local.get $arm_node) (local.get $expression_type)))
          (if (i32.ne (local.get $result) (i32.const 0))
            (then (return (local.get $result))))

          ;; Check if this is a wildcard pattern (makes match exhaustive)
          (if (call $is_wildcard_arm (local.get $arm_node))
            (then (local.set $is_exhaustive (i32.const 1))))

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $arm_loop))))

    ;; For now, we don't enforce exhaustiveness checking
    ;; This would be enhanced in a more complete implementation
    (i32.const 0)
  )

  ;; Type check a single match arm
  ;; @param $arm_node i32 - Pointer to match arm AST node
  ;; @param $expression_type i32 - Type of the matched expression
  ;; @returns i32 - Result (0 = success, 1 = error)
  (func $check_match_arm (param $arm_node i32) (param $expression_type i32) (result i32)
    (local $pattern_node i32)
    (local $body_node i32)
    (local $result i32)

    ;; Validate node type
    (if (i32.ne (call $get_node_type (local.get $arm_node)) (global.get $CTRL_MATCH_ARM))
      (then (return (i32.const 1))))

    ;; Get pattern (first child) and body (second child)
    (local.set $pattern_node (call $get_child (local.get $arm_node) (i32.const 0)))
    (local.set $body_node (call $get_child (local.get $arm_node) (i32.const 1)))

    (if (i32.eqz (local.get $pattern_node))
      (then (return (i32.const 1))))

    ;; Enter new scope for pattern variables
    (call $enter_scope)

    ;; Type check the pattern against the expression type
    (local.set $result (call $check_pattern (local.get $pattern_node) (local.get $expression_type)))

    ;; Type check the body if pattern checking succeeded
    (if (i32.eq (local.get $result) (i32.const 0))
      (then
        (if (local.get $body_node)
          (then
            ;; For now, assume body type checking is handled elsewhere
            (nop)))))

    ;; Exit scope
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
  (func $check_literal_pattern (param $pattern_node i32) (param $expected_type i32) (result i32)
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
  (func $check_variable_pattern (param $pattern_node i32) (param $expected_type i32) (result i32)
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
  (func $check_wildcard_pattern (param $pattern_node i32) (param $expected_type i32) (result i32)
    ;; Wildcard patterns always match
    (i32.const 0)
  )

  ;; Check option some pattern
  (func $check_option_some_pattern (param $pattern_node i32) (param $expected_type i32) (result i32)
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
  (func $check_option_none_pattern (param $pattern_node i32) (param $expected_type i32) (result i32)
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
  (func $check_result_ok_pattern (param $pattern_node i32) (param $expected_type i32) (result i32)
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
  (func $check_result_err_pattern (param $pattern_node i32) (param $expected_type i32) (result i32)
    (local $inner_pattern i32)
    (local $inner_type i32)
    (local $result i32)

    ;; Verify that expected_type is a result type
    ;; For now, we use a simplified check - in a complete implementation,
    ;; we would have proper type introspection to check if it's result<T, E>

    ;; Get the inner pattern (first child of the error pattern)
    (local.set $inner_pattern (call $get_child (local.get $pattern_node) (i32.const 0)))
    (if (i32.eqz (local.get $inner_pattern))
      (then (return (i32.const 1)))) ;; Error: error pattern must have inner pattern

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
  (func $check_tuple_pattern (param $pattern_node i32) (param $expected_type i32) (result i32)
    (local $element_count i32)
    (local $i i32)
    (local $element_pattern i32)
    (local $element_type i32)
    (local $result i32)

    ;; Get the number of elements in the tuple pattern
    (local.set $element_count (call $get_child_count (local.get $pattern_node)))

    ;; For now, we assume all tuple elements have the same type as the expected type
    ;; In a complete implementation, we would extract individual element types from tuple<T1, T2, ...>
    (local.set $element_type (local.get $expected_type))

    ;; Check each element pattern
    (local.set $i (i32.const 0))
    (loop $element_loop
      (if (i32.lt_u (local.get $i) (local.get $element_count))
        (then
          (local.set $element_pattern (call $get_child (local.get $pattern_node) (local.get $i)))
          (if (local.get $element_pattern)
            (then
              ;; Recursively check this element pattern
              (local.set $result (call $check_pattern (local.get $element_pattern) (local.get $element_type)))
              (if (i32.ne (local.get $result) (i32.const 0))
                (then (return (local.get $result))))))

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $element_loop))))

    ;; Set pattern type info
    (drop (call $set_node_type_info (local.get $pattern_node) (local.get $expected_type)))

    (i32.const 0) ;; Success
  )

  ;; Check record pattern
  (func $check_record_pattern (param $pattern_node i32) (param $expected_type i32) (result i32)
    (local $field_count i32)
    (local $i i32)
    (local $field_pattern i32)
    (local $field_type i32)
    (local $result i32)

    ;; Get the number of fields in the record pattern
    (local.set $field_count (call $get_child_count (local.get $pattern_node)))

    ;; For now, we assume all record fields have the same type as the expected type
    ;; In a complete implementation, we would:
    ;; 1. Extract field names from the pattern
    ;; 2. Look up field types in the record type definition
    ;; 3. Match field patterns against their corresponding types
    (local.set $field_type (local.get $expected_type))

    ;; Check each field pattern
    (local.set $i (i32.const 0))
    (loop $field_loop
      (if (i32.lt_u (local.get $i) (local.get $field_count))
        (then
          (local.set $field_pattern (call $get_child (local.get $pattern_node) (local.get $i)))
          (if (local.get $field_pattern)
            (then
              ;; Recursively check this field pattern
              (local.set $result (call $check_pattern (local.get $field_pattern) (local.get $field_type)))
              (if (i32.ne (local.get $result) (i32.const 0))
                (then (return (local.get $result))))))

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $field_loop))))

    ;; Set pattern type info
    (drop (call $set_node_type_info (local.get $pattern_node) (local.get $expected_type)))

    (i32.const 0) ;; Success
  )

  ;; Check variant pattern
  (func $check_variant_pattern (param $pattern_node i32) (param $expected_type i32) (result i32)
    (local $variant_tag i32)
    (local $field_count i32)
    (local $i i32)
    (local $field_pattern i32)
    (local $field_type i32)
    (local $result i32)

    ;; Verify that expected_type is a variant type
    ;; For now, we use a simplified check - in a complete implementation,
    ;; we would have proper type introspection to check variant compatibility

    ;; Get the variant tag (this would be extracted from the pattern AST)
    ;; For now, we use a placeholder
    (local.set $variant_tag (i32.const 0))

    ;; Get the number of fields in the variant pattern
    (local.set $field_count (call $get_child_count (local.get $pattern_node)))

    ;; For now, assume all variant fields have the same type as the expected type
    ;; In a complete implementation, we would:
    ;; 1. Extract the variant constructor name from the pattern
    ;; 2. Look up the constructor's field types in the variant definition
    ;; 3. Match field patterns against their corresponding types
    (local.set $field_type (local.get $expected_type))

    ;; Check each field pattern
    (local.set $i (i32.const 0))
    (loop $field_loop
      (if (i32.lt_u (local.get $i) (local.get $field_count))
        (then
          (local.set $field_pattern (call $get_child (local.get $pattern_node) (local.get $i)))
          (if (local.get $field_pattern)
            (then
              ;; Recursively check this field pattern
              (local.set $result (call $check_pattern (local.get $field_pattern) (local.get $field_type)))
              (if (i32.ne (local.get $result) (i32.const 0))
                (then (return (local.get $result))))))

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $field_loop))))

    ;; Set pattern type info
    (drop (call $set_node_type_info (local.get $pattern_node) (local.get $expected_type)))

    (i32.const 0) ;; Success
  )

  ;; Helper function to check if a match arm contains a wildcard pattern
  (func $is_wildcard_arm (param $arm_node i32) (result i32)
    (local $pattern_node i32)

    (local.set $pattern_node (call $get_child (local.get $arm_node) (i32.const 0)))
    (if (i32.eqz (local.get $pattern_node))
      (then (return (i32.const 0))))

    (i32.eq (call $get_node_type (local.get $pattern_node)) (global.get $PAT_WILDCARD))
  )

  ;; Check if a pattern contains guard expressions (boolean expressions)
  ;; @param $pattern_node i32 - Pointer to pattern AST node
  ;; @returns i32 - Result (0 = success, 1 = error)
  (func $check_pattern_guard (export "check_pattern_guard") (param $pattern_node i32) (result i32)
    (local $guard_expr i32)
    (local $guard_type i32)

    ;; Check if this pattern has a guard expression
    ;; For now, we assume guard expressions are stored as a child node
    ;; In a complete implementation, we would have a specific field for guards
    (local.set $guard_expr (call $get_child (local.get $pattern_node) (i32.const 1)))

    (if (i32.eqz (local.get $guard_expr))
      (then (return (i32.const 0)))) ;; No guard, success

    ;; Type check the guard expression
    ;; Guards must evaluate to boolean type
    (local.set $guard_type (call $get_node_type_info (local.get $guard_expr)))

    ;; If guard type is unknown, it might need type inference
    (if (i32.eq (local.get $guard_type) (global.get $TYPE_UNKNOWN))
      (then
        ;; Set expected type to boolean
        (call $set_node_type_info (local.get $guard_expr) (global.get $TYPE_BOOL))
        (return (i32.const 0))))

    ;; Check if guard type is compatible with boolean
    (call $types_compatible (local.get $guard_type) (global.get $TYPE_BOOL))
  )

  ;; Validate exhaustiveness of match statement
  ;; @param $match_node i32 - Pointer to match AST node
  ;; @returns i32 - Result (0 = exhaustive, 1 = non-exhaustive)
  (func $check_exhaustiveness (export "check_exhaustiveness") (param $match_node i32) (result i32)
    (local $arm_count i32)
    (local $i i32)
    (local $arm_node i32)
    (local $has_wildcard i32)

    ;; Get match arms (skip expression, which is first child)
    (local.set $arm_count (call $get_child_count (local.get $match_node)))
    (local.set $i (i32.const 1))
    (local.set $has_wildcard (i32.const 0))

    (loop $check_loop
      (if (i32.lt_u (local.get $i) (local.get $arm_count))
        (then
          (local.set $arm_node (call $get_child (local.get $match_node) (local.get $i)))

          ;; Check if this arm has a wildcard pattern
          (if (call $is_wildcard_arm (local.get $arm_node))
            (then (local.set $has_wildcard (i32.const 1))))

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $check_loop))))

    ;; For now, we consider a match exhaustive if it has a wildcard
    ;; A more complete implementation would analyze all patterns for exhaustiveness
    (if (local.get $has_wildcard)
      (then (return (i32.const 0)))  ;; Exhaustive
      (else (return (i32.const 1)))) ;; Non-exhaustive

    ;; This should never be reached, but needed for type checking
    (i32.const 1)
  )
)
