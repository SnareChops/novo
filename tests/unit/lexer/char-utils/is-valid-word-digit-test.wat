;; Test is_valid_word with digits to isolate the bug
(module $is_valid_word_digit_test
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import is_valid_word
  (import "char_utils" "is_valid_word" (func $is_valid_word (param i32 i32) (result i32)))

  ;; Test function
  (func $test_is_valid_word_with_digits (export "_start")
    (local $result i32)

    ;; Test valid word with digits: "test123"
    (i32.store8 (i32.const 20) (i32.const 116)) ;; 't'
    (i32.store8 (i32.const 21) (i32.const 101)) ;; 'e'
    (i32.store8 (i32.const 22) (i32.const 115)) ;; 's'
    (i32.store8 (i32.const 23) (i32.const 116)) ;; 't'
    (i32.store8 (i32.const 24) (i32.const 49))  ;; '1'
    (i32.store8 (i32.const 25) (i32.const 50))  ;; '2'
    (i32.store8 (i32.const 26) (i32.const 51))  ;; '3'
    (local.set $result (call $is_valid_word (i32.const 20) (i32.const 27)))
    (if (i32.eqz (local.get $result))
      (then (unreachable))  ;; Fail - "test123" should be valid
    )

    ;; Test passed
  )
)
