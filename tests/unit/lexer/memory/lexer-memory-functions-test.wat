;; Lexer Memory Functions Test
;; Tests the lexer memory management functions that aren't directly tested elsewhere

(module $lexer_memory_functions_test
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import functions to test
  (import "lexer_memory" "update_position" (func $update_position (param i32)))
  (import "lexer_memory" "store_identifier" (func $store_identifier (param i32) (param i32) (result i32)))

  ;; Import position globals
  (import "lexer_memory" "current_line" (global $current_line (mut i32)))
  (import "lexer_memory" "current_col" (global $current_col (mut i32)))

  ;; Test data storage area
  (data (i32.const 1000) "hello")      ;; 5 characters
  (data (i32.const 1010) "hello-world") ;; 11 characters
  (data (i32.const 1030) "")          ;; empty string

  ;; Test update_position function with regular character
  (func $test_update_position_regular_char (export "test_update_position_regular_char") (result i32)
    ;; Reset position state
    (global.set $current_line (i32.const 1))
    (global.set $current_col (i32.const 5))

    ;; Update position with regular character (not newline)
    (call $update_position (i32.const 0x41))  ;; 'A'

    ;; Check that column was incremented, line stayed same
    (if (i32.ne (global.get $current_line) (i32.const 1))
      (then (return (i32.const 0)))
    )
    (if (i32.ne (global.get $current_col) (i32.const 6))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test update_position function with newline character
  (func $test_update_position_newline (export "test_update_position_newline") (result i32)
    ;; Reset position state
    (global.set $current_line (i32.const 3))
    (global.set $current_col (i32.const 15))

    ;; Update position with newline character
    (call $update_position (i32.const 0x0A))  ;; '\n'

    ;; Check that line was incremented, column reset to 0
    (if (i32.ne (global.get $current_line) (i32.const 4))
      (then (return (i32.const 0)))
    )
    (if (i32.ne (global.get $current_col) (i32.const 0))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test store_identifier function with normal identifier
  (func $test_store_identifier_normal (export "test_store_identifier_normal") (result i32)
    (local $stored_ptr i32)
    (local $i i32)
    (local $char_match i32)

    ;; Store "hello" identifier (5 characters)
    (local.set $stored_ptr (call $store_identifier (i32.const 1000) (i32.const 5)))

    ;; Check that returned pointer is in valid range (variable data section)
    (if (i32.lt_u (local.get $stored_ptr) (i32.const 32768))
      (then (return (i32.const 0)))
    )

    ;; Verify stored content by checking each character
    (local.set $char_match (i32.const 1))
    (local.set $i (i32.const 0))
    (loop $verify_loop
      (if (i32.lt_u (local.get $i) (i32.const 5))
        (then
          ;; Compare stored character with original
          (if (i32.ne
                (i32.load8_u (i32.add (local.get $stored_ptr) (local.get $i)))
                (i32.load8_u (i32.add (i32.const 1000) (local.get $i))))
            (then (local.set $char_match (i32.const 0)))
          )
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $verify_loop)
        )
      )
    )

    ;; Check that characters matched
    (if (i32.eqz (local.get $char_match))
      (then (return (i32.const 0)))
    )

    ;; Check null terminator was added
    (if (i32.ne (i32.load8_u (i32.add (local.get $stored_ptr) (i32.const 5))) (i32.const 0))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test store_identifier function with longer identifier
  (func $test_store_identifier_long (export "test_store_identifier_long") (result i32)
    (local $stored_ptr i32)
    (local $i i32)
    (local $char_match i32)

    ;; Store "hello-world" identifier (11 characters)
    (local.set $stored_ptr (call $store_identifier (i32.const 1010) (i32.const 11)))

    ;; Check that returned pointer is in valid range
    (if (i32.lt_u (local.get $stored_ptr) (i32.const 32768))
      (then (return (i32.const 0)))
    )

    ;; Verify stored content by checking key characters
    ;; Check first character: 'h'
    (if (i32.ne (i32.load8_u (local.get $stored_ptr)) (i32.const 0x68))
      (then (return (i32.const 0)))
    )

    ;; Check middle character: '-'
    (if (i32.ne (i32.load8_u (i32.add (local.get $stored_ptr) (i32.const 5))) (i32.const 0x2D))
      (then (return (i32.const 0)))
    )

    ;; Check last character: 'd'
    (if (i32.ne (i32.load8_u (i32.add (local.get $stored_ptr) (i32.const 10))) (i32.const 0x64))
      (then (return (i32.const 0)))
    )

    ;; Check null terminator
    (if (i32.ne (i32.load8_u (i32.add (local.get $stored_ptr) (i32.const 11))) (i32.const 0))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test store_identifier function with empty string
  (func $test_store_identifier_empty (export "test_store_identifier_empty") (result i32)
    (local $stored_ptr i32)

    ;; Store empty identifier (0 characters)
    (local.set $stored_ptr (call $store_identifier (i32.const 1030) (i32.const 0)))

    ;; Check that returned pointer is in valid range
    (if (i32.lt_u (local.get $stored_ptr) (i32.const 32768))
      (then (return (i32.const 0)))
    )

    ;; Check that null terminator is immediately at start
    (if (i32.ne (i32.load8_u (local.get $stored_ptr)) (i32.const 0))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Run all tests
  (func $run_tests (export "run_tests") (result i32)
    (local $result i32)

    ;; Test 1: update_position with regular character
    (local.set $result (call $test_update_position_regular_char))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 2: update_position with newline
    (local.set $result (call $test_update_position_newline))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 3: store_identifier with normal string
    (local.set $result (call $test_store_identifier_normal))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 4: store_identifier with long string
    (local.set $result (call $test_store_identifier_long))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 5: store_identifier with empty string
    (local.set $result (call $test_store_identifier_empty))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; All tests passed
    (i32.const 1)
  )
)
