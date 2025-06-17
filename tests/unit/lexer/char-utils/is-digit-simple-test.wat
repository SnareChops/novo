;; Test is_digit function directly
(module $char_test
  ;; Import char utils
  (import "char_utils" "is_digit" (func $is_digit (param i32) (result i32)))

  ;; Test function
  (func $test_is_digit (export "_start")
    (local $result i32)

    ;; Test with '4' (ASCII 52)
    (local.set $result (call $is_digit (i32.const 52)))

    ;; If is_digit returns 0 (false), fail the test
    (if (i32.eqz (local.get $result))
      (then
        (unreachable)
      )
    )

    ;; Test passed
  )
)
