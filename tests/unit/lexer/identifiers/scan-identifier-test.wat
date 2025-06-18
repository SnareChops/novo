;; Lexer Identifiers Test
;; Tests the scan_identifier function with various identifier patterns

(module $lexer_identifiers_test
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import function to test
  (import "lexer_identifiers" "scan_identifier" (func $scan_identifier (param i32) (result i32 i32)))

  ;; Import character utility functions
  (import "char_utils" "is_letter" (func $is_letter (param i32) (result i32)))
  (import "char_utils" "is_digit" (func $is_digit (param i32) (result i32)))
  (import "char_utils" "is_kebab_char" (func $is_kebab_char (param i32) (result i32)))

  ;; Test data: various identifier patterns
  (data (i32.const 1000) "hello")         ;; simple identifier
  (data (i32.const 1010) "hello-world")   ;; kebab-case identifier
  (data (i32.const 1025) "test123")       ;; identifier with numbers
  (data (i32.const 1035) "a")             ;; single character
  (data (i32.const 1040) "MyVariable")    ;; mixed case
  (data (i32.const 1055) "func-name-2")   ;; complex kebab-case
  (data (i32.const 1070) "_internal")     ;; starting with underscore
  (data (i32.const 1085) "x42y")          ;; mixed letters and digits
  (data (i32.const 1095) "kebab-case-var") ;; longer kebab-case

  ;; Test scan_identifier with simple identifier
  (func $test_scan_identifier_simple (export "test_scan_identifier_simple") (result i32)
    (local $end_pos i32)
    (local $token_idx i32)

    ;; Scan "hello" starting at position 1000
    (call $scan_identifier (i32.const 1000))
    (local.set $token_idx)  ;; second return value (token index)
    (local.set $end_pos)    ;; first return value (end position)

    ;; Should return position 1005 (after 5 characters)
    (if (i32.ne (local.get $end_pos) (i32.const 1005))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test scan_identifier with kebab-case identifier
  (func $test_scan_identifier_kebab_case (export "test_scan_identifier_kebab_case") (result i32)
    (local $end_pos i32)
    (local $token_idx i32)

    ;; Scan "hello-world" starting at position 1010
    (call $scan_identifier (i32.const 1010))
    (local.set $token_idx)  ;; second return value (token index)
    (local.set $end_pos)    ;; first return value (end position)

    ;; Should return position 1021 (after 11 characters)
    (if (i32.ne (local.get $end_pos) (i32.const 1021))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test scan_identifier with identifier containing numbers
  (func $test_scan_identifier_with_numbers (export "test_scan_identifier_with_numbers") (result i32)
    (local $end_pos i32)
    (local $token_idx i32)

    ;; Scan "test123" starting at position 1025
    (call $scan_identifier (i32.const 1025))
    (local.set $token_idx)  ;; second return value (token index)
    (local.set $end_pos)    ;; first return value (end position)

    ;; Should return position 1032 (after 7 characters)
    (if (i32.ne (local.get $end_pos) (i32.const 1032))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test scan_identifier with single character
  (func $test_scan_identifier_single_char (export "test_scan_identifier_single_char") (result i32)
    (local $end_pos i32)
    (local $token_idx i32)

    ;; Scan "a" starting at position 1035
    (call $scan_identifier (i32.const 1035))
    (local.set $token_idx)  ;; second return value (token index)
    (local.set $end_pos)    ;; first return value (end position)

    ;; Should return position 1036 (after 1 character)
    (if (i32.ne (local.get $end_pos) (i32.const 1036))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test scan_identifier with mixed case
  (func $test_scan_identifier_mixed_case (export "test_scan_identifier_mixed_case") (result i32)
    (local $end_pos i32)
    (local $token_idx i32)

    ;; Scan "MyVariable" starting at position 1040
    (call $scan_identifier (i32.const 1040))
    (local.set $token_idx)  ;; second return value (token index)
    (local.set $end_pos)    ;; first return value (end position)

    ;; Should return position 1050 (after 10 characters)
    (if (i32.ne (local.get $end_pos) (i32.const 1050))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test scan_identifier with complex kebab-case
  (func $test_scan_identifier_complex_kebab (export "test_scan_identifier_complex_kebab") (result i32)
    (local $end_pos i32)
    (local $token_idx i32)

    ;; Scan "func-name-2" starting at position 1055
    (call $scan_identifier (i32.const 1055))
    (local.set $token_idx)  ;; second return value (token index)
    (local.set $end_pos)    ;; first return value (end position)

    ;; Should return position 1066 (after 11 characters)
    (if (i32.ne (local.get $end_pos) (i32.const 1066))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test scan_identifier with mixed letters and digits
  (func $test_scan_identifier_mixed_letters_digits (export "test_scan_identifier_mixed_letters_digits") (result i32)
    (local $end_pos i32)
    (local $token_idx i32)

    ;; Scan "x42y" starting at position 1085
    (call $scan_identifier (i32.const 1085))
    (local.set $token_idx)  ;; second return value (token index)
    (local.set $end_pos)    ;; first return value (end position)

    ;; Should return position 1089 (after 4 characters)
    (if (i32.ne (local.get $end_pos) (i32.const 1089))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test scan_identifier with longer kebab-case
  (func $test_scan_identifier_longer_kebab (export "test_scan_identifier_longer_kebab") (result i32)
    (local $end_pos i32)
    (local $token_idx i32)

    ;; Scan "kebab-case-var" starting at position 1095
    (call $scan_identifier (i32.const 1095))
    (local.set $token_idx)  ;; second return value (token index)
    (local.set $end_pos)    ;; first return value (end position)

    ;; Should return position 1109 (after 14 characters)
    (if (i32.ne (local.get $end_pos) (i32.const 1109))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test scan_identifier boundary conditions
  (func $test_scan_identifier_boundary (export "test_scan_identifier_boundary") (result i32)
    (local $end_pos i32)
    (local $token_idx i32)

    ;; Test scanning when reaching null terminator
    ;; Place a null terminator after "hello" for boundary testing
    (i32.store8 (i32.const 1005) (i32.const 0))

    ;; Scan "hello" starting at position 1000
    (call $scan_identifier (i32.const 1000))
    (local.set $token_idx)  ;; second return value (token index)
    (local.set $end_pos)    ;; first return value (end position)

    ;; Should stop at position 1005 (at null terminator)
    (if (i32.ne (local.get $end_pos) (i32.const 1005))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test that identifier scanning handles position tracking correctly
  (func $test_scan_identifier_position_tracking (export "test_scan_identifier_position_tracking") (result i32)
    (local $start_pos i32)
    (local $end_pos i32)
    (local $token_idx i32)
    (local $expected_length i32)

    ;; Test with "hello-world" which should be 11 characters
    (local.set $start_pos (i32.const 1010))
    (call $scan_identifier (local.get $start_pos))
    (local.set $token_idx)  ;; second return value (token index)
    (local.set $end_pos)    ;; first return value (end position)
    (local.set $expected_length (i32.const 11))

    ;; Check that the length is correct
    (if (i32.ne
          (i32.sub (local.get $end_pos) (local.get $start_pos))
          (local.get $expected_length))
      (then (return (i32.const 0)))
    )

    ;; Test with "test123" which should be 7 characters
    (local.set $start_pos (i32.const 1025))
    (call $scan_identifier (local.get $start_pos))
    (local.set $token_idx)  ;; second return value (token index)
    (local.set $end_pos)    ;; first return value (end position)
    (local.set $expected_length (i32.const 7))

    ;; Check that the length is correct
    (if (i32.ne
          (i32.sub (local.get $end_pos) (local.get $start_pos))
          (local.get $expected_length))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Run all tests
  (func $run_tests (export "run_tests") (result i32)
    (local $result i32)

    ;; Test 1: simple identifier
    (local.set $result (call $test_scan_identifier_simple))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 2: kebab-case identifier
    (local.set $result (call $test_scan_identifier_kebab_case))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 3: identifier with numbers
    (local.set $result (call $test_scan_identifier_with_numbers))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 4: single character
    (local.set $result (call $test_scan_identifier_single_char))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 5: mixed case
    (local.set $result (call $test_scan_identifier_mixed_case))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 6: complex kebab-case
    (local.set $result (call $test_scan_identifier_complex_kebab))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 7: mixed letters and digits
    (local.set $result (call $test_scan_identifier_mixed_letters_digits))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 8: longer kebab-case
    (local.set $result (call $test_scan_identifier_longer_kebab))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 9: boundary conditions
    (local.set $result (call $test_scan_identifier_boundary))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 10: position tracking
    (local.set $result (call $test_scan_identifier_position_tracking))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; All tests passed
    (i32.const 1)
  )
)
