;; Pattern Matching Type Checker - Validation and Exhaustiveness
;; Handles pattern validation, guards, and exhaustiveness checking

(module $typechecker_pattern_validation
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import type checker infrastructure
  (import "typechecker_main" "get_node_type_info" (func $get_node_type_info (param i32) (result i32)))
  (import "typechecker_main" "set_node_type_info" (func $set_node_type_info (param i32 i32) (result i32)))
  (import "typechecker_main" "types_compatible" (func $types_compatible (param i32 i32) (result i32)))

  ;; Import AST functions
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "ast_node_core" "get_child_count" (func $get_child_count (param i32) (result i32)))
  (import "ast_node_core" "get_child" (func $get_child (param i32 i32) (result i32)))

  ;; Import node type constants
  (import "ast_node_types" "PAT_WILDCARD" (global $PAT_WILDCARD i32))

  ;; Import type constants
  (import "typechecker_main" "TYPE_UNKNOWN" (global $TYPE_UNKNOWN i32))
  (import "typechecker_main" "TYPE_BOOL" (global $TYPE_BOOL i32))

  ;; Helper function to check if a match arm contains a wildcard pattern
  ;; @param $arm_node i32 - Pointer to match arm AST node
  ;; @returns i32 - 1 if wildcard, 0 otherwise
  (func $is_wildcard_arm (export "is_wildcard_arm") (param $arm_node i32) (result i32)
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

  ;; Check pattern completeness for a specific type
  ;; @param $match_node i32 - Pointer to match AST node
  ;; @param $expression_type i32 - Type being matched against
  ;; @returns i32 - Result (0 = complete, 1 = incomplete)
  (func $check_pattern_completeness (export "check_pattern_completeness") (param $match_node i32) (param $expression_type i32) (result i32)
    ;; Simplified implementation - always return complete for now
    ;; A full implementation would check:
    ;; - All enum variants are covered
    ;; - Option types have both Some and None cases (or wildcard)
    ;; - Result types have both Ok and Err cases (or wildcard)
    ;; - Tuple/record patterns cover all fields appropriately

    ;; For now, delegate to exhaustiveness check
    (call $check_exhaustiveness (local.get $match_node))
  )

  ;; Validate pattern reachability (detect unreachable patterns)
  ;; @param $match_node i32 - Pointer to match AST node
  ;; @returns i32 - Result (0 = all reachable, 1 = unreachable patterns found)
  (func $check_pattern_reachability (export "check_pattern_reachability") (param $match_node i32) (result i32)
    (local $arm_count i32)
    (local $i i32)
    (local $arm_node i32)
    (local $wildcard_index i32)

    ;; Find if there's a wildcard pattern and its position
    (local.set $arm_count (call $get_child_count (local.get $match_node)))
    (local.set $i (i32.const 1)) ;; Skip expression
    (local.set $wildcard_index (i32.const -1))

    (loop $find_wildcard_loop
      (if (i32.lt_u (local.get $i) (local.get $arm_count))
        (then
          (local.set $arm_node (call $get_child (local.get $match_node) (local.get $i)))

          ;; Check if this arm has a wildcard pattern
          (if (call $is_wildcard_arm (local.get $arm_node))
            (then
              (local.set $wildcard_index (local.get $i))
              (br $find_wildcard_loop))) ;; Exit early - found wildcard

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $find_wildcard_loop))))

    ;; If wildcard found and it's not the last arm, there are unreachable patterns
    (if (i32.and
          (i32.ne (local.get $wildcard_index) (i32.const -1))
          (i32.lt_u (local.get $wildcard_index) (i32.sub (local.get $arm_count) (i32.const 1))))
      (then (return (i32.const 1)))) ;; Unreachable patterns found

    (i32.const 0) ;; All patterns reachable
  )

  ;; Validate that all patterns in a match are well-formed
  ;; @param $match_node i32 - Pointer to match AST node
  ;; @returns i32 - Result (0 = well-formed, 1 = malformed patterns)
  (func $validate_pattern_structure (export "validate_pattern_structure") (param $match_node i32) (result i32)
    (local $arm_count i32)
    (local $i i32)
    (local $arm_node i32)
    (local $pattern_node i32)

    ;; Check each match arm has proper structure
    (local.set $arm_count (call $get_child_count (local.get $match_node)))
    (local.set $i (i32.const 1)) ;; Skip expression

    (loop $validate_loop
      (if (i32.lt_u (local.get $i) (local.get $arm_count))
        (then
          (local.set $arm_node (call $get_child (local.get $match_node) (local.get $i)))

          ;; Each arm must have at least a pattern (child 0)
          (local.set $pattern_node (call $get_child (local.get $arm_node) (i32.const 0)))
          (if (i32.eqz (local.get $pattern_node))
            (then (return (i32.const 1)))) ;; Malformed - no pattern

          ;; Each arm must have a body (child 1)
          (if (i32.eqz (call $get_child (local.get $arm_node) (i32.const 1)))
            (then (return (i32.const 1)))) ;; Malformed - no body

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $validate_loop))))

    (i32.const 0) ;; All patterns well-formed
  )
)
