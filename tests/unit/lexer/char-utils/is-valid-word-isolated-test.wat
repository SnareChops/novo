;; Isolated test for debugging is_valid_word failures
(module $is_valid_word_isolated_test
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import is_valid_word
  (import "char_utils" "is_valid_word" (func $is_valid_word (param i32 i32) (result i32)))

  ;; Test function
  (func $test_is_valid_word_isolated (export "_start")
    (local $result i32)

    ;; Test 1: empty string (should return false)
    (local.set $result (call $is_valid_word (i32.const 0) (i32.const 0)))
    (if (local.get $result)
      (then (unreachable))  ;; Fail - empty string should not be valid
    )

    ;; If we get here, test 1 passed. Test 2: valid lowercase word "hello"
    (i32.store8 (i32.const 0) (i32.const 104))  ;; 'h'
    (i32.store8 (i32.const 1) (i32.const 101))  ;; 'e'
    (i32.store8 (i32.const 2) (i32.const 108))  ;; 'l'
    (i32.store8 (i32.const 3) (i32.const 108))  ;; 'l'
    (i32.store8 (i32.const 4) (i32.const 111))  ;; 'o'
    (local.set $result (call $is_valid_word (i32.const 0) (i32.const 5)))
    (if (i32.eqz (local.get $result))
      (then (unreachable))  ;; Fail - "hello" should be valid
    )

    ;; Test passed - both basic tests work
  )
)
