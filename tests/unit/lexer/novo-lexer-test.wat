;; Novo Lexer Unit Tests
(module $novo_lexer_test
  ;; Import shared memory from memory module
  (import "lexer_memory" "memory" (memory 1))
  (import "lexer_memory" "update_position" (func $update_position (param i32)))

  ;; Import token constants
  (import "lexer_tokens" "TOKEN_ERROR" (global $TOKEN_ERROR i32))
  (import "lexer_tokens" "TOKEN_IDENTIFIER" (global $TOKEN_IDENTIFIER i32))
  (import "lexer_tokens" "TOKEN_COLON" (global $TOKEN_COLON i32))
  (import "lexer_tokens" "TOKEN_ASSIGN" (global $TOKEN_ASSIGN i32))
  (import "lexer_tokens" "TOKEN_ARROW" (global $TOKEN_ARROW i32))
  (import "lexer_tokens" "TOKEN_META" (global $TOKEN_META i32))
  (import "lexer_tokens" "TOKEN_LBRACE" (global $TOKEN_LBRACE i32))
  (import "lexer_tokens" "TOKEN_RBRACE" (global $TOKEN_RBRACE i32))
  (import "lexer_tokens" "TOKEN_KW_FUNC" (global $TOKEN_KW_FUNC i32))
  (import "lexer_tokens" "TOKEN_KW_RECORD" (global $TOKEN_KW_RECORD i32))
  (import "lexer_tokens" "TOKEN_KW_STRING" (global $TOKEN_KW_STRING i32))
  (import "lexer_tokens" "TOKEN_KW_BOOL" (global $TOKEN_KW_BOOL i32))
  (import "lexer_tokens" "TOKEN_KW_TRUE" (global $TOKEN_KW_TRUE i32))
  (import "lexer_tokens" "TOKEN_KW_FALSE" (global $TOKEN_KW_FALSE i32))

  ;; Import lexer functions from novo_lexer main module
  (import "novo_lexer" "next_token" (func $next_token (param i32) (result i32 i32)))

  ;; Token field offsets (must match lexer)
  (global $TOKEN_TYPE_OFFSET i32 (i32.const 0))
  (global $TOKEN_START_OFFSET i32 (i32.const 4))
  (global $TOKEN_LINE_OFFSET i32 (i32.const 8))
  (global $TOKEN_COLUMN_OFFSET i32 (i32.const 12))
  (global $TOKEN_RECORD_SIZE i32 (i32.const 16))
  (global $TOKEN_ARRAY_START i32 (i32.const 2048))

  ;; Test helper functions
  (func $assert_eq (param $actual i32) (param $expected i32)
    (if (i32.ne (local.get $actual) (local.get $expected))
      (then unreachable)
    )
  )

  (func $assert_token (param $token_idx i32) (param $expected_type i32) (param $expected_line i32) (param $expected_col i32)
    (local $token_offset i32)

    ;; Calculate token offset
    (local.set $token_offset
      (i32.add
        (global.get $TOKEN_ARRAY_START)
        (i32.mul (local.get $token_idx) (global.get $TOKEN_RECORD_SIZE))
      )
    )

    ;; Assert token type
    (call $assert_eq
      (i32.load (i32.add (local.get $token_offset) (global.get $TOKEN_TYPE_OFFSET)))
      (local.get $expected_type)
    )

    ;; Assert line number
    (call $assert_eq
      (i32.load (i32.add (local.get $token_offset) (global.get $TOKEN_LINE_OFFSET)))
      (local.get $expected_line)
    )

    ;; Assert column number
    (call $assert_eq
      (i32.load (i32.add (local.get $token_offset) (global.get $TOKEN_COLUMN_OFFSET)))
      (local.get $expected_col)
    )
  )

  ;; Test: Basic Operators
  (func $test_operators
    (local $pos i32)
    (local $token_idx i32)
    (local $next_pos i32)

    ;; Write test input: "foo := bar : baz => qux :: { }"
    (i32.store8 (i32.const 0) (i32.const 0x66))  ;; 'f'
    (i32.store8 (i32.const 1) (i32.const 0x6f))  ;; 'o'
    (i32.store8 (i32.const 2) (i32.const 0x6f))  ;; 'o'
    (i32.store8 (i32.const 3) (i32.const 0x20))  ;; ' '
    (i32.store8 (i32.const 4) (i32.const 0x3a))  ;; ':'
    (i32.store8 (i32.const 5) (i32.const 0x3d))  ;; '='
    (i32.store8 (i32.const 6) (i32.const 0x20))  ;; ' '
    (i32.store8 (i32.const 7) (i32.const 0x62))  ;; 'b'
    (i32.store8 (i32.const 8) (i32.const 0x61))  ;; 'a'
    (i32.store8 (i32.const 9) (i32.const 0x72))  ;; 'r'
    (i32.store8 (i32.const 10) (i32.const 0x20)) ;; ' '
    (i32.store8 (i32.const 11) (i32.const 0x3a)) ;; ':'
    (i32.store8 (i32.const 12) (i32.const 0x20)) ;; ' '
    (i32.store8 (i32.const 13) (i32.const 0x62)) ;; 'b'
    (i32.store8 (i32.const 14) (i32.const 0x61)) ;; 'a'
    (i32.store8 (i32.const 15) (i32.const 0x7a)) ;; 'z'
    (i32.store8 (i32.const 16) (i32.const 0x20)) ;; ' '
    (i32.store8 (i32.const 17) (i32.const 0x3d)) ;; '='
    (i32.store8 (i32.const 18) (i32.const 0x3e)) ;; '>'
    (i32.store8 (i32.const 19) (i32.const 0x20)) ;; ' '
    (i32.store8 (i32.const 20) (i32.const 0x71)) ;; 'q'
    (i32.store8 (i32.const 21) (i32.const 0x75)) ;; 'u'
    (i32.store8 (i32.const 22) (i32.const 0x78)) ;; 'x'
    (i32.store8 (i32.const 23) (i32.const 0x20)) ;; ' '
    (i32.store8 (i32.const 24) (i32.const 0x3a)) ;; ':'
    (i32.store8 (i32.const 25) (i32.const 0x3a)) ;; ':'
    (i32.store8 (i32.const 26) (i32.const 0x20)) ;; ' '
    (i32.store8 (i32.const 27) (i32.const 0x7b)) ;; '{'
    (i32.store8 (i32.const 28) (i32.const 0x20)) ;; ' '
    (i32.store8 (i32.const 29) (i32.const 0x7d)) ;; '}'
    (i32.store8 (i32.const 30) (i32.const 0))    ;; null

    (local.set $pos (i32.const 0))

    ;; First token: identifier "foo"
    (call $next_token (local.get $pos))
    (local.set $next_pos)
    (local.set $token_idx)
    (call $assert_token (local.get $token_idx) (global.get $TOKEN_IDENTIFIER) (i32.const 1) (i32.const 1))
    (local.set $pos (local.get $next_pos))

    ;; Skip whitespace
    (call $next_token (local.get $pos))
    (local.set $next_pos)
    (local.set $pos)

    ;; Test := operator
    (call $next_token (local.get $pos))
    (local.set $next_pos)
    (local.set $token_idx)
    (call $assert_token (local.get $token_idx) (global.get $TOKEN_ASSIGN) (i32.const 1) (i32.const 5))
    (local.set $pos (local.get $next_pos))

    ;; Skip to single colon
    (call $next_token (local.get $pos)) ;; whitespace
    (local.set $next_pos)
    (local.set $pos)
    (call $next_token (local.get $pos)) ;; "bar"
    (local.set $next_pos)
    (local.set $pos)
    (call $next_token (local.get $pos)) ;; whitespace
    (local.set $next_pos)
    (local.set $pos)

    ;; Test : operator
    (call $next_token (local.get $pos))
    (local.set $next_pos)
    (local.set $token_idx)
    (call $assert_token (local.get $token_idx) (global.get $TOKEN_COLON) (i32.const 1) (i32.const 11))
    (local.set $pos (local.get $next_pos))

    ;; Skip to arrow
    (call $next_token (local.get $pos)) ;; whitespace
    (local.set $next_pos)
    (local.set $pos)
    (call $next_token (local.get $pos)) ;; "baz"
    (local.set $next_pos)
    (local.set $pos)
    (call $next_token (local.get $pos)) ;; whitespace
    (local.set $next_pos)
    (local.set $pos)

    ;; Test => operator
    (call $next_token (local.get $pos))
    (local.set $next_pos)
    (local.set $token_idx)
    (call $assert_token (local.get $token_idx) (global.get $TOKEN_ARROW) (i32.const 1) (i32.const 17))
    (local.set $pos (local.get $next_pos))

    ;; Skip to meta operator
    (call $next_token (local.get $pos)) ;; whitespace
    (local.set $next_pos)
    (local.set $pos)
    (call $next_token (local.get $pos)) ;; "qux"
    (local.set $next_pos)
    (local.set $pos)
    (call $next_token (local.get $pos)) ;; whitespace
    (local.set $next_pos)
    (local.set $pos)

    ;; Test :: operator
    (call $next_token (local.get $pos))
    (local.set $next_pos)
    (local.set $token_idx)
    (call $assert_token (local.get $token_idx) (global.get $TOKEN_META) (i32.const 1) (i32.const 24))
    (local.set $pos (local.get $next_pos))

    ;; Skip whitespace
    (call $next_token (local.get $pos))
    (local.set $next_pos)
    (local.set $pos)

    ;; Test { token
    (call $next_token (local.get $pos))
    (local.set $next_pos)
    (local.set $token_idx)
    (call $assert_token (local.get $token_idx) (global.get $TOKEN_LBRACE) (i32.const 1) (i32.const 27))
    (local.set $pos (local.get $next_pos))

    ;; Skip whitespace
    (call $next_token (local.get $pos))
    (local.set $next_pos)
    (local.set $pos)

    ;; Test } token
    (call $next_token (local.get $pos))
    (local.set $next_pos)
    (local.set $token_idx)
    (call $assert_token (local.get $token_idx) (global.get $TOKEN_RBRACE) (i32.const 1) (i32.const 29))
  )

  ;; Test: MultiLine Identifier
  (func $test_identifier_multiline
    ;; TODO: Add test implementation
  )

  ;; Test: Basic Identifier
  (func $test_identifier
    ;; TODO: Add test implementation
  )

  ;; Test: Keyword Recognition
  (func $test_keywords
    (local $pos i32)
    (local $token_idx i32)
    (local $next_pos i32)

    ;; Test input: "func record string bool true false"
    (i32.store8 (i32.const 0) (i32.const 0x66))  ;; 'f'
    (i32.store8 (i32.const 1) (i32.const 0x75))  ;; 'u'
    (i32.store8 (i32.const 2) (i32.const 0x6e))  ;; 'n'
    (i32.store8 (i32.const 3) (i32.const 0x63))  ;; 'c'
    (i32.store8 (i32.const 4) (i32.const 0x20))  ;; ' '
    (i32.store8 (i32.const 5) (i32.const 0x72))  ;; 'r'
    (i32.store8 (i32.const 6) (i32.const 0x65))  ;; 'e'
    (i32.store8 (i32.const 7) (i32.const 0x63))  ;; 'c'
    (i32.store8 (i32.const 8) (i32.const 0x6f))  ;; 'o'
    (i32.store8 (i32.const 9) (i32.const 0x72))  ;; 'r'
    (i32.store8 (i32.const 10) (i32.const 0x64)) ;; 'd'
    (i32.store8 (i32.const 11) (i32.const 0x20)) ;; ' '
    (i32.store8 (i32.const 12) (i32.const 0x73)) ;; 's'
    (i32.store8 (i32.const 13) (i32.const 0x74)) ;; 't'
    (i32.store8 (i32.const 14) (i32.const 0x72)) ;; 'r'
    (i32.store8 (i32.const 15) (i32.const 0x69)) ;; 'i'
    (i32.store8 (i32.const 16) (i32.const 0x6e)) ;; 'n'
    (i32.store8 (i32.const 17) (i32.const 0x67)) ;; 'g'
    (i32.store8 (i32.const 18) (i32.const 0x20)) ;; ' '
    (i32.store8 (i32.const 19) (i32.const 0x62)) ;; 'b'
    (i32.store8 (i32.const 20) (i32.const 0x6f)) ;; 'o'
    (i32.store8 (i32.const 21) (i32.const 0x6f)) ;; 'o'
    (i32.store8 (i32.const 22) (i32.const 0x6c)) ;; 'l'
    (i32.store8 (i32.const 23) (i32.const 0x20)) ;; ' '
    (i32.store8 (i32.const 24) (i32.const 0x74)) ;; 't'
    (i32.store8 (i32.const 25) (i32.const 0x72)) ;; 'r'
    (i32.store8 (i32.const 26) (i32.const 0x75)) ;; 'u'
    (i32.store8 (i32.const 27) (i32.const 0x65)) ;; 'e'
    (i32.store8 (i32.const 28) (i32.const 0x20)) ;; ' '
    (i32.store8 (i32.const 29) (i32.const 0x66)) ;; 'f'
    (i32.store8 (i32.const 30) (i32.const 0x61)) ;; 'a'
    (i32.store8 (i32.const 31) (i32.const 0x6c)) ;; 'l'
    (i32.store8 (i32.const 32) (i32.const 0x73)) ;; 's'
    (i32.store8 (i32.const 33) (i32.const 0x65)) ;; 'e'

    ;; Reset position
    (local.set $pos (i32.const 0))
    (local.set $token_idx (i32.const 0))

    ;; Test func keyword
    (call $next_token (local.get $pos))
    (local.set $token_idx)
    (local.set $next_pos)
    (call $assert_token (local.get $token_idx) (global.get $TOKEN_KW_FUNC) (i32.const 1) (i32.const 1))
    (local.set $pos (local.get $next_pos))

    ;; Skip whitespace
    (call $next_token (local.get $pos))
    (local.set $token_idx)
    (local.set $next_pos)
    (local.set $pos (local.get $next_pos))

    ;; Test record keyword
    (call $next_token (local.get $pos))
    (local.set $token_idx)
    (local.set $next_pos)
    (call $assert_token (local.get $token_idx) (global.get $TOKEN_KW_RECORD) (i32.const 1) (i32.const 6))
    (local.set $pos (local.get $next_pos))

    ;; Test string keyword
    (call $next_token (local.get $pos))
    (local.set $token_idx)
    (local.set $next_pos)
    (call $assert_token (local.get $token_idx) (global.get $TOKEN_KW_STRING) (i32.const 1) (i32.const 13))
    (local.set $pos (local.get $next_pos))

    ;; Test bool keyword
    (call $next_token (local.get $pos))
    (local.set $token_idx)
    (local.set $next_pos)
    (call $assert_token (local.get $token_idx) (global.get $TOKEN_KW_BOOL) (i32.const 1) (i32.const 20))
    (local.set $pos (local.get $next_pos))

    ;; Test true keyword
    (call $next_token (local.get $pos))
    (local.set $token_idx)
    (local.set $next_pos)
    (call $assert_token (local.get $token_idx) (global.get $TOKEN_KW_TRUE) (i32.const 1) (i32.const 25))
    (local.set $pos (local.get $next_pos))

    ;; Test false keyword
    (call $next_token (local.get $pos))
    (local.set $token_idx)
    (local.set $next_pos)
    (call $assert_token (local.get $token_idx) (global.get $TOKEN_KW_FALSE) (i32.const 1) (i32.const 31))
  )

  ;; Test: Edge Cases with Keywords and Identifiers
  (func $test_edge_cases
    (local $pos i32)
    (local $token_idx i32)
    (local $next_pos i32)

    ;; Test input: "%interface my-func-if WIT-demo bad--name a--b"
    ;; Tests:
    ;; 1. % prefix with keyword
    ;; 2. identifier containing keyword
    ;; 3. Mixed case
    ;; 4. Invalid double hyphen
    ;; 5. Another invalid double hyphen
    (i32.store8 (i32.const 100) (i32.const 0x25)) ;; %
    (i32.store8 (i32.const 101) (i32.const 0x69)) ;; i
    (i32.store8 (i32.const 102) (i32.const 0x6e)) ;; n
    (i32.store8 (i32.const 103) (i32.const 0x74)) ;; t
    (i32.store8 (i32.const 104) (i32.const 0x65)) ;; e
    (i32.store8 (i32.const 105) (i32.const 0x72)) ;; r
    (i32.store8 (i32.const 106) (i32.const 0x66)) ;; f
    (i32.store8 (i32.const 107) (i32.const 0x61)) ;; a
    (i32.store8 (i32.const 108) (i32.const 0x63)) ;; c
    (i32.store8 (i32.const 109) (i32.const 0x65)) ;; e
    (i32.store8 (i32.const 110) (i32.const 0x20)) ;; space

    ;; my-func-if
    (i32.store8 (i32.const 111) (i32.const 0x6d)) ;; m
    (i32.store8 (i32.const 112) (i32.const 0x79)) ;; y
    (i32.store8 (i32.const 113) (i32.const 0x2d)) ;; -
    (i32.store8 (i32.const 114) (i32.const 0x66)) ;; f
    (i32.store8 (i32.const 115) (i32.const 0x75)) ;; u
    (i32.store8 (i32.const 116) (i32.const 0x6e)) ;; n
    (i32.store8 (i32.const 117) (i32.const 0x63)) ;; c
    (i32.store8 (i32.const 118) (i32.const 0x2d)) ;; -
    (i32.store8 (i32.const 119) (i32.const 0x69)) ;; i
    (i32.store8 (i32.const 120) (i32.const 0x66)) ;; f
    (i32.store8 (i32.const 121) (i32.const 0x20)) ;; space

    ;; WIT-demo
    (i32.store8 (i32.const 122) (i32.const 0x57)) ;; W
    (i32.store8 (i32.const 123) (i32.const 0x49)) ;; I
    (i32.store8 (i32.const 124) (i32.const 0x54)) ;; T
    (i32.store8 (i32.const 125) (i32.const 0x2d)) ;; -
    (i32.store8 (i32.const 126) (i32.const 0x64)) ;; d
    (i32.store8 (i32.const 127) (i32.const 0x65)) ;; e
    (i32.store8 (i32.const 128) (i32.const 0x6d)) ;; m
    (i32.store8 (i32.const 129) (i32.const 0x6f)) ;; o
    (i32.store8 (i32.const 130) (i32.const 0x20)) ;; space

    ;; bad--name
    (i32.store8 (i32.const 131) (i32.const 0x62)) ;; b
    (i32.store8 (i32.const 132) (i32.const 0x61)) ;; a
    (i32.store8 (i32.const 133) (i32.const 0x64)) ;; d
    (i32.store8 (i32.const 134) (i32.const 0x2d)) ;; -
    (i32.store8 (i32.const 135) (i32.const 0x2d)) ;; -
    (i32.store8 (i32.const 136) (i32.const 0x6e)) ;; n
    (i32.store8 (i32.const 137) (i32.const 0x61)) ;; a
    (i32.store8 (i32.const 138) (i32.const 0x6d)) ;; m
    (i32.store8 (i32.const 139) (i32.const 0x65)) ;; e
    (i32.store8 (i32.const 140) (i32.const 0x20)) ;; space

    ;; Reset position
    (local.set $pos (i32.const 100))
    (local.set $token_idx (i32.const 0))

    ;; Test %interface (should be identifier, not keyword)
    (call $next_token (local.get $pos))
    (local.set $token_idx)
    (local.set $next_pos)
    (call $assert_token (local.get $token_idx) (global.get $TOKEN_IDENTIFIER) (i32.const 1) (i32.const 1))
    (local.set $pos (local.get $next_pos))

    ;; Skip whitespace
    (call $next_token (local.get $pos))
    (local.set $token_idx)
    (local.set $next_pos)
    (local.set $pos (local.get $next_pos))

    ;; Test my-func-if (valid identifier containing keyword)
    (call $next_token (local.get $pos))
    (local.set $token_idx)
    (local.set $next_pos)
    (call $assert_token (local.get $token_idx) (global.get $TOKEN_IDENTIFIER) (i32.const 1) (i32.const 12))
    (local.set $pos (local.get $next_pos))

    ;; Skip whitespace
    (call $next_token (local.get $pos))
    (local.set $token_idx)
    (local.set $next_pos)
    (local.set $pos (local.get $next_pos))

    ;; Test WIT-demo (valid mixed case)
    (call $next_token (local.get $pos))
    (local.set $token_idx)
    (local.set $next_pos)
    (call $assert_token (local.get $token_idx) (global.get $TOKEN_IDENTIFIER) (i32.const 1) (i32.const 23))
    (local.set $pos (local.get $next_pos))

    ;; Skip whitespace
    (call $next_token (local.get $pos))
    (local.set $token_idx)
    (local.set $next_pos)
    (local.set $pos (local.get $next_pos))

    ;; Test bad--name (should be error)
    (call $next_token (local.get $pos))
    (local.set $token_idx)
    (local.set $next_pos)
    (call $assert_token (local.get $token_idx) (global.get $TOKEN_ERROR) (i32.const 1) (i32.const 32))
  )

  ;; Export test functions
  (export "test_operators" (func $test_operators))
  (export "test_identifier_multiline" (func $test_identifier_multiline))
  (export "test_identifier" (func $test_identifier))
  (export "test_keywords" (func $test_keywords))
  (export "test_edge_cases" (func $test_edge_cases))
)
