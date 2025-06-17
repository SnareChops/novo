;; Test skip_whitespace behavior on '4'
(module $skip_whitespace_test
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import skip_whitespace
  (import "char_utils" "skip_whitespace" (func $skip_whitespace (param i32) (result i32)))

  ;; Test function
  (func $test_skip_whitespace (export "_start")
    (local $original_pos i32)
    (local $after_skip i32)

    ;; Write test input: "4"
    (i32.store8 (i32.const 0) (i32.const 0x34))  ;; '4'
    (i32.store8 (i32.const 1) (i32.const 0x00))  ;; null terminator

    (local.set $original_pos (i32.const 0))

    ;; Call skip_whitespace
    (local.set $after_skip (call $skip_whitespace (local.get $original_pos)))

    ;; If skip_whitespace moved the position, '4' was treated as whitespace
    (if (i32.ne (local.get $original_pos) (local.get $after_skip))
      (then
        (unreachable)  ;; Fail - skip_whitespace incorrectly skipped '4'
      )
    )

    ;; Test passed - skip_whitespace correctly did not skip '4'
  )
)
