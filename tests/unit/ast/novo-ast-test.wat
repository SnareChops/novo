;; Tests for Novo AST implementation
;; Tests memory management and node creation/manipulation

(module $novo_ast_test
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import memory management functions
  (import "ast_memory" "init_memory_manager" (func $init_memory_manager))
  (import "ast_memory" "free" (func $free (param i32)))

  ;; Import core node operations
  (import "ast_node_core" "create_node" (func $create_node (param i32 i32) (result i32)))
  (import "ast_node_core" "add_child" (func $add_child (param i32 i32) (result i32)))
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))

  ;; Import node creator functions
  (import "ast_type_creators" "create_type_primitive" (func $create_type_primitive (param i32) (result i32)))
  (import "ast_declaration_creators" "create_decl_function" (func $create_decl_function (param i32 i32) (result i32)))
  (import "ast_expression_creators" "create_expr_identifier" (func $create_expr_identifier (param i32 i32) (result i32)))

  ;; Import node type constants
  (import "ast_node_types" "TYPE_PRIMITIVE" (global $TYPE_PRIMITIVE i32))
  (import "ast_node_types" "DECL_FUNCTION" (global $DECL_FUNCTION i32))
  (import "ast_node_types" "EXPR_IDENTIFIER" (global $EXPR_IDENTIFIER i32))

  ;; Test utilities
  (global $TEST_FAILED i32 (i32.const 0))
  (global $TEST_PASSED i32 (i32.const 1))
  (global $test_count (mut i32) (i32.const 0))
  (global $pass_count (mut i32) (i32.const 0))

  ;; Assert functions
  (func $assert_eq (param $actual i32) (param $expected i32) (result i32)
    (if (result i32) (i32.eq (local.get $actual) (local.get $expected))
      (then
        (global.set $pass_count (i32.add (global.get $pass_count) (i32.const 1)))
        (global.get $TEST_PASSED))
      (else
        (global.get $TEST_FAILED))))

  (func $assert_ne (param $actual i32) (param $expected i32) (result i32)
    (if (result i32) (i32.ne (local.get $actual) (local.get $expected))
      (then
        (global.set $pass_count (i32.add (global.get $pass_count) (i32.const 1)))
        (global.get $TEST_PASSED))
      (else
        (global.get $TEST_FAILED))))

  ;; Memory management tests
  (func $test_memory_allocation
    (local $node1 i32)
    (local $node2 i32)
    (global.set $test_count (i32.add (global.get $test_count) (i32.const 1)))

    ;; Initialize memory manager
    (call $init_memory_manager)

    ;; Allocate two nodes
    (local.set $node1 (call $create_node (i32.const 1) (i32.const 32)))
    (local.set $node2 (call $create_node (i32.const 2) (i32.const 32)))

    ;; Test that allocations succeeded
    (drop (call $assert_ne (local.get $node1) (i32.const 0)))
    (drop (call $assert_ne (local.get $node2) (i32.const 0)))

    ;; Test that allocations are different
    (drop (call $assert_ne (local.get $node1) (local.get $node2)))

    ;; Free nodes
    (call $free (local.get $node1))
    (call $free (local.get $node2)))

  ;; Node type tests
  (func $test_node_types
    (local $node i32)
    (global.set $test_count (i32.add (global.get $test_count) (i32.const 1)))

    ;; Initialize memory manager
    (call $init_memory_manager)

    ;; Create primitive type node
    (local.set $node (call $create_type_primitive (i32.const 42)))

    ;; Test node creation and type
    (drop (call $assert_ne (local.get $node) (i32.const 0)))
    (drop (call $assert_eq
      (call $get_node_type (local.get $node))
      (global.get $TYPE_PRIMITIVE)))

    ;; Free node
    (call $free (local.get $node)))

  ;; Node relationship tests
  (func $test_node_relationships
    (local $parent i32)
    (local $child1 i32)
    (local $child2 i32)
    (global.set $test_count (i32.add (global.get $test_count) (i32.const 1)))

    ;; Initialize memory manager
    (call $init_memory_manager)

    ;; Create nodes
    (local.set $parent (call $create_node (i32.const 1) (i32.const 32)))
    (local.set $child1 (call $create_node (i32.const 2) (i32.const 32)))
    (local.set $child2 (call $create_node (i32.const 3) (i32.const 32)))

    ;; Test adding children
    (drop (call $assert_eq
      (call $add_child (local.get $parent) (local.get $child1))
      (i32.const 1)))
    (drop (call $assert_eq
      (call $add_child (local.get $parent) (local.get $child2))
      (i32.const 1)))

    ;; Free nodes (parent node deletion should handle children)
    (call $free (local.get $child2))
    (call $free (local.get $child1))
    (call $free (local.get $parent)))

  ;; String handling tests
  (func $test_string_handling
    (local $node i32)
    (local $str_ptr i32)
    (global.set $test_count (i32.add (global.get $test_count) (i32.const 1)))

    ;; Initialize memory manager
    (call $init_memory_manager)

    ;; Create test string in memory
    (local.set $str_ptr (i32.const 1000))  ;; Arbitrary location
    (i32.store8 (local.get $str_ptr) (i32.const 104))  ;; 'h'
    (i32.store8 (i32.add (local.get $str_ptr) (i32.const 1)) (i32.const 105))  ;; 'i'

    ;; Create function declaration with name
    (local.set $node
      (call $create_decl_function
        (local.get $str_ptr)
        (i32.const 2)))  ;; Length of "hi"

    ;; Test node creation and type
    (drop (call $assert_ne (local.get $node) (i32.const 0)))
    (drop (call $assert_eq
      (call $get_node_type (local.get $node))
      (global.get $DECL_FUNCTION)))

    ;; Test string length storage
    (drop (call $assert_eq
      (i32.load offset=16 (local.get $node))  ;; Length field
      (i32.const 2)))

    ;; Free node
    (call $free (local.get $node)))

  ;; Export test functions
  (export "test_memory_allocation" (func $test_memory_allocation))
  (export "test_node_types" (func $test_node_types))
  (export "test_node_relationships" (func $test_node_relationships))
  (export "test_string_handling" (func $test_string_handling))

  ;; Export test metrics
  (export "test_count" (global $test_count))
  (export "pass_count" (global $pass_count)))
