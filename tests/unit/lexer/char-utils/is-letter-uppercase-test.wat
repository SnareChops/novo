;; Test is_letter function with uppercase letters
(module $is_letter_uppercase_test
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import is_letter
  (import "char_utils" "is_letter" (func $is_letter (param i32) (result i32)))

  ;; Test function
  (func $test_is_letter_uppercase (export "_start")
    (local $result i32)

    ;; Test uppercase 'H' (72)
    (local.set $result (call $is_letter (i32.const 72)))
    (if (i32.eqz (local.get $result))
      (then (unreachable))  ;; Fail - 'H' should be a letter
    )

    ;; Test lowercase 'h' (104)
    (local.set $result (call $is_letter (i32.const 104)))
    (if (i32.eqz (local.get $result))
      (then (unreachable))  ;; Fail - 'h' should be a letter
    )

    ;; Test passed
  )
)
