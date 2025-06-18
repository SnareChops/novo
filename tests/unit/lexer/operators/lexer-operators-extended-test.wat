;; Lexer Operators Extended Test
;; Tests lexer operator functions that need additional coverage

(module $lexer_operators_extended_test
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import functions to test
  (import "lexer_operators" "update_space_tracking" (func $update_space_tracking (param i32)))
  (import "lexer_operators" "scan_operator" (func $scan_operator (param i32) (result i32 i32)))

  ;; Import space tracking state
  (import "lexer_operators" "last_char_was_space" (global $last_char_was_space (mut i32)))
  (import "lexer_operators" "space_required" (global $space_required (mut i32)))

  ;; Import char utils
  (import "char_utils" "is_whitespace" (func $is_whitespace (param i32) (result i32)))

  ;; Import token constants
  (import "lexer_tokens" "TOKEN_PLUS" (global $TOKEN_PLUS i32))
  (import "lexer_tokens" "TOKEN_MINUS" (global $TOKEN_MINUS i32))
  (import "lexer_tokens" "TOKEN_MULTIPLY" (global $TOKEN_MULTIPLY i32))
  (import "lexer_tokens" "TOKEN_DIVIDE" (global $TOKEN_DIVIDE i32))
  (import "lexer_tokens" "TOKEN_MODULO" (global $TOKEN_MODULO i32))

  ;; Test data: various operator characters
  (data (i32.const 1000) "+")     ;; plus
  (data (i32.const 1001) "-")     ;; minus
  (data (i32.const 1002) "*")     ;; multiply
  (data (i32.const 1003) "/")     ;; divide
  (data (i32.const 1004) "%")     ;; modulo
  (data (i32.const 1005) " ")     ;; space
  (data (i32.const 1006) "\t")    ;; tab
  (data (i32.const 1007) "\n")    ;; newline
  (data (i32.const 1008) "a")     ;; letter

  ;; Test update_space_tracking with whitespace characters
  (func $test_update_space_tracking_whitespace (export "test_update_space_tracking_whitespace") (result i32)
    ;; Reset state
    (global.set $last_char_was_space (i32.const 0))

    ;; Test with space character
    (call $update_space_tracking (i32.const 0x20))  ;; space
    (if (i32.eqz (global.get $last_char_was_space))
      (then (return (i32.const 0)))
    )

    ;; Test with tab character
    (call $update_space_tracking (i32.const 0x09))  ;; tab
    (if (i32.eqz (global.get $last_char_was_space))
      (then (return (i32.const 0)))
    )

    ;; Test with newline character
    (call $update_space_tracking (i32.const 0x0A))  ;; newline
    (if (i32.eqz (global.get $last_char_was_space))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test update_space_tracking with non-whitespace characters
  (func $test_update_space_tracking_non_whitespace (export "test_update_space_tracking_non_whitespace") (result i32)
    ;; Reset state to whitespace
    (global.set $last_char_was_space (i32.const 1))

    ;; Test with letter character
    (call $update_space_tracking (i32.const 0x61))  ;; 'a'
    (if (i32.ne (global.get $last_char_was_space) (i32.const 0))
      (then (return (i32.const 0)))
    )

    ;; Test with digit character
    (call $update_space_tracking (i32.const 0x35))  ;; '5'
    (if (i32.ne (global.get $last_char_was_space) (i32.const 0))
      (then (return (i32.const 0)))
    )

    ;; Test with operator character
    (call $update_space_tracking (i32.const 0x2B))  ;; '+'
    (if (i32.ne (global.get $last_char_was_space) (i32.const 0))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test scan_operator with plus operator
  (func $test_scan_operator_plus (export "test_scan_operator_plus") (result i32)
    (local $token_type i32)
    (local $next_pos i32)

    ;; Set up plus character in memory at position 1000
    ;; scan_operator expects the character to be at the given position
    (call $scan_operator (i32.const 1000))
    (local.set $next_pos)    ;; second return value (next position)
    (local.set $token_type)  ;; first return value (token type)

    ;; Check that token type is correct
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_PLUS))
      (then (return (i32.const 0)))
    )

    ;; Check that position advanced by 1
    (if (i32.ne (local.get $next_pos) (i32.const 1001))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test scan_operator with minus operator
  (func $test_scan_operator_minus (export "test_scan_operator_minus") (result i32)
    (local $token_type i32)
    (local $next_pos i32)

    ;; Set up minus character in memory at position 1001
    (call $scan_operator (i32.const 1001))
    (local.set $next_pos)    ;; second return value
    (local.set $token_type)  ;; first return value

    ;; Check that token type is correct
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_MINUS))
      (then (return (i32.const 0)))
    )

    ;; Check that position advanced by 1
    (if (i32.ne (local.get $next_pos) (i32.const 1002))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test scan_operator with multiply operator
  (func $test_scan_operator_multiply (export "test_scan_operator_multiply") (result i32)
    (local $token_type i32)
    (local $next_pos i32)

    ;; Set up multiply character in memory at position 1002
    (call $scan_operator (i32.const 1002))
    (local.set $next_pos)    ;; second return value
    (local.set $token_type)  ;; first return value

    ;; Check that token type is correct
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_MULTIPLY))
      (then (return (i32.const 0)))
    )

    ;; Check that position advanced by 1
    (if (i32.ne (local.get $next_pos) (i32.const 1003))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test scan_operator with divide operator
  (func $test_scan_operator_divide (export "test_scan_operator_divide") (result i32)
    (local $token_type i32)
    (local $next_pos i32)

    ;; Set up divide character in memory at position 1003
    (call $scan_operator (i32.const 1003))
    (local.set $next_pos)    ;; second return value
    (local.set $token_type)  ;; first return value

    ;; Check that token type is correct
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_DIVIDE))
      (then (return (i32.const 0)))
    )

    ;; Check that position advanced by 1
    (if (i32.ne (local.get $next_pos) (i32.const 1004))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test scan_operator with modulo operator
  (func $test_scan_operator_modulo (export "test_scan_operator_modulo") (result i32)
    (local $token_type i32)
    (local $next_pos i32)

    ;; Set up modulo character in memory at position 1004
    (call $scan_operator (i32.const 1004))
    (local.set $next_pos)    ;; second return value
    (local.set $token_type)  ;; first return value

    ;; Check that token type is correct
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_MODULO))
      (then (return (i32.const 0)))
    )

    ;; Check that position advanced by 1
    (if (i32.ne (local.get $next_pos) (i32.const 1005))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test space tracking state transitions
  (func $test_space_tracking_transitions (export "test_space_tracking_transitions") (result i32)
    ;; Test transition: non-whitespace -> whitespace -> non-whitespace

    ;; Start with non-whitespace
    (global.set $last_char_was_space (i32.const 0))
    (call $update_space_tracking (i32.const 0x61))  ;; 'a'
    (if (i32.ne (global.get $last_char_was_space) (i32.const 0))
      (then (return (i32.const 0)))
    )

    ;; Transition to whitespace
    (call $update_space_tracking (i32.const 0x20))  ;; space
    (if (i32.ne (global.get $last_char_was_space) (i32.const 1))
      (then (return (i32.const 0)))
    )

    ;; Transition back to non-whitespace
    (call $update_space_tracking (i32.const 0x62))  ;; 'b'
    (if (i32.ne (global.get $last_char_was_space) (i32.const 0))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Run all tests
  (func $run_tests (export "run_tests") (result i32)
    (local $result i32)

    ;; Test 1: update_space_tracking with whitespace
    (local.set $result (call $test_update_space_tracking_whitespace))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 2: update_space_tracking with non-whitespace
    (local.set $result (call $test_update_space_tracking_non_whitespace))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 3: scan_operator plus
    (local.set $result (call $test_scan_operator_plus))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 4: scan_operator minus
    (local.set $result (call $test_scan_operator_minus))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 5: scan_operator multiply
    (local.set $result (call $test_scan_operator_multiply))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 6: scan_operator divide
    (local.set $result (call $test_scan_operator_divide))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 7: scan_operator modulo
    (local.set $result (call $test_scan_operator_modulo))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 8: space tracking transitions
    (local.set $result (call $test_space_tracking_transitions))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; All tests passed
    (i32.const 1)
  )
)
