;; Comprehensive test for is_keyword function
(module $is_keyword_test
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import tokens
  (import "tokens" "TOKEN_IDENTIFIER" (global $TOKEN_IDENTIFIER i32))
  (import "tokens" "TOKEN_KW_FUNC" (global $TOKEN_KW_FUNC i32))
  (import "tokens" "TOKEN_KW_IF" (global $TOKEN_KW_IF i32))
  (import "tokens" "TOKEN_KW_BOOL" (global $TOKEN_KW_BOOL i32))
  (import "tokens" "TOKEN_KW_STRING" (global $TOKEN_KW_STRING i32))

  ;; Import is_keyword
  (import "keywords" "is_keyword" (func $is_keyword (param i32 i32) (result i32)))

  ;; Test function
  (func $test_is_keyword (export "_start")
    (local $result i32)

    ;; Test keyword "func"
    (i32.store8 (i32.const 0) (i32.const 102)) ;; 'f'
    (i32.store8 (i32.const 1) (i32.const 117)) ;; 'u'
    (i32.store8 (i32.const 2) (i32.const 110)) ;; 'n'
    (i32.store8 (i32.const 3) (i32.const 99))  ;; 'c'
    (local.set $result (call $is_keyword (i32.const 0) (i32.const 4)))
    ;; Should return a keyword token, not TOKEN_IDENTIFIER
    (if (i32.eq (local.get $result) (global.get $TOKEN_IDENTIFIER))
      (then (unreachable))  ;; Fail - "func" should be recognized as keyword
    )

    ;; Test keyword "if"
    (i32.store8 (i32.const 10) (i32.const 105)) ;; 'i'
    (i32.store8 (i32.const 11) (i32.const 102)) ;; 'f'
    (local.set $result (call $is_keyword (i32.const 10) (i32.const 2)))
    ;; Should return a keyword token, not TOKEN_IDENTIFIER
    (if (i32.eq (local.get $result) (global.get $TOKEN_IDENTIFIER))
      (then (unreachable))  ;; Fail - "if" should be recognized as keyword
    )

    ;; Test keyword "bool"
    (i32.store8 (i32.const 20) (i32.const 98))  ;; 'b'
    (i32.store8 (i32.const 21) (i32.const 111)) ;; 'o'
    (i32.store8 (i32.const 22) (i32.const 111)) ;; 'o'
    (i32.store8 (i32.const 23) (i32.const 108)) ;; 'l'
    (local.set $result (call $is_keyword (i32.const 20) (i32.const 4)))
    ;; Should return a keyword token, not TOKEN_IDENTIFIER
    (if (i32.eq (local.get $result) (global.get $TOKEN_IDENTIFIER))
      (then (unreachable))  ;; Fail - "bool" should be recognized as keyword
    )

    ;; Test keyword "string"
    (i32.store8 (i32.const 30) (i32.const 115)) ;; 's'
    (i32.store8 (i32.const 31) (i32.const 116)) ;; 't'
    (i32.store8 (i32.const 32) (i32.const 114)) ;; 'r'
    (i32.store8 (i32.const 33) (i32.const 105)) ;; 'i'
    (i32.store8 (i32.const 34) (i32.const 110)) ;; 'n'
    (i32.store8 (i32.const 35) (i32.const 103)) ;; 'g'
    (local.set $result (call $is_keyword (i32.const 30) (i32.const 6)))
    ;; Should return a keyword token, not TOKEN_IDENTIFIER
    (if (i32.eq (local.get $result) (global.get $TOKEN_IDENTIFIER))
      (then (unreachable))  ;; Fail - "string" should be recognized as keyword
    )

    ;; Test keyword "true"
    (i32.store8 (i32.const 40) (i32.const 116)) ;; 't'
    (i32.store8 (i32.const 41) (i32.const 114)) ;; 'r'
    (i32.store8 (i32.const 42) (i32.const 117)) ;; 'u'
    (i32.store8 (i32.const 43) (i32.const 101)) ;; 'e'
    (local.set $result (call $is_keyword (i32.const 40) (i32.const 4)))
    ;; Should return a keyword token, not TOKEN_IDENTIFIER
    (if (i32.eq (local.get $result) (global.get $TOKEN_IDENTIFIER))
      (then (unreachable))  ;; Fail - "true" should be recognized as keyword
    )

    ;; Test keyword "false"
    (i32.store8 (i32.const 50) (i32.const 102)) ;; 'f'
    (i32.store8 (i32.const 51) (i32.const 97))  ;; 'a'
    (i32.store8 (i32.const 52) (i32.const 108)) ;; 'l'
    (i32.store8 (i32.const 53) (i32.const 115)) ;; 's'
    (i32.store8 (i32.const 54) (i32.const 101)) ;; 'e'
    (local.set $result (call $is_keyword (i32.const 50) (i32.const 5)))
    ;; Should return a keyword token, not TOKEN_IDENTIFIER
    (if (i32.eq (local.get $result) (global.get $TOKEN_IDENTIFIER))
      (then (unreachable))  ;; Fail - "false" should be recognized as keyword
    )

    ;; Test non-keyword identifier "hello"
    (i32.store8 (i32.const 60) (i32.const 104)) ;; 'h'
    (i32.store8 (i32.const 61) (i32.const 101)) ;; 'e'
    (i32.store8 (i32.const 62) (i32.const 108)) ;; 'l'
    (i32.store8 (i32.const 63) (i32.const 108)) ;; 'l'
    (i32.store8 (i32.const 64) (i32.const 111)) ;; 'o'
    (local.set $result (call $is_keyword (i32.const 60) (i32.const 5)))
    ;; Should return TOKEN_IDENTIFIER
    (if (i32.ne (local.get $result) (global.get $TOKEN_IDENTIFIER))
      (then (unreachable))  ;; Fail - "hello" should be identifier, not keyword
    )

    ;; Test non-keyword identifier "test-name"
    (i32.store8 (i32.const 70) (i32.const 116)) ;; 't'
    (i32.store8 (i32.const 71) (i32.const 101)) ;; 'e'
    (i32.store8 (i32.const 72) (i32.const 115)) ;; 's'
    (i32.store8 (i32.const 73) (i32.const 116)) ;; 't'
    (i32.store8 (i32.const 74) (i32.const 45))  ;; '-'
    (i32.store8 (i32.const 75) (i32.const 110)) ;; 'n'
    (i32.store8 (i32.const 76) (i32.const 97))  ;; 'a'
    (i32.store8 (i32.const 77) (i32.const 109)) ;; 'm'
    (i32.store8 (i32.const 78) (i32.const 101)) ;; 'e'
    (local.set $result (call $is_keyword (i32.const 70) (i32.const 9)))
    ;; Should return TOKEN_IDENTIFIER
    (if (i32.ne (local.get $result) (global.get $TOKEN_IDENTIFIER))
      (then (unreachable))  ;; Fail - "test-name" should be identifier, not keyword
    )

    ;; Test partial keyword match "fun" (not "func")
    (i32.store8 (i32.const 80) (i32.const 102)) ;; 'f'
    (i32.store8 (i32.const 81) (i32.const 117)) ;; 'u'
    (i32.store8 (i32.const 82) (i32.const 110)) ;; 'n'
    (local.set $result (call $is_keyword (i32.const 80) (i32.const 3)))
    ;; Should return TOKEN_IDENTIFIER
    (if (i32.ne (local.get $result) (global.get $TOKEN_IDENTIFIER))
      (then (unreachable))  ;; Fail - "fun" should be identifier, not keyword
    )

    ;; Test empty string
    (local.set $result (call $is_keyword (i32.const 90) (i32.const 0)))
    ;; Should return TOKEN_IDENTIFIER
    (if (i32.ne (local.get $result) (global.get $TOKEN_IDENTIFIER))
      (then (unreachable))  ;; Fail - empty string should be identifier
    )

    ;; Test longer than keyword "function"
    (i32.store8 (i32.const 100) (i32.const 102)) ;; 'f'
    (i32.store8 (i32.const 101) (i32.const 117)) ;; 'u'
    (i32.store8 (i32.const 102) (i32.const 110)) ;; 'n'
    (i32.store8 (i32.const 103) (i32.const 99))  ;; 'c'
    (i32.store8 (i32.const 104) (i32.const 116)) ;; 't'
    (i32.store8 (i32.const 105) (i32.const 105)) ;; 'i'
    (i32.store8 (i32.const 106) (i32.const 111)) ;; 'o'
    (i32.store8 (i32.const 107) (i32.const 110)) ;; 'n'
    (local.set $result (call $is_keyword (i32.const 100) (i32.const 8)))
    ;; Should return TOKEN_IDENTIFIER
    (if (i32.ne (local.get $result) (global.get $TOKEN_IDENTIFIER))
      (then (unreachable))  ;; Fail - "function" should be identifier, not keyword
    )

    ;; Test passed
  )
)
