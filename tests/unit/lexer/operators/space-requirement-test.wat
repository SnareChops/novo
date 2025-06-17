;; Comprehensive test for space requirement functions
(module $space_requirement_test
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import space tracking functions and globals
  (import "operators" "require_space" (func $require_space))
  (import "operators" "check_space_requirement" (func $check_space_requirement (result i32)))
  (import "operators" "last_char_was_space" (global $last_char_was_space (mut i32)))
  (import "operators" "space_required" (global $space_required (mut i32)))

  ;; Test function
  (func $test_space_requirement (export "_start")
    (local $result i32)

    ;; Test initial state - space_required should be 0, last_char_was_space should be 1
    ;; check_space_requirement should return true (no requirement or last char was space)
    (local.set $result (call $check_space_requirement))
    (if (i32.eqz (local.get $result))
      (then (unreachable))  ;; Fail - initial state should allow continuation
    )

    ;; Set space requirement
    (call $require_space)
    ;; Verify space_required is now set
    (if (i32.eqz (global.get $space_required))
      (then (unreachable))  ;; Fail - require_space should set space_required to 1
    )

    ;; Test when space is required and last char was space (should pass)
    (global.set $last_char_was_space (i32.const 1))  ;; last char was space
    (local.set $result (call $check_space_requirement))
    (if (i32.eqz (local.get $result))
      (then (unreachable))  ;; Fail - should pass when space required and last char was space
    )

    ;; Test when space is required and last char was NOT space (should fail)
    (global.set $last_char_was_space (i32.const 0))  ;; last char was NOT space
    (local.set $result (call $check_space_requirement))
    (if (local.get $result)
      (then (unreachable))  ;; Fail - should fail when space required but last char was not space
    )

    ;; Reset space requirement to 0
    (global.set $space_required (i32.const 0))
    ;; Test when space is NOT required and last char was NOT space (should pass)
    (global.set $last_char_was_space (i32.const 0))  ;; last char was NOT space
    (local.set $result (call $check_space_requirement))
    (if (i32.eqz (local.get $result))
      (then (unreachable))  ;; Fail - should pass when space not required
    )

    ;; Test when space is NOT required and last char was space (should pass)
    (global.set $last_char_was_space (i32.const 1))  ;; last char was space
    (local.set $result (call $check_space_requirement))
    (if (i32.eqz (local.get $result))
      (then (unreachable))  ;; Fail - should pass when space not required
    )

    ;; Test passed
  )
)
