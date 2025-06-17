;; Comprehensive test for update_space_tracking function
(module $update_space_tracking_test
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import space tracking functions and globals
  (import "operators" "update_space_tracking" (func $update_space_tracking (param i32)))
  (import "operators" "last_char_was_space" (global $last_char_was_space (mut i32)))

  ;; Test function
  (func $test_update_space_tracking (export "_start")
    ;; Test with space character (32)
    (call $update_space_tracking (i32.const 32))  ;; space
    (if (i32.eqz (global.get $last_char_was_space))
      (then (unreachable))  ;; Fail - space should set last_char_was_space to true
    )

    ;; Test with tab character (9)
    (call $update_space_tracking (i32.const 9))   ;; tab
    (if (i32.eqz (global.get $last_char_was_space))
      (then (unreachable))  ;; Fail - tab should set last_char_was_space to true
    )

    ;; Test with newline character (10)
    (call $update_space_tracking (i32.const 10))  ;; newline
    (if (i32.eqz (global.get $last_char_was_space))
      (then (unreachable))  ;; Fail - newline should set last_char_was_space to true
    )

    ;; Test with non-whitespace character 'a' (97)
    (call $update_space_tracking (i32.const 97))  ;; 'a'
    (if (global.get $last_char_was_space)
      (then (unreachable))  ;; Fail - 'a' should set last_char_was_space to false
    )

    ;; Test with digit '5' (53)
    (call $update_space_tracking (i32.const 53))  ;; '5'
    (if (global.get $last_char_was_space)
      (then (unreachable))  ;; Fail - '5' should set last_char_was_space to false
    )

    ;; Test with operator '+' (43)
    (call $update_space_tracking (i32.const 43))  ;; '+'
    (if (global.get $last_char_was_space)
      (then (unreachable))  ;; Fail - '+' should set last_char_was_space to false
    )

    ;; Test back to space to verify it works again
    (call $update_space_tracking (i32.const 32))  ;; space
    (if (i32.eqz (global.get $last_char_was_space))
      (then (unreachable))  ;; Fail - space should set last_char_was_space to true
    )

    ;; Test passed
  )
)
