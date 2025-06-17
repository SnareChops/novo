;; Test uppercase word specifically
(module $is_valid_word_uppercase_test
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import is_valid_word
  (import "char_utils" "is_valid_word" (func $is_valid_word (param i32 i32) (result i32)))

  ;; Test function
  (func $test_is_valid_word_uppercase (export "_start")
    (local $result i32)

    ;; Test valid all uppercase: "HELLO"
    (i32.store8 (i32.const 60) (i32.const 72))  ;; 'H'
    (i32.store8 (i32.const 61) (i32.const 69))  ;; 'E'
    (i32.store8 (i32.const 62) (i32.const 76))  ;; 'L'
    (i32.store8 (i32.const 63) (i32.const 76))  ;; 'L'
    (i32.store8 (i32.const 64) (i32.const 79))  ;; 'O'
    (local.set $result (call $is_valid_word (i32.const 60) (i32.const 65)))
    (if (i32.eqz (local.get $result))
      (then (unreachable))  ;; Fail - "HELLO" should be valid (all uppercase)
    )

    ;; Test passed
  )
)
