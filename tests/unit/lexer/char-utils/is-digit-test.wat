;; Test is_digit function directly
(module $is_digit_test
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import char utils
  (import "char_utils" "is_digit" (func $is_digit (param i32) (result i32)))

  ;; Test function
  (func $test_is_digit (export "_start")
    (local $result i32)

    ;; Test '4' (0x34)
    (local.set $result (call $is_digit (i32.const 0x34)))
    (i32.store (i32.const 100) (local.get $result))  ;; Should be 1

    ;; Test '2' (0x32)
    (local.set $result (call $is_digit (i32.const 0x32)))
    (i32.store (i32.const 104) (local.get $result))  ;; Should be 1

    ;; Test 'a' (0x61)
    (local.set $result (call $is_digit (i32.const 0x61)))
    (i32.store (i32.const 108) (local.get $result))  ;; Should be 0

    ;; Store magic number to confirm test ran
    (i32.store (i32.const 112) (i32.const 0xABCDEF))
  )
)
