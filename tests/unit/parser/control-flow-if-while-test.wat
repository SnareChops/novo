;; Control Flow If/While Tests
;; Tests for the new if and while statement parsing

(module $control_flow_if_while_test
  ;; Import necessary modules
  (import "lexer_memory" "memory" (memory 1))
  (import "parser_control_flow" "parse_if_statement" (func $parse_if_statement (param i32) (result i32 i32)))
  (import "parser_control_flow" "parse_while_statement" (func $parse_while_statement (param i32) (result i32 i32)))
  (import "parser_control_flow" "parse_control_flow" (func $parse_control_flow (param i32) (result i32 i32)))

  ;; Import AST node types for validation
  (import "ast_node_types" "CTRL_IF" (global $CTRL_IF i32))
  (import "ast_node_types" "CTRL_WHILE" (global $CTRL_WHILE i32))

  ;; Import AST node core functions
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))

  ;; Helper function to store string in memory at position 0
  (func $store_test_input (param $str_ptr i32) (param $str_len i32)
    (local $i i32)

    (local.set $i (i32.const 0))
    (loop $copy_loop
      (if (i32.lt_u (local.get $i) (local.get $str_len))
        (then
          (i32.store8
            (local.get $i)
            (i32.load8_u (i32.add (local.get $str_ptr) (local.get $i))))
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $copy_loop)
        )
      )
    )
  )

  ;; Test if statement parsing
  (func $test_if_statement (result i32)
    (local $ast_node i32)
    (local $next_pos i32)
    (local $node_type i32)

    ;; Set up test input in memory: "if"
    (call $store_test_input (i32.const 2000) (i32.const 2)) ;; "if"

    ;; Parse if statement
    (call $parse_if_statement (i32.const 0))
    (local.set $next_pos) ;; Second return value (position)
    (local.set $ast_node) ;; First return value (AST node)

    ;; Check if parsing succeeded
    (if (i32.eqz (local.get $ast_node))
      (then
        (return (i32.const 0)) ;; Test failed
      )
    )

    ;; Check node type
    (local.set $node_type (call $get_node_type (local.get $ast_node)))
    (if (i32.ne (local.get $node_type) (global.get $CTRL_IF))
      (then
        (return (i32.const 0)) ;; Test failed
      )
    )

    ;; Test passed
    (return (i32.const 1))
  )

  ;; Test while statement parsing
  (func $test_while_statement (result i32)
    (local $ast_node i32)
    (local $next_pos i32)
    (local $node_type i32)

    ;; Set up test input in memory: "while"
    (call $store_test_input (i32.const 3000) (i32.const 5)) ;; "while"

    ;; Parse while statement
    (call $parse_while_statement (i32.const 0))
    (local.set $next_pos) ;; Second return value (position)
    (local.set $ast_node) ;; First return value (AST node)

    ;; Check if parsing succeeded
    (if (i32.eqz (local.get $ast_node))
      (then
        (return (i32.const 0)) ;; Test failed
      )
    )

    ;; Check node type
    (local.set $node_type (call $get_node_type (local.get $ast_node)))
    (if (i32.ne (local.get $node_type) (global.get $CTRL_WHILE))
      (then
        (return (i32.const 0)) ;; Test failed
      )
    )

    ;; Test passed
    (return (i32.const 1))
  )

  ;; Test control flow dispatcher with if/while
  (func $test_control_flow_dispatcher (result i32)
    (local $ast_node i32)
    (local $next_pos i32)
    (local $node_type i32)

    ;; Test 1: Parse if through dispatcher
    (call $store_test_input (i32.const 4000) (i32.const 2)) ;; "if"

    (call $parse_control_flow (i32.const 0))
    (local.set $next_pos) ;; Second return value (position)
    (local.set $ast_node) ;; First return value (AST node)

    (if (i32.eqz (local.get $ast_node))
      (then
        (return (i32.const 0)) ;; Test failed
      )
    )

    (local.set $node_type (call $get_node_type (local.get $ast_node)))
    (if (i32.ne (local.get $node_type) (global.get $CTRL_IF))
      (then
        (return (i32.const 0)) ;; Test failed
      )
    )

    ;; Test 2: Parse while through dispatcher
    (call $store_test_input (i32.const 5000) (i32.const 5)) ;; "while"

    (call $parse_control_flow (i32.const 0))
    (local.set $next_pos) ;; Second return value (position)
    (local.set $ast_node) ;; First return value (AST node)

    (if (i32.eqz (local.get $ast_node))
      (then
        (return (i32.const 0)) ;; Test failed
      )
    )

    (local.set $node_type (call $get_node_type (local.get $ast_node)))
    (if (i32.ne (local.get $node_type) (global.get $CTRL_WHILE))
      (then
        (return (i32.const 0)) ;; Test failed
      )
    )

    ;; All tests passed
    (return (i32.const 1))
  )

  ;; Main test runner
  (func $run_tests (export "run_tests") (result i32)
    (local $total_tests i32)
    (local $passed_tests i32)

    (local.set $total_tests (i32.const 3))
    (local.set $passed_tests (i32.const 0))

    ;; Run if statement test
    (if (call $test_if_statement)
      (then
        (local.set $passed_tests (i32.add (local.get $passed_tests) (i32.const 1)))
      )
    )

    ;; Run while statement test
    (if (call $test_while_statement)
      (then
        (local.set $passed_tests (i32.add (local.get $passed_tests) (i32.const 1)))
      )
    )

    ;; Run control flow dispatcher test
    (if (call $test_control_flow_dispatcher)
      (then
        (local.set $passed_tests (i32.add (local.get $passed_tests) (i32.const 1)))
      )
    )

    ;; Return 1 if all tests passed, 0 otherwise
    (if (i32.eq (local.get $passed_tests) (local.get $total_tests))
      (then (return (i32.const 1)))
    )
    (return (i32.const 0))
  )

  ;; Test data stored in memory
  (data (i32.const 2000) "if")          ;; Position 2000
  (data (i32.const 3000) "while")       ;; Position 3000
  (data (i32.const 4000) "if")          ;; Position 4000
  (data (i32.const 5000) "while")       ;; Position 5000
)
