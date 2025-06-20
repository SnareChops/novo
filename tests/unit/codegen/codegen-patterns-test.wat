;; Pattern Matching Code Generation Tests
;; Tests for match statement compilation and pattern testing

(module $codegen_patterns_test
  ;; Import memory for testing
  (import "lexer_memory" "memory" (memory 1))

  ;; Import pattern matching codegen
  (import "codegen_patterns" "generate_pattern_matching" (func $generate_pattern_matching (param i32) (result i32)))
  (import "codegen_patterns" "check_exhaustiveness" (func $check_exhaustiveness (param i32) (result i32)))

  ;; Import AST creation functions
  (import "ast_control_flow_creators" "create_match_node" (func $create_match_node (param i32) (result i32)))
  (import "ast_control_flow_creators" "create_match_arm_node" (func $create_match_arm_node (param i32 i32) (result i32)))
  (import "ast_pattern_creators" "create_pattern_literal_node" (func $create_pattern_literal_node (param i32 i32) (result i32)))
  (import "ast_pattern_creators" "create_pattern_variable_node" (func $create_pattern_variable_node (param i32) (result i32)))
  (import "ast_pattern_creators" "create_pattern_wildcard_node" (func $create_pattern_wildcard_node (result i32)))

  ;; Import AST node creation for expressions (simplified)
  (import "ast_node_core" "create_node" (func $create_node (param i32 i32) (result i32)))
  (import "ast_node_core" "add_child" (func $add_child (param i32 i32) (result i32)))

  ;; Import AST node types
  (import "ast_node_types" "PAT_LITERAL" (global $PAT_LITERAL i32))
  (import "ast_node_types" "PAT_VARIABLE" (global $PAT_VARIABLE i32))
  (import "ast_node_types" "PAT_WILDCARD" (global $PAT_WILDCARD i32))
  (import "ast_node_types" "EXPR_IDENTIFIER" (global $EXPR_IDENTIFIER i32))

  ;; Helper function to create a simple identifier node for testing
  (func $create_simple_identifier (param $token_pos i32) (result i32)
    ;; Create a simple identifier node with just token position
    (call $create_node (global.get $EXPR_IDENTIFIER) (i32.const 4))
  )

  ;; Test basic pattern matching code generation
  (func $test_basic_pattern_matching (result i32)
    (local $match_node i32)
    (local $match_expr i32)
    (local $arm_node i32)
    (local $pattern_node i32)
    (local $body_node i32)
    (local $result i32)
    (local $test_passed i32)

    (local.set $test_passed (i32.const 0))

    ;; Create a simple match expression: match x { 42 => "found" }
    (local.set $match_expr (call $create_simple_identifier (i32.const 0))) ;; x
    (local.set $match_node (call $create_match_node (local.get $match_expr)))

    ;; Check if match node was created successfully
    (if (local.get $match_node)
      (then
        (local.set $test_passed (i32.add (local.get $test_passed) (i32.const 1)))
      )
    )

    ;; Create pattern: 42
    (local.set $pattern_node (call $create_pattern_literal_node (global.get $PAT_LITERAL) (i32.const 1)))

    ;; Create body: "found"
    (local.set $body_node (call $create_simple_identifier (i32.const 2)))

    ;; Create match arm: 42 => "found"
    (local.set $arm_node (call $create_match_arm_node (local.get $pattern_node) (local.get $body_node)))

    ;; Check if arm node was created successfully
    (if (local.get $arm_node)
      (then
        (local.set $test_passed (i32.add (local.get $test_passed) (i32.const 1)))
      )
    )

    ;; Add arm to match
    (drop (call $add_child (local.get $match_node) (local.get $arm_node)))

    ;; Test code generation
    (local.set $result (call $generate_pattern_matching (local.get $match_node)))

    ;; Check if code generation succeeded
    (if (local.get $result)
      (then
        (local.set $test_passed (i32.add (local.get $test_passed) (i32.const 1)))
      )
    )

    (local.get $test_passed)
  )

  ;; Test variable pattern code generation
  (func $test_variable_pattern (result i32)
    (local $match_node i32)
    (local $match_expr i32)
    (local $arm_node i32)
    (local $pattern_node i32)
    (local $body_node i32)
    (local $result i32)
    (local $test_passed i32)

    (local.set $test_passed (i32.const 0))

    ;; Create match expression: match x { y => y }
    (local.set $match_expr (call $create_simple_identifier (i32.const 0))) ;; x
    (local.set $match_node (call $create_match_node (local.get $match_expr)))

    ;; Check if match node was created successfully
    (if (local.get $match_node)
      (then
        (local.set $test_passed (i32.add (local.get $test_passed) (i32.const 1)))
      )
    )

    ;; Create variable pattern: y
    (local.set $pattern_node (call $create_pattern_variable_node (i32.const 1)))

    ;; Create body: y
    (local.set $body_node (call $create_simple_identifier (i32.const 1)))

    ;; Create match arm: y => y
    (local.set $arm_node (call $create_match_arm_node (local.get $pattern_node) (local.get $body_node)))

    ;; Add arm to match
    (drop (call $add_child (local.get $match_node) (local.get $arm_node)))

    ;; Test code generation
    (local.set $result (call $generate_pattern_matching (local.get $match_node)))

    ;; Check if code generation succeeded
    (if (local.get $result)
      (then
        (local.set $test_passed (i32.add (local.get $test_passed) (i32.const 1)))
      )
    )

    (local.get $test_passed)
  )

  ;; Test exhaustiveness checking
  (func $test_exhaustiveness_check (result i32)
    (local $match_node i32)
    (local $match_expr i32)
    (local $arm_node i32)
    (local $pattern_node i32)
    (local $body_node i32)
    (local $result i32)
    (local $test_passed i32)

    (local.set $test_passed (i32.const 0))

    ;; Create match with wildcard pattern (should be exhaustive)
    (local.set $match_expr (call $create_simple_identifier (i32.const 0))) ;; x
    (local.set $match_node (call $create_match_node (local.get $match_expr)))

    ;; Create wildcard pattern: _
    (local.set $pattern_node (call $create_pattern_wildcard_node))
    (local.set $body_node (call $create_simple_identifier (i32.const 1)))
    (local.set $arm_node (call $create_match_arm_node (local.get $pattern_node) (local.get $body_node)))
    (drop (call $add_child (local.get $match_node) (local.get $arm_node)))

    ;; Test exhaustiveness (should return 1 - exhaustive)
    (local.set $result (call $check_exhaustiveness (local.get $match_node)))

    ;; Check if exhaustiveness check returned correct result
    (if (i32.eq (local.get $result) (i32.const 1))
      (then
        (local.set $test_passed (i32.add (local.get $test_passed) (i32.const 1)))
      )
    )

    (local.get $test_passed)
  )

  ;; Run all tests and return total passed
  (func $run_all_tests (result i32)
    (local $total_passed i32)

    (local.set $total_passed (i32.const 0))

    ;; Run basic pattern matching test
    (local.set $total_passed (i32.add (local.get $total_passed) (call $test_basic_pattern_matching)))

    ;; Run variable pattern test
    (local.set $total_passed (i32.add (local.get $total_passed) (call $test_variable_pattern)))

    ;; Run exhaustiveness check test
    (local.set $total_passed (i32.add (local.get $total_passed) (call $test_exhaustiveness_check)))

    (local.get $total_passed)
  )

  ;; Main test function
  (func $main (export "_start") (result i32)
    (local $passed i32)
    (local $expected i32)
    (local $result i32)

    ;; Expected: 3 tests should pass basic functionality + 2 tests should pass generation + 1 test should pass exhaustiveness = 6
    (local.set $expected (i32.const 6))

    ;; Run all tests
    (local.set $passed (call $run_all_tests))

    ;; Return 0 if all tests passed, 1 if some failed
    (if (i32.eq (local.get $passed) (local.get $expected))
      (then
        (local.set $result (i32.const 0))  ;; Success
      )
      (else
        (local.set $result (i32.const 1))  ;; Failure
      )
    )

    (local.get $result)
  )
)
