;; Comprehensive test for is_valid_word function
(module $is_valid_word_test
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import is_valid_word
  (import "char_utils" "is_valid_word" (func $is_valid_word (param i32 i32) (result i32)))

  ;; Helper function to write string to memory
  (func $write_string (param $pos i32) (param $str_data i32) (param $len i32)
    (local $i i32)
    (local.set $i (i32.const 0))
    (loop $copy_loop
      (if (i32.lt_s (local.get $i) (local.get $len))
        (then
          (i32.store8
            (i32.add (local.get $pos) (local.get $i))
            (i32.load8_u (i32.add (local.get $str_data) (local.get $i)))
          )
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $copy_loop)
        )
      )
    )
  )

  ;; Test function
  (func $test_is_valid_word (export "_start")
    (local $result i32)

    ;; Test empty string (should return false)
    (local.set $result (call $is_valid_word (i32.const 0) (i32.const 0)))
    (if (local.get $result)
      (then (unreachable))  ;; Fail - empty string should not be valid
    )

    ;; Test valid lowercase word: "hello"
    (i32.store8 (i32.const 0) (i32.const 104))  ;; 'h'
    (i32.store8 (i32.const 1) (i32.const 101))  ;; 'e'
    (i32.store8 (i32.const 2) (i32.const 108))  ;; 'l'
    (i32.store8 (i32.const 3) (i32.const 108))  ;; 'l'
    (i32.store8 (i32.const 4) (i32.const 111))  ;; 'o'
    (local.set $result (call $is_valid_word (i32.const 0) (i32.const 5)))
    (if (i32.eqz (local.get $result))
      (then (unreachable))  ;; Fail - "hello" should be valid
    )

    ;; Test valid single letter: "a"
    (i32.store8 (i32.const 10) (i32.const 97))  ;; 'a'
    (local.set $result (call $is_valid_word (i32.const 10) (i32.const 11)))
    (if (i32.eqz (local.get $result))
      (then (unreachable))  ;; Fail - "a" should be valid
    )

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

    ;; Test invalid - starts with digit: "123abc"
    (i32.store8 (i32.const 30) (i32.const 49))  ;; '1'
    (i32.store8 (i32.const 31) (i32.const 50))  ;; '2'
    (i32.store8 (i32.const 32) (i32.const 51))  ;; '3'
    (i32.store8 (i32.const 33) (i32.const 97))  ;; 'a'
    (i32.store8 (i32.const 34) (i32.const 98))  ;; 'b'
    (i32.store8 (i32.const 35) (i32.const 99))  ;; 'c'
    (local.set $result (call $is_valid_word (i32.const 30) (i32.const 36)))
    (if (local.get $result)
      (then (unreachable))  ;; Fail - "123abc" should not be valid
    )

    ;; Test invalid - contains hyphen: "test-word"
    (i32.store8 (i32.const 40) (i32.const 116)) ;; 't'
    (i32.store8 (i32.const 41) (i32.const 101)) ;; 'e'
    (i32.store8 (i32.const 42) (i32.const 115)) ;; 's'
    (i32.store8 (i32.const 43) (i32.const 116)) ;; 't'
    (i32.store8 (i32.const 44) (i32.const 45))  ;; '-'
    (i32.store8 (i32.const 45) (i32.const 119)) ;; 'w'
    (i32.store8 (i32.const 46) (i32.const 111)) ;; 'o'
    (i32.store8 (i32.const 47) (i32.const 114)) ;; 'r'
    (i32.store8 (i32.const 48) (i32.const 100)) ;; 'd'
    (local.set $result (call $is_valid_word (i32.const 40) (i32.const 49)))
    (if (local.get $result)
      (then (unreachable))  ;; Fail - "test-word" should not be valid (hyphen not allowed in word)
    )

    ;; Test invalid - mixed case: "TestWord"
    (i32.store8 (i32.const 50) (i32.const 84))  ;; 'T'
    (i32.store8 (i32.const 51) (i32.const 101)) ;; 'e'
    (i32.store8 (i32.const 52) (i32.const 115)) ;; 's'
    (i32.store8 (i32.const 53) (i32.const 116)) ;; 't'
    (i32.store8 (i32.const 54) (i32.const 87))  ;; 'W'
    (i32.store8 (i32.const 55) (i32.const 111)) ;; 'o'
    (i32.store8 (i32.const 56) (i32.const 114)) ;; 'r'
    (i32.store8 (i32.const 57) (i32.const 100)) ;; 'd'
    (local.set $result (call $is_valid_word (i32.const 50) (i32.const 58)))
    (if (local.get $result)
      (then (unreachable))  ;; Fail - "TestWord" should not be valid (mixed case)
    )

    ;; Test valid all uppercase: "HELLO"
    (i32.store8 (i32.const 60) (i32.const 72))  ;; 'H'
    (i32.store8 (i32.const 61) (i32.const 69))  ;; 'E'
    (i32.store8 (i32.const 62) (i32.const 76))  ;; 'L'
    (i32.store8 (i32.const 63) (i32.const 76))  ;; 'L'
    (i32.store8 (i32.const 64) (i32.const 79))  ;; 'O'
    (local.set $result (call $is_valid_word (i32.const 60) (i32.const 65)))
    (if (i32.eqz (local.get $result))
      (then (unreachable))  ;; Fail - "HELLO" should be valid (all uppercase)
    )

    ;; Test invalid - contains space: "test word"
    (i32.store8 (i32.const 70) (i32.const 116)) ;; 't'
    (i32.store8 (i32.const 71) (i32.const 101)) ;; 'e'
    (i32.store8 (i32.const 72) (i32.const 115)) ;; 's'
    (i32.store8 (i32.const 73) (i32.const 116)) ;; 't'
    (i32.store8 (i32.const 74) (i32.const 32))  ;; ' '
    (i32.store8 (i32.const 75) (i32.const 119)) ;; 'w'
    (i32.store8 (i32.const 76) (i32.const 111)) ;; 'o'
    (i32.store8 (i32.const 77) (i32.const 114)) ;; 'r'
    (i32.store8 (i32.const 78) (i32.const 100)) ;; 'd'
    (local.set $result (call $is_valid_word (i32.const 70) (i32.const 79)))
    (if (local.get $result)
      (then (unreachable))  ;; Fail - "test word" should not be valid (contains space)
    )

    ;; Test invalid - negative range
    (local.set $result (call $is_valid_word (i32.const 10) (i32.const 5)))
    (if (local.get $result)
      (then (unreachable))  ;; Fail - negative range should not be valid
    )

    ;; Test passed
  )
)
