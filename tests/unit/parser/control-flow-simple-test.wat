;; Simple Control Flow Parser Tests
;; Basic tests for break, continue, and return statements

(module $control_flow_simple_test
  ;; Import necessary modules
  (import "lexer_memory" "memory" (memory 1))
  (import "parser_control_flow" "parse_break_statement" (func $parse_break_statement (param i32) (result i32 i32)))
  (import "parser_control_flow" "parse_continue_statement" (func $parse_continue_statement (param i32) (result i32 i32)))
  (import "parser_control_flow" "parse_return_statement" (func $parse_return_statement (param i32) (result i32 i32)))
  (import "parser_control_flow" "parse_control_flow" (func $parse_control_flow (param i32) (result i32 i32)))

  ;; Import AST node types for validation
  (import "ast_node_types" "CTRL_RETURN" (global $CTRL_RETURN i32))
  (import "ast_node_types" "CTRL_BREAK" (global $CTRL_BREAK i32))
  (import "ast_node_types" "CTRL_CONTINUE" (global $CTRL_CONTINUE i32))

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

  ;; Test data: simple statements
  (data (i32.const 1000) "return")
  (data (i32.const 1010) "break")
  (data (i32.const 1020) "continue")

  ;; Test return statement
  (func $test_return_statement (result i32)
    (local $ast_node i32)
    (local $next_pos i32)
    (local $node_type i32)

    ;; Set up test input in memory
    (call $store_test_input (i32.const 1000) (i32.const 6)) ;; "return"

    ;; Parse return statement
    (call $parse_return_statement (i32.const 0))
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
    (if (i32.ne (local.get $node_type) (global.get $CTRL_RETURN))
      (then
        (return (i32.const 0)) ;; Test failed
      )
    )

    ;; Test passed
    (return (i32.const 1))
  )

  ;; Test break statement
  (func $test_break_statement (result i32)
    (local $ast_node i32)
    (local $next_pos i32)
    (local $node_type i32)

    ;; Set up test input in memory
    (call $store_test_input (i32.const 1010) (i32.const 5)) ;; "break"

    ;; Parse break statement
    (call $parse_break_statement (i32.const 0))
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
    (if (i32.ne (local.get $node_type) (global.get $CTRL_BREAK))
      (then
        (return (i32.const 0)) ;; Test failed
      )
    )

    ;; Test passed
    (return (i32.const 1))
  )

  ;; Test continue statement
  (func $test_continue_statement (result i32)
    (local $ast_node i32)
    (local $next_pos i32)
    (local $node_type i32)

    ;; Set up test input in memory
    (call $store_test_input (i32.const 1020) (i32.const 8)) ;; "continue"

    ;; Parse continue statement
    (call $parse_continue_statement (i32.const 0))
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
    (if (i32.ne (local.get $node_type) (global.get $CTRL_CONTINUE))
      (then
        (return (i32.const 0)) ;; Test failed
      )
    )

    ;; Test passed
    (return (i32.const 1))
  )

  ;; Run all tests
  (func $run_tests (export "run_tests") (result i32)
    (local $result i32)

    ;; Test 1: Return statement
    (local.set $result (call $test_return_statement))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 2: Break statement
    (local.set $result (call $test_break_statement))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 3: Continue statement
    (local.set $result (call $test_continue_statement))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; All tests passed
    (return (i32.const 1))
  )
)
