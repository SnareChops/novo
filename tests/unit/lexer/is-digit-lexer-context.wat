;; Test is_digit exactly as the lexer does - through the lexer's import
(module $is_digit_lexer_context_test
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import lexer functions - use the SAME import path as the lexer
  (import "char_utils" "is_digit" (func $is_digit (param i32) (result i32)))

  ;; Test function
  (func $test_is_digit_in_lexer_context (export "_start")
    (local $char i32)
    (local $result i32)

    ;; Write test input: "4"
    (i32.store8 (i32.const 0) (i32.const 0x34))  ;; '4'

    ;; Load the character exactly as the lexer does
    (local.set $char (i32.load8_u (i32.const 0)))

    ;; Test with is_digit
    (local.set $result (call $is_digit (local.get $char)))

    ;; If is_digit returns 0 (false), fail the test
    (if (i32.eqz (local.get $result))
      (then
        (unreachable)
      )
    )

    ;; Test passed
  )
)
