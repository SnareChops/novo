;; AST Node Creators Test
;; Tests AST node creation functions that aren't covered by other tests

(module $ast_node_creators_test
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import AST functions
  (import "ast_memory" "init_memory_manager" (func $init_memory_manager))
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "ast_node_core" "get_child_count" (func $get_child_count (param i32) (result i32)))
  (import "ast_node_core" "get_child" (func $get_child (param i32) (param i32) (result i32)))

  ;; Import node creators to test
  (import "ast_expression_creators" "create_expr_integer_literal" (func $create_expr_integer_literal (param i64) (result i32)))
  (import "ast_expression_creators" "create_expr_bool_literal" (func $create_expr_bool_literal (param i32) (result i32)))
  (import "ast_expression_creators" "create_expr_string_literal" (func $create_expr_string_literal (param i32) (param i32) (result i32)))
  (import "ast_expression_creators" "create_expr_add" (func $create_expr_add (param i32) (param i32) (result i32)))
  (import "ast_expression_creators" "create_expr_sub" (func $create_expr_sub (param i32) (param i32) (result i32)))
  (import "ast_expression_creators" "create_expr_mul" (func $create_expr_mul (param i32) (param i32) (result i32)))
  (import "ast_expression_creators" "create_expr_div" (func $create_expr_div (param i32) (param i32) (result i32)))
  (import "ast_expression_creators" "create_expr_mod" (func $create_expr_mod (param i32) (param i32) (result i32)))
  (import "ast_type_creators" "create_type_list" (func $create_type_list (param i32) (result i32)))
  (import "ast_type_creators" "create_type_option" (func $create_type_option (param i32) (result i32)))
  (import "ast_type_creators" "create_type_result" (func $create_type_result (param i32) (param i32) (result i32)))
  (import "ast_control_flow_creators" "create_ctrl_break" (func $create_ctrl_break (result i32)))
  (import "ast_control_flow_creators" "create_ctrl_continue" (func $create_ctrl_continue (result i32)))

  ;; Import node type constants
  (import "ast_node_types" "EXPR_INTEGER_LITERAL" (global $EXPR_INTEGER_LITERAL i32))
  (import "ast_node_types" "EXPR_BOOL_LITERAL" (global $EXPR_BOOL_LITERAL i32))
  (import "ast_node_types" "EXPR_STRING_LITERAL" (global $EXPR_STRING_LITERAL i32))
  (import "ast_node_types" "EXPR_ADD" (global $EXPR_ADD i32))
  (import "ast_node_types" "EXPR_SUB" (global $EXPR_SUB i32))
  (import "ast_node_types" "EXPR_MUL" (global $EXPR_MUL i32))
  (import "ast_node_types" "EXPR_DIV" (global $EXPR_DIV i32))
  (import "ast_node_types" "EXPR_MOD" (global $EXPR_MOD i32))
  (import "ast_node_types" "TYPE_LIST" (global $TYPE_LIST i32))
  (import "ast_node_types" "TYPE_OPTION" (global $TYPE_OPTION i32))
  (import "ast_node_types" "TYPE_RESULT" (global $TYPE_RESULT i32))
  (import "ast_node_types" "CTRL_BREAK" (global $CTRL_BREAK i32))
  (import "ast_node_types" "CTRL_CONTINUE" (global $CTRL_CONTINUE i32))

  ;; Test data for string literals
  (data (i32.const 1500) "hello world")  ;; 11 characters

  ;; Test create_expr_integer_literal
  (func $test_create_expr_integer_literal (export "test_create_expr_integer_literal") (result i32)
    (local $node i32)
    (local $node_type i32)

    ;; Initialize AST system
    (call $init_memory_manager)

    ;; Create integer literal node with value 42
    (local.set $node (call $create_expr_integer_literal (i64.const 42)))

    ;; Check that node was created
    (if (i32.eqz (local.get $node))
      (then (return (i32.const 0)))
    )

    ;; Check node type
    (local.set $node_type (call $get_node_type (local.get $node)))
    (if (i32.ne (local.get $node_type) (global.get $EXPR_INTEGER_LITERAL))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test create_expr_bool_literal
  (func $test_create_expr_bool_literal (export "test_create_expr_bool_literal") (result i32)
    (local $node_true i32)
    (local $node_false i32)
    (local $node_type i32)

    ;; Initialize AST system
    (call $init_memory_manager)

    ;; Create boolean literal nodes
    (local.set $node_true (call $create_expr_bool_literal (i32.const 1)))
    (local.set $node_false (call $create_expr_bool_literal (i32.const 0)))

    ;; Check that nodes were created
    (if (i32.eqz (local.get $node_true))
      (then (return (i32.const 0)))
    )
    (if (i32.eqz (local.get $node_false))
      (then (return (i32.const 0)))
    )

    ;; Check node types
    (local.set $node_type (call $get_node_type (local.get $node_true)))
    (if (i32.ne (local.get $node_type) (global.get $EXPR_BOOL_LITERAL))
      (then (return (i32.const 0)))
    )

    (local.set $node_type (call $get_node_type (local.get $node_false)))
    (if (i32.ne (local.get $node_type) (global.get $EXPR_BOOL_LITERAL))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test create_expr_string_literal
  (func $test_create_expr_string_literal (export "test_create_expr_string_literal") (result i32)
    (local $node i32)
    (local $node_type i32)

    ;; Initialize AST system
    (call $init_memory_manager)

    ;; Create string literal node
    (local.set $node (call $create_expr_string_literal (i32.const 1500) (i32.const 11)))

    ;; Check that node was created
    (if (i32.eqz (local.get $node))
      (then (return (i32.const 0)))
    )

    ;; Check node type
    (local.set $node_type (call $get_node_type (local.get $node)))
    (if (i32.ne (local.get $node_type) (global.get $EXPR_STRING_LITERAL))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test binary expression creators (add, sub, mul, div, mod)
  (func $test_create_binary_expressions (export "test_create_binary_expressions") (result i32)
    (local $left_node i32)
    (local $right_node i32)
    (local $add_node i32)
    (local $sub_node i32)
    (local $mul_node i32)
    (local $div_node i32)
    (local $mod_node i32)
    (local $node_type i32)
    (local $child_count i32)

    ;; Initialize AST system
    (call $init_memory_manager)

    ;; Create operand nodes
    (local.set $left_node (call $create_expr_integer_literal (i64.const 10)))
    (local.set $right_node (call $create_expr_integer_literal (i64.const 5)))

    ;; Check operands were created
    (if (i32.eqz (local.get $left_node))
      (then (return (i32.const 0)))
    )
    (if (i32.eqz (local.get $right_node))
      (then (return (i32.const 0)))
    )

    ;; Test create_expr_add
    (local.set $add_node (call $create_expr_add (local.get $left_node) (local.get $right_node)))
    (if (i32.eqz (local.get $add_node))
      (then (return (i32.const 0)))
    )
    (local.set $node_type (call $get_node_type (local.get $add_node)))
    (if (i32.ne (local.get $node_type) (global.get $EXPR_ADD))
      (then (return (i32.const 0)))
    )

    ;; Check that add node has 2 children
    (local.set $child_count (call $get_child_count (local.get $add_node)))
    (if (i32.ne (local.get $child_count) (i32.const 2))
      (then (return (i32.const 0)))
    )

    ;; Create fresh operands for other operations
    (local.set $left_node (call $create_expr_integer_literal (i64.const 20)))
    (local.set $right_node (call $create_expr_integer_literal (i64.const 8)))

    ;; Test create_expr_sub
    (local.set $sub_node (call $create_expr_sub (local.get $left_node) (local.get $right_node)))
    (if (i32.eqz (local.get $sub_node))
      (then (return (i32.const 0)))
    )
    (local.set $node_type (call $get_node_type (local.get $sub_node)))
    (if (i32.ne (local.get $node_type) (global.get $EXPR_SUB))
      (then (return (i32.const 0)))
    )

    ;; Create fresh operands
    (local.set $left_node (call $create_expr_integer_literal (i64.const 6)))
    (local.set $right_node (call $create_expr_integer_literal (i64.const 3)))

    ;; Test create_expr_mul
    (local.set $mul_node (call $create_expr_mul (local.get $left_node) (local.get $right_node)))
    (if (i32.eqz (local.get $mul_node))
      (then (return (i32.const 0)))
    )
    (local.set $node_type (call $get_node_type (local.get $mul_node)))
    (if (i32.ne (local.get $node_type) (global.get $EXPR_MUL))
      (then (return (i32.const 0)))
    )

    ;; Create fresh operands
    (local.set $left_node (call $create_expr_integer_literal (i64.const 15)))
    (local.set $right_node (call $create_expr_integer_literal (i64.const 3)))

    ;; Test create_expr_div
    (local.set $div_node (call $create_expr_div (local.get $left_node) (local.get $right_node)))
    (if (i32.eqz (local.get $div_node))
      (then (return (i32.const 0)))
    )
    (local.set $node_type (call $get_node_type (local.get $div_node)))
    (if (i32.ne (local.get $node_type) (global.get $EXPR_DIV))
      (then (return (i32.const 0)))
    )

    ;; Create fresh operands
    (local.set $left_node (call $create_expr_integer_literal (i64.const 17)))
    (local.set $right_node (call $create_expr_integer_literal (i64.const 5)))

    ;; Test create_expr_mod
    (local.set $mod_node (call $create_expr_mod (local.get $left_node) (local.get $right_node)))
    (if (i32.eqz (local.get $mod_node))
      (then (return (i32.const 0)))
    )
    (local.set $node_type (call $get_node_type (local.get $mod_node)))
    (if (i32.ne (local.get $node_type) (global.get $EXPR_MOD))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test type node creators
  (func $test_create_type_nodes (export "test_create_type_nodes") (result i32)
    (local $element_type i32)
    (local $list_node i32)
    (local $option_node i32)
    (local $result_node i32)
    (local $node_type i32)

    ;; Initialize AST system
    (call $init_memory_manager)

    ;; Create an element type node first
    (local.set $element_type (call $create_expr_integer_literal (i64.const 1)))
    (if (i32.eqz (local.get $element_type))
      (then (return (i32.const 0)))
    )

    ;; Test create_type_list
    (local.set $list_node (call $create_type_list (local.get $element_type)))
    (if (i32.eqz (local.get $list_node))
      (then (return (i32.const 0)))
    )
    (local.set $node_type (call $get_node_type (local.get $list_node)))
    (if (i32.ne (local.get $node_type) (global.get $TYPE_LIST))
      (then (return (i32.const 0)))
    )

    ;; Test create_type_option
    (local.set $option_node (call $create_type_option (local.get $element_type)))
    (if (i32.eqz (local.get $option_node))
      (then (return (i32.const 0)))
    )
    (local.set $node_type (call $get_node_type (local.get $option_node)))
    (if (i32.ne (local.get $node_type) (global.get $TYPE_OPTION))
      (then (return (i32.const 0)))
    )

    ;; Test create_type_result
    (local.set $result_node (call $create_type_result (local.get $element_type) (local.get $element_type)))
    (if (i32.eqz (local.get $result_node))
      (then (return (i32.const 0)))
    )
    (local.set $node_type (call $get_node_type (local.get $result_node)))
    (if (i32.ne (local.get $node_type) (global.get $TYPE_RESULT))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test control flow node creators
  (func $test_create_control_flow_nodes (export "test_create_control_flow_nodes") (result i32)
    (local $break_node i32)
    (local $continue_node i32)
    (local $node_type i32)

    ;; Initialize AST system
    (call $init_memory_manager)

    ;; Test create_ctrl_break
    (local.set $break_node (call $create_ctrl_break))
    (if (i32.eqz (local.get $break_node))
      (then (return (i32.const 0)))
    )
    (local.set $node_type (call $get_node_type (local.get $break_node)))
    (if (i32.ne (local.get $node_type) (global.get $CTRL_BREAK))
      (then (return (i32.const 0)))
    )

    ;; Test create_ctrl_continue
    (local.set $continue_node (call $create_ctrl_continue))
    (if (i32.eqz (local.get $continue_node))
      (then (return (i32.const 0)))
    )
    (local.set $node_type (call $get_node_type (local.get $continue_node)))
    (if (i32.ne (local.get $node_type) (global.get $CTRL_CONTINUE))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Run all tests
  (func $run_tests (export "run_tests") (result i32)
    (local $result i32)

    ;; Test 1: create_expr_integer_literal
    (local.set $result (call $test_create_expr_integer_literal))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 2: create_expr_bool_literal
    (local.set $result (call $test_create_expr_bool_literal))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 3: create_expr_string_literal
    (local.set $result (call $test_create_expr_string_literal))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 4: binary expressions
    (local.set $result (call $test_create_binary_expressions))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 5: type nodes
    (local.set $result (call $test_create_type_nodes))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 6: control flow nodes
    (local.set $result (call $test_create_control_flow_nodes))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; All tests passed
    (i32.const 1)
  )
)
