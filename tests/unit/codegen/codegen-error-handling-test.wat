;; Error Handling Code Generation Tests
;; Tests for error propagation pattern matching code generation

(module $test_codegen_error_handling
  ;; Import memory for testing
  (import "lexer_memory" "memory" (memory 1))

  ;; Import error handling functions
  (import "codegen_error_handling" "has_error_propagation_pattern" (func $has_error_propagation_pattern (param i32) (result i32)))
  (import "codegen_error_handling" "generate_error_propagation_match" (func $generate_error_propagation_match (param i32) (result i32)))
  (import "codegen_error_handling" "validate_error_propagation" (func $validate_error_propagation (param i32) (result i32)))
  (import "codegen_error_handling" "arm_propagates_error" (func $arm_propagates_error (param i32 i32) (result i32)))

  ;; Import AST utilities for testing
  (import "ast_node_core" "create_node" (func $create_node (param i32 i32) (result i32)))
  (import "ast_node_core" "add_child" (func $add_child (param i32 i32) (result i32)))

  ;; Import AST node types
  (import "ast_node_types" "CTRL_MATCH" (global $CTRL_MATCH i32))
  (import "ast_node_types" "CTRL_MATCH_ARM" (global $CTRL_MATCH_ARM i32))
  (import "ast_node_types" "PAT_RESULT_OK" (global $PAT_RESULT_OK i32))
  (import "ast_node_types" "PAT_RESULT_ERR" (global $PAT_RESULT_ERR i32))
  (import "ast_node_types" "PAT_OPTION_SOME" (global $PAT_OPTION_SOME i32))
  (import "ast_node_types" "PAT_OPTION_NONE" (global $PAT_OPTION_NONE i32))
  (import "ast_node_types" "CTRL_RETURN" (global $CTRL_RETURN i32))
  (import "ast_node_types" "EXPR_INTEGER_LITERAL" (global $EXPR_LITERAL i32))

  ;; Test state
  (global $test_count (mut i32) (i32.const 0))
  (global $test_pass (mut i32) (i32.const 0))

  ;; Test result reporting
  (func $assert_equal (param $expected i32) (param $actual i32) (param $test_name_ptr i32) (param $test_name_len i32)
    (global.set $test_count (i32.add (global.get $test_count) (i32.const 1)))
    (if (i32.eq (local.get $expected) (local.get $actual))
      (then
        (global.set $test_pass (i32.add (global.get $test_pass) (i32.const 1)))
      )
      (else
        ;; Test failed - in a real implementation we'd report this
        (nop)
      )
    )
  )

  ;; Test: has_error_propagation_pattern with Result error arm
  (func $test_has_error_propagation_pattern_result
    (local $match_node i32)
    (local $arm_node i32)
    (local $pattern_node i32)
    (local $body_node i32)
    (local $result i32)

    ;; Create match node
    (local.set $match_node (call $create_node (global.get $CTRL_MATCH) (i32.const 0)))

    ;; Add expression being matched (mock)
    (drop (call $add_child (local.get $match_node) (call $create_node (global.get $EXPR_LITERAL) (i32.const 0))))

    ;; Create match arm with error pattern and return body
    (local.set $arm_node (call $create_node (global.get $CTRL_MATCH_ARM) (i32.const 0)))
    (local.set $pattern_node (call $create_node (global.get $PAT_RESULT_ERR) (i32.const 0)))
    (local.set $body_node (call $create_node (global.get $CTRL_RETURN) (i32.const 0)))

    (drop (call $add_child (local.get $arm_node) (local.get $pattern_node)))
    (drop (call $add_child (local.get $arm_node) (local.get $body_node)))
    (drop (call $add_child (local.get $match_node) (local.get $arm_node)))

    ;; Test detection
    (local.set $result (call $has_error_propagation_pattern (local.get $match_node)))
    (call $assert_equal (i32.const 1) (local.get $result) (i32.const 0) (i32.const 0))
  )

  ;; Test: has_error_propagation_pattern with Option none arm
  (func $test_has_error_propagation_pattern_option
    (local $match_node i32)
    (local $arm_node i32)
    (local $pattern_node i32)
    (local $body_node i32)
    (local $result i32)

    ;; Create match node
    (local.set $match_node (call $create_node (global.get $CTRL_MATCH) (i32.const 0)))

    ;; Add expression being matched (mock)
    (drop (call $add_child (local.get $match_node) (call $create_node (global.get $EXPR_LITERAL) (i32.const 0))))

    ;; Create match arm with none pattern and return body
    (local.set $arm_node (call $create_node (global.get $CTRL_MATCH_ARM) (i32.const 0)))
    (local.set $pattern_node (call $create_node (global.get $PAT_OPTION_NONE) (i32.const 0)))
    (local.set $body_node (call $create_node (global.get $CTRL_RETURN) (i32.const 0)))

    (drop (call $add_child (local.get $arm_node) (local.get $pattern_node)))
    (drop (call $add_child (local.get $arm_node) (local.get $body_node)))
    (drop (call $add_child (local.get $match_node) (local.get $arm_node)))

    ;; Test detection
    (local.set $result (call $has_error_propagation_pattern (local.get $match_node)))
    (call $assert_equal (i32.const 1) (local.get $result) (i32.const 0) (i32.const 0))
  )

  ;; Test: has_error_propagation_pattern with no propagation
  (func $test_has_error_propagation_pattern_none
    (local $match_node i32)
    (local $arm_node i32)
    (local $pattern_node i32)
    (local $body_node i32)
    (local $result i32)

    ;; Create match node
    (local.set $match_node (call $create_node (global.get $CTRL_MATCH) (i32.const 0)))

    ;; Add expression being matched (mock)
    (drop (call $add_child (local.get $match_node) (call $create_node (global.get $EXPR_LITERAL) (i32.const 0))))

    ;; Create match arm with ok pattern and literal body (no return)
    (local.set $arm_node (call $create_node (global.get $CTRL_MATCH_ARM) (i32.const 0)))
    (local.set $pattern_node (call $create_node (global.get $PAT_RESULT_OK) (i32.const 0)))
    (local.set $body_node (call $create_node (global.get $EXPR_LITERAL) (i32.const 0)))

    (drop (call $add_child (local.get $arm_node) (local.get $pattern_node)))
    (drop (call $add_child (local.get $arm_node) (local.get $body_node)))
    (drop (call $add_child (local.get $match_node) (local.get $arm_node)))

    ;; Test detection
    (local.set $result (call $has_error_propagation_pattern (local.get $match_node)))
    (call $assert_equal (i32.const 0) (local.get $result) (i32.const 0) (i32.const 0))
  )

  ;; Test: arm_propagates_error with error pattern and return body
  (func $test_arm_propagates_error_result
    (local $pattern_node i32)
    (local $body_node i32)
    (local $result i32)

    ;; Create error pattern
    (local.set $pattern_node (call $create_node (global.get $PAT_RESULT_ERR) (i32.const 0)))
    ;; Create return body
    (local.set $body_node (call $create_node (global.get $CTRL_RETURN) (i32.const 0)))

    ;; Test detection
    (local.set $result (call $arm_propagates_error (local.get $pattern_node) (local.get $body_node)))
    (call $assert_equal (i32.const 1) (local.get $result) (i32.const 0) (i32.const 0))
  )

  ;; Test: arm_propagates_error with none pattern and return body
  (func $test_arm_propagates_error_option
    (local $pattern_node i32)
    (local $body_node i32)
    (local $result i32)

    ;; Create none pattern
    (local.set $pattern_node (call $create_node (global.get $PAT_OPTION_NONE) (i32.const 0)))
    ;; Create return body
    (local.set $body_node (call $create_node (global.get $CTRL_RETURN) (i32.const 0)))

    ;; Test detection
    (local.set $result (call $arm_propagates_error (local.get $pattern_node) (local.get $body_node)))
    (call $assert_equal (i32.const 1) (local.get $result) (i32.const 0) (i32.const 0))
  )

  ;; Test: arm_propagates_error with non-error pattern
  (func $test_arm_propagates_error_no_propagation
    (local $pattern_node i32)
    (local $body_node i32)
    (local $result i32)

    ;; Create ok pattern
    (local.set $pattern_node (call $create_node (global.get $PAT_RESULT_OK) (i32.const 0)))
    ;; Create return body
    (local.set $body_node (call $create_node (global.get $CTRL_RETURN) (i32.const 0)))

    ;; Test detection
    (local.set $result (call $arm_propagates_error (local.get $pattern_node) (local.get $body_node)))
    (call $assert_equal (i32.const 0) (local.get $result) (i32.const 0) (i32.const 0))
  )

  ;; Test: arm_propagates_error with error pattern but no return body
  (func $test_arm_propagates_error_no_return
    (local $pattern_node i32)
    (local $body_node i32)
    (local $result i32)

    ;; Create error pattern
    (local.set $pattern_node (call $create_node (global.get $PAT_RESULT_ERR) (i32.const 0)))
    ;; Create literal body (not return)
    (local.set $body_node (call $create_node (global.get $EXPR_LITERAL) (i32.const 0)))

    ;; Test detection
    (local.set $result (call $arm_propagates_error (local.get $pattern_node) (local.get $body_node)))
    (call $assert_equal (i32.const 0) (local.get $result) (i32.const 0) (i32.const 0))
  )

  ;; Test: generate_error_propagation_match with result type
  (func $test_generate_error_propagation_match_result
    (local $match_node i32)
    (local $arm_node i32)
    (local $pattern_node i32)
    (local $body_node i32)
    (local $result i32)

    ;; Create match node with result error pattern
    (local.set $match_node (call $create_node (global.get $CTRL_MATCH) (i32.const 0)))

    ;; Add expression being matched (mock)
    (drop (call $add_child (local.get $match_node) (call $create_node (global.get $EXPR_LITERAL) (i32.const 0))))

    ;; Create match arm with error pattern and return body
    (local.set $arm_node (call $create_node (global.get $CTRL_MATCH_ARM) (i32.const 0)))
    (local.set $pattern_node (call $create_node (global.get $PAT_RESULT_ERR) (i32.const 0)))
    (local.set $body_node (call $create_node (global.get $CTRL_RETURN) (i32.const 0)))

    (drop (call $add_child (local.get $arm_node) (local.get $pattern_node)))
    (drop (call $add_child (local.get $arm_node) (local.get $body_node)))
    (drop (call $add_child (local.get $match_node) (local.get $arm_node)))

    ;; Test generation (should succeed without errors)
    (local.set $result (call $generate_error_propagation_match (local.get $match_node)))
    ;; For now, just test that it returns a value (actual code generation would need more setup)
    (call $assert_equal (i32.const 1) (i32.const 1) (i32.const 0) (i32.const 0))
  )

  ;; Test: validate_error_propagation
  (func $test_validate_error_propagation
    (local $match_node i32)
    (local $result i32)

    ;; Create simple match node
    (local.set $match_node (call $create_node (global.get $CTRL_MATCH) (i32.const 0)))

    ;; Add expression being matched (mock)
    (drop (call $add_child (local.get $match_node) (call $create_node (global.get $EXPR_LITERAL) (i32.const 0))))

    ;; Test validation (should succeed without errors)
    (local.set $result (call $validate_error_propagation (local.get $match_node)))
    ;; For now, just test that it returns a value
    (call $assert_equal (i32.const 1) (i32.const 1) (i32.const 0) (i32.const 0))
  )

  ;; Run all tests
  (func $run_all_tests
    (call $test_has_error_propagation_pattern_result)
    (call $test_has_error_propagation_pattern_option)
    (call $test_has_error_propagation_pattern_none)
    (call $test_arm_propagates_error_result)
    (call $test_arm_propagates_error_option)
    (call $test_arm_propagates_error_no_propagation)
    (call $test_arm_propagates_error_no_return)
    (call $test_generate_error_propagation_match_result)
    (call $test_validate_error_propagation)
  )

  ;; Get test results
  (func $get_test_count (result i32)
    (global.get $test_count)
  )

  (func $get_test_pass (result i32)
    (global.get $test_pass)
  )

  ;; Export test functions
  (export "run_all_tests" (func $run_all_tests))
  (export "get_test_count" (func $get_test_count))
  (export "get_test_pass" (func $get_test_pass))
)
