;; Simple test to verify is_digit works in lexer context
(module $is_digit_lexer_simple_test
  ;; Import memory and is_digit
  (import "lexer_memory" "memory" (memory 1))
  (import "char_utils" "is_digit" (func $is_digit (param i32) (result i32)))

  ;; Test function
  (func $test_is_digit_simple (export "_start")
    (local $result i32)

    ;; Test if '4' (0x34) is recognized as a digit
    (local.set $result (call $is_digit (i32.const 0x34)))

    ;; If is_digit returns 0 (false), fail
    (if (i32.eqz (local.get $result))
      (then (unreachable))
    )

    ;; Test passed
  )
)
