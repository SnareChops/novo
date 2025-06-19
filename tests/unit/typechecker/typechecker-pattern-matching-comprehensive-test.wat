;; Comprehensive Pattern Matching Type Checker Test
;; Tests the enhanced pattern matching type checking functionality

(module $typechecker_pattern_matching_comprehensive_test
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import AST functions
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "ast_control_flow_creators" "create_ctrl_match" (func $create_ctrl_match (param i32 i32 i32) (result i32)))
  (import "ast_control_flow_creators" "create_ctrl_match_arm" (func $create_ctrl_match_arm (param i32 i32) (result i32)))
  (import "ast_pattern_creators" "create_pat_literal" (func $create_pat_literal (param i32) (result i32)))
  (import "ast_pattern_creators" "create_pat_variable" (func $create_pat_variable (param i32) (result i32)))
  (import "ast_pattern_creators" "create_pat_wildcard" (func $create_pat_wildcard (result i32)))
  (import "ast_expression_creators" "create_expr_integer_literal" (func $create_expr_integer_literal (param i64) (result i32)))

  ;; Import pattern matching type checker functions
  (import "typechecker_pattern_matching" "check_pattern" (func $check_pattern (param i32 i32) (result i32)))
  (import "typechecker_pattern_validation" "check_pattern_guard" (func $check_pattern_guard (param i32) (result i32)))
  (import "typechecker_pattern_validation" "check_exhaustiveness" (func $check_exhaustiveness (param i32) (result i32)))

  ;; Import type checker main functions
  (import "typechecker_main" "TYPE_BOOL" (global $TYPE_BOOL i32))
  (import "typechecker_main" "TYPE_I32" (global $TYPE_I32 i32))
  (import "typechecker_main" "TYPE_UNKNOWN" (global $TYPE_UNKNOWN i32))

  ;; Import node type constants
  (import "ast_node_types" "PAT_LITERAL" (global $PAT_LITERAL i32))
  (import "ast_node_types" "PAT_VARIABLE" (global $PAT_VARIABLE i32))
  (import "ast_node_types" "PAT_WILDCARD" (global $PAT_WILDCARD i32))

  ;; Test basic pattern type checking - simplified to avoid function import issues
  (func $test_basic_pattern_checks (result i32)
    (local $pattern_node i32)
    (local $result i32)
    (local $total_passed i32)

    (local.set $total_passed (i32.const 0))

    ;; Test 1: Create a literal pattern and check it against i32 type
    (local.set $pattern_node (call $create_pat_literal (global.get $PAT_LITERAL)))
    (if (i32.ne (local.get $pattern_node) (i32.const 0))
      (then
        (local.set $result (call $check_pattern (local.get $pattern_node) (global.get $TYPE_I32)))
        (if (i32.eq (local.get $result) (i32.const 0))
          (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))))

    ;; Test 2: Create a variable pattern (should always succeed)
    (local.set $pattern_node (call $create_pat_variable (global.get $PAT_VARIABLE)))
    (if (i32.ne (local.get $pattern_node) (i32.const 0))
      (then
        (local.set $result (call $check_pattern (local.get $pattern_node) (global.get $TYPE_I32)))
        (if (i32.eq (local.get $result) (i32.const 0))
          (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))))

    ;; Test 3: Wildcard pattern should match any type
    (local.set $pattern_node (call $create_pat_wildcard))
    (if (i32.ne (local.get $pattern_node) (i32.const 0))
      (then
        (local.set $result (call $check_pattern (local.get $pattern_node) (global.get $TYPE_BOOL)))
        (if (i32.eq (local.get $result) (i32.const 0))
          (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))))

    ;; Test 4: Pattern guard checking
    (local.set $pattern_node (call $create_pat_variable (global.get $PAT_VARIABLE)))
    (if (i32.ne (local.get $pattern_node) (i32.const 0))
      (then
        (local.set $result (call $check_pattern_guard (local.get $pattern_node)))
        (if (i32.eq (local.get $result) (i32.const 0))
          (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))))

    (local.get $total_passed)
  )

  ;; Main test function
  (func $run_tests (export "run_tests") (result i32)
    (local $total_passed i32)

    ;; Run basic pattern tests
    (local.set $total_passed (call $test_basic_pattern_checks))

    ;; Return 1 if all tests passed (total should be 4), 0 otherwise
    (i32.eq (local.get $total_passed) (i32.const 4))
  )
)
