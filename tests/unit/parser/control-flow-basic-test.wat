;; Basic Control Flow Parser Tests
;; Tests for if/else, while, break, continue, and return statements

(module $control_flow_basic_test
  ;; Import necessary modules
  (import "lexer_memory" "memory" (memory 1))
  (import "novo_lexer" "scan_text" (func $scan_text (param i32 i32) (result i32)))
  (import "parser_control_flow" "parse_if_statement" (func $parse_if_statement (param i32) (result i32 i32)))
  (import "parser_control_flow" "parse_while_statement" (func $parse_while_statement (param i32) (result i32 i32)))
  (import "parser_control_flow" "parse_return_statement" (func $parse_return_statement (param i32) (result i32 i32)))
  (import "parser_control_flow" "parse_break_statement" (func $parse_break_statement (param i32) (result i32 i32)))
  (import "parser_control_flow" "parse_continue_statement" (func $parse_continue_statement (param i32) (result i32 i32)))
  (import "parser_control_flow" "parse_control_flow" (func $parse_control_flow (param i32) (result i32 i32)))

  ;; Import AST node types for validation
  (import "ast_node_types" "CTRL_IF" (global $CTRL_IF i32))
  (import "ast_node_types" "CTRL_WHILE" (global $CTRL_WHILE i32))
  (import "ast_node_types" "CTRL_RETURN" (global $CTRL_RETURN i32))
  (import "ast_node_types" "CTRL_BREAK" (global $CTRL_BREAK i32))
  (import "ast_node_types" "CTRL_CONTINUE" (global $CTRL_CONTINUE i32))

  ;; Import AST node core functions
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))

  ;; Memory locations for test strings
  (global $TEST_STRING_AREA i32 (i32.const 8192))

  ;; Test counter
  (global $test_count (mut i32) (i32.const 0))
  (global $test_passed (mut i32) (i32.const 0))

  ;; Helper function to write string to memory
  (func $write_string (param $dest i32) (param $str_offset i32) (param $length i32)
    (local $i i32)
    (local.set $i (i32.const 0))
    (loop $copy_loop
      (if (i32.lt_u (local.get $i) (local.get $length))
        (then
          (i32.store8
            (i32.add (local.get $dest) (local.get $i))
            (i32.load8_u (i32.add (local.get $str_offset) (local.get $i)))
          )
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $copy_loop)
        )
      )
    )
  )

  ;; Helper function to run a test
  (func $run_test (param $test_name_start i32) (param $test_name_len i32) (param $code_start i32) (param $code_len i32) (param $expected_node_type i32) (result i32)
    (local $result i32)
    (local $node_ptr i32)
    (local $next_pos i32)
    (local $actual_node_type i32)

    ;; Increment test counter
    (global.set $test_count (i32.add (global.get $test_count) (i32.const 1)))

    ;; Copy test code to memory
    (call $write_string (global.get $TEST_STRING_AREA) (local.get $code_start) (local.get $code_len))

    ;; Scan the text
    (local.set $result (call $scan_text (global.get $TEST_STRING_AREA) (local.get $code_len)))
    (if (i32.eqz (local.get $result))
      (then
        ;; Scanning failed
        (return (i32.const 0))
      )
    )

    ;; Parse control flow
    (local.set $result (call $parse_control_flow (i32.const 0)))
    (local.set $node_ptr (i32.shr_u (local.get $result) (i32.const 16)))
    (local.set $next_pos (i32.and (local.get $result) (i32.const 0xFFFF)))

    ;; Check if parsing succeeded
    (if (i32.eqz (local.get $node_ptr))
      (then
        ;; Parsing failed
        (return (i32.const 0))
      )
    )

    ;; Validate node type
    (local.set $actual_node_type (call $get_node_type (local.get $node_ptr)))
    (if (i32.eq (local.get $actual_node_type) (local.get $expected_node_type))
      (then
        ;; Test passed
        (global.set $test_passed (i32.add (global.get $test_passed) (i32.const 1)))
        (return (i32.const 1))
      )
      (else
        ;; Test failed
        (return (i32.const 0))
      )
    )
  )

  ;; Test data strings (embedded in the module)
  (data (i32.const 16384) "if (true) { return 42 }")
  (data (i32.const 16408) "while (x > 0) { x = x - 1 }")
  (data (i32.const 16436) "return")
  (data (i32.const 16443) "return 42")
  (data (i32.const 16453) "break")
  (data (i32.const 16459) "continue")
  (data (i32.const 16468) "if (x) { y = 1 } else { y = 2 }")

  ;; Test simple if statement
  (func $test_simple_if (export "test_simple_if") (result i32)
    (call $run_test
      (i32.const 0) (i32.const 0)  ;; Test name (unused)
      (i32.const 16384) (i32.const 24)  ;; "if (true) { return 42 }"
      (global.get $CTRL_IF)  ;; Expected node type
    )
  )

  ;; Test while loop
  (func $test_while_loop (export "test_while_loop") (result i32)
    (call $run_test
      (i32.const 0) (i32.const 0)  ;; Test name (unused)
      (i32.const 16408) (i32.const 28)  ;; "while (x > 0) { x = x - 1 }"
      (global.get $CTRL_WHILE)  ;; Expected node type
    )
  )

  ;; Test return without value
  (func $test_return_no_value (export "test_return_no_value") (result i32)
    (call $run_test
      (i32.const 0) (i32.const 0)  ;; Test name (unused)
      (i32.const 16436) (i32.const 6)  ;; "return"
      (global.get $CTRL_RETURN)  ;; Expected node type
    )
  )

  ;; Test return with value
  (func $test_return_with_value (export "test_return_with_value") (result i32)
    (call $run_test
      (i32.const 0) (i32.const 0)  ;; Test name (unused)
      (i32.const 16443) (i32.const 9)  ;; "return 42"
      (global.get $CTRL_RETURN)  ;; Expected node type
    )
  )

  ;; Test break statement
  (func $test_break_statement (export "test_break_statement") (result i32)
    (call $run_test
      (i32.const 0) (i32.const 0)  ;; Test name (unused)
      (i32.const 16453) (i32.const 5)  ;; "break"
      (global.get $CTRL_BREAK)  ;; Expected node type
    )
  )

  ;; Test continue statement
  (func $test_continue_statement (export "test_continue_statement") (result i32)
    (call $run_test
      (i32.const 0) (i32.const 0)  ;; Test name (unused)
      (i32.const 16459) (i32.const 8)  ;; "continue"
      (global.get $CTRL_CONTINUE)  ;; Expected node type
    )
  )

  ;; Test if-else statement
  (func $test_if_else_statement (export "test_if_else_statement") (result i32)
    (call $run_test
      (i32.const 0) (i32.const 0)  ;; Test name (unused)
      (i32.const 16468) (i32.const 31)  ;; "if (x) { y = 1 } else { y = 2 }"
      (global.get $CTRL_IF)  ;; Expected node type
    )
  )

  ;; Main test runner
  (func $run_all_tests (export "run_all_tests") (result i32)
    (local $result i32)

    ;; Reset counters
    (global.set $test_count (i32.const 0))
    (global.set $test_passed (i32.const 0))

    ;; Run all tests
    (local.set $result (call $test_simple_if))
    (local.set $result (call $test_while_loop))
    (local.set $result (call $test_return_no_value))
    (local.set $result (call $test_return_with_value))
    (local.set $result (call $test_break_statement))
    (local.set $result (call $test_continue_statement))
    (local.set $result (call $test_if_else_statement))

    ;; Return 1 if all tests passed, 0 otherwise
    (i32.eq (global.get $test_count) (global.get $test_passed))
  )

  ;; Get test results
  (func $get_test_count (export "get_test_count") (result i32)
    (global.get $test_count)
  )

  (func $get_test_passed (export "get_test_passed") (result i32)
    (global.get $test_passed)
  )
)
