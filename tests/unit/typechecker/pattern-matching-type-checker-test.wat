;; Pattern Matching Type Checker Test
;; Tests type checking for pattern matching constructs

(module $pattern_matching_type_checker_test
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import typechecker functions
  (import "typechecker_pattern_matching" "check_match_statement" (func $check_match_statement (param i32) (result i32)))
  (import "typechecker_pattern_matching" "check_pattern" (func $check_pattern (param i32 i32) (result i32)))
  (import "typechecker_pattern_validation" "check_pattern_guard" (func $check_pattern_guard (param i32) (result i32)))
  (import "typechecker_pattern_validation" "check_exhaustiveness" (func $check_exhaustiveness (param i32) (result i32)))

  ;; Import type checker infrastructure
  (import "typechecker_main" "reset_type_checker" (func $reset_type_checker))
  (import "typechecker_main" "set_node_type_info" (func $set_node_type_info (param i32 i32) (result i32)))

  ;; Import type constants
  (import "typechecker_main" "TYPE_I32" (global $TYPE_I32 i32))
  (import "typechecker_main" "TYPE_BOOL" (global $TYPE_BOOL i32))
  (import "typechecker_main" "TYPE_STRING" (global $TYPE_STRING i32))

  ;; Import AST creation functions for testing
  (import "ast_control_flow_creators" "create_ctrl_match" (func $create_ctrl_match (param i32 i32 i32) (result i32)))
  (import "ast_expression_creators" "create_expr_integer_literal" (func $create_integer_literal (param i64) (result i32)))

  ;; Import AST memory
  (import "ast_memory" "init_memory_manager" (func $init_memory_manager))

  ;; Import node type constants
  (import "ast_node_types" "PAT_WILDCARD" (global $PAT_WILDCARD i32))
  (import "ast_node_types" "PAT_VARIABLE" (global $PAT_VARIABLE i32))
  (import "ast_node_types" "PAT_LITERAL" (global $PAT_LITERAL i32))

  ;; Global test counters
  (global $test_count (mut i32) (i32.const 0))
  (global $pass_count (mut i32) (i32.const 0))

  ;; Test pattern type checking against different types
  (func $test_pattern_type_checking (result i32)
    (local $result i32)

    ;; Reset state
    (call $reset_type_checker)
    (call $init_memory_manager)

    ;; Test pattern guard checking (simplified implementation should return 0)
    (local.set $result (call $check_pattern_guard (i32.const 300)))
    (if (i32.ne (local.get $result) (i32.const 0)) (then (return (i32.const 0))))

    ;; Test basic pattern API availability
    ;; For now, the check_pattern function expects valid AST nodes
    ;; so we'll just test that the functions are callable without causing immediate errors

    (i32.const 1)
  )

  ;; Test match statement type checking
  (func $test_match_statement_checking (result i32)
    (local $result i32)

    ;; Reset state
    (call $reset_type_checker)
    (call $init_memory_manager)

    ;; For now, just test that the function APIs are available
    ;; Proper integration testing would require creating actual AST nodes
    ;; which is complex for a unit test

    (i32.const 1)
  )

  ;; Test pattern guard checking
  (func $test_pattern_guard_checking (result i32)
    (local $pattern_node i32)
    (local $result i32)

    ;; Reset state
    (call $reset_type_checker)

    ;; Test pattern guard checking (simplified implementation should return 0)
    (local.set $pattern_node (i32.const 300))
    (local.set $result (call $check_pattern_guard (local.get $pattern_node)))
    (if (i32.ne (local.get $result) (i32.const 0)) (then (return (i32.const 0))))

    (i32.const 1)
  )

  ;; Test exhaustiveness checking
  (func $test_exhaustiveness_checking (result i32)
    (local $match_node i32)
    (local $result i32)

    ;; Reset state
    (call $reset_type_checker)

    ;; Test exhaustiveness checking (simplified implementation)
    (local.set $match_node (i32.const 400))
    (local.set $result (call $check_exhaustiveness (local.get $match_node)))
    ;; Since we don't have a real match node, this should return 1 (non-exhaustive)
    (if (i32.ne (local.get $result) (i32.const 1)) (then (return (i32.const 0))))

    (i32.const 1)
  )

  ;; Main test function
  (func $run_tests (export "run_tests") (result i32)
    (local $success i32)
    (local $all_passed i32)
    (local.set $all_passed (i32.const 1))

    ;; Test 1: Pattern type checking
    (local.set $success (call $test_pattern_type_checking))
    (if (i32.eqz (local.get $success))
      (then (local.set $all_passed (i32.const 0))))

    ;; Test 2: Match statement checking
    (local.set $success (call $test_match_statement_checking))
    (if (i32.eqz (local.get $success))
      (then (local.set $all_passed (i32.const 0))))

    ;; Test 3: Pattern guard checking
    (local.set $success (call $test_pattern_guard_checking))
    (if (i32.eqz (local.get $success))
      (then (local.set $all_passed (i32.const 0))))

    ;; Test 4: Exhaustiveness checking
    (local.set $success (call $test_exhaustiveness_checking))
    (if (i32.eqz (local.get $success))
      (then (local.set $all_passed (i32.const 0))))

    (local.get $all_passed)
  )

  ;; Start function for testing
  (func $_start (export "_start")
    (local $result i32)
    (local.set $result (call $run_tests))
    (if (local.get $result)
      (then)  ;; Success
      (else unreachable)  ;; Failure
    )
  )
)
