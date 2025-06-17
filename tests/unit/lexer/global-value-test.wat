;; Test to see what value the TOKEN_NUMBER_LITERAL global has
(module $global_value_test
  ;; Import TOKEN_NUMBER_LITERAL global
  (import "lexer_tokens" "TOKEN_NUMBER_LITERAL" (global $TOKEN_NUMBER_LITERAL i32))

  (memory 1)  ;; Add memory for the error cases

  ;; Test function
  (func $test_global_value (export "_start")
    (local $global_value i32)

    ;; Get the global value
    (local.set $global_value (global.get $TOKEN_NUMBER_LITERAL))

    ;; Check if it's the expected value (54)
    (if (i32.ne (local.get $global_value) (i32.const 54))
      (then
        ;; Wrong value - use the actual value to determine what it is
        ;; If it's 0, cause specific error
        (if (i32.eqz (local.get $global_value))
          (then
            (i32.store8 (i32.const 999999) (i32.const 1))  ;; Global is 0
          )
        )

        ;; If it's 1, cause different error
        (if (i32.eq (local.get $global_value) (i32.const 1))
          (then
            (i32.store8 (i32.const 999998) (i32.const 1))  ;; Global is 1
          )
        )

        ;; Default case
        (unreachable)  ;; Global is some other unexpected value
      )
    )

    ;; Test passed - global value is correct (54)
  )
)
