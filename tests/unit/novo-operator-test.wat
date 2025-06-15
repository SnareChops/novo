;; Novo Operator Tests
(module $novo_operator_test
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import token constants
  (import "lexer_tokens" "TOKEN_ERROR" (global $TOKEN_ERROR i32))
  (import "lexer_tokens" "TOKEN_IDENTIFIER" (global $TOKEN_IDENTIFIER i32))
  (import "lexer_tokens" "TOKEN_WHITESPACE" (global $TOKEN_WHITESPACE i32))
  (import "lexer_tokens" "TOKEN_PLUS" (global $TOKEN_PLUS i32))
  (import "lexer_tokens" "TOKEN_MINUS" (global $TOKEN_MINUS i32))
  (import "lexer_tokens" "TOKEN_MULTIPLY" (global $TOKEN_MULTIPLY i32))
  (import "lexer_tokens" "TOKEN_DIVIDE" (global $TOKEN_DIVIDE i32))
  (import "lexer_tokens" "TOKEN_MODULO" (global $TOKEN_MODULO i32))

  ;; Import memory layout constants
  (import "lexer_memory" "TOKEN_ARRAY_START" (global $TOKEN_ARRAY_START i32))
  (import "lexer_memory" "TOKEN_RECORD_SIZE" (global $TOKEN_RECORD_SIZE i32))
  (import "lexer_memory" "TOKEN_TYPE_OFFSET" (global $TOKEN_TYPE_OFFSET i32))
  (import "lexer_memory" "TOKEN_START_OFFSET" (global $TOKEN_START_OFFSET i32))
  (import "lexer_memory" "TOKEN_LINE_OFFSET" (global $TOKEN_LINE_OFFSET i32))
  (import "lexer_memory" "TOKEN_COLUMN_OFFSET" (global $TOKEN_COLUMN_OFFSET i32))

  ;; Import lexer functions
  (import "novo_lexer" "next_token" (func $next_token (param i32) (result i32 i32)))

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

  ;; Test: Basic Mathematical Operators
  (func $test_basic_operators
    (local $pos i32)
    (local $token_idx i32)
    (local $next_pos i32)

    ;; Test input: "a + b - c * d / e % f"
    (i32.store8 (i32.const 0) (i32.const 0x61)) ;; a
    (i32.store8 (i32.const 1) (i32.const 0x20)) ;; space
    (i32.store8 (i32.const 2) (i32.const 0x2b)) ;; +
    (i32.store8 (i32.const 3) (i32.const 0x20)) ;; space
    (i32.store8 (i32.const 4) (i32.const 0x62)) ;; b
    (i32.store8 (i32.const 5) (i32.const 0x20)) ;; space
    (i32.store8 (i32.const 6) (i32.const 0x2d)) ;; -
    (i32.store8 (i32.const 7) (i32.const 0x20)) ;; space
    (i32.store8 (i32.const 8) (i32.const 0x63)) ;; c
    (i32.store8 (i32.const 9) (i32.const 0x20)) ;; space
    (i32.store8 (i32.const 10) (i32.const 0x2a)) ;; *
    (i32.store8 (i32.const 11) (i32.const 0x20)) ;; space
    (i32.store8 (i32.const 12) (i32.const 0x64)) ;; d
    (i32.store8 (i32.const 13) (i32.const 0x20)) ;; space
    (i32.store8 (i32.const 14) (i32.const 0x2f)) ;; /
    (i32.store8 (i32.const 15) (i32.const 0x20)) ;; space
    (i32.store8 (i32.const 16) (i32.const 0x65)) ;; e
    (i32.store8 (i32.const 17) (i32.const 0x20)) ;; space
    (i32.store8 (i32.const 18) (i32.const 0x25)) ;; %
    (i32.store8 (i32.const 19) (i32.const 0x20)) ;; space
    (i32.store8 (i32.const 20) (i32.const 0x66)) ;; f

    ;; Reset position
    (local.set $pos (i32.const 0))
    (local.set $token_idx (i32.const 0))

    ;; Test identifier "a"
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

    ;; Test + operator
    (call $next_token (local.get $pos))
    (local.set $token_idx)
    (local.set $next_pos)
    (call $assert_token (local.get $token_idx) (global.get $TOKEN_PLUS) (i32.const 1) (i32.const 3))
    (local.set $pos (local.get $next_pos))
  )

  ;; Test: Kebab-case vs Minus Operator
  (func $test_kebab_minus
    (local $pos i32)
    (local $token_idx i32)
    (local $next_pos i32)

    ;; Test input: "my-var   a - b"
    (i32.store8 (i32.const 0) (i32.const 0x6d)) ;; m
    (i32.store8 (i32.const 1) (i32.const 0x79)) ;; y
    (i32.store8 (i32.const 2) (i32.const 0x2d)) ;; -
    (i32.store8 (i32.const 3) (i32.const 0x76)) ;; v
    (i32.store8 (i32.const 4) (i32.const 0x61)) ;; a
    (i32.store8 (i32.const 5) (i32.const 0x72)) ;; r
    (i32.store8 (i32.const 6) (i32.const 0x20)) ;; space
    (i32.store8 (i32.const 7) (i32.const 0x20)) ;; space
    (i32.store8 (i32.const 8) (i32.const 0x20)) ;; space
    (i32.store8 (i32.const 9) (i32.const 0x61)) ;; a
    (i32.store8 (i32.const 10) (i32.const 0x20)) ;; space
    (i32.store8 (i32.const 11) (i32.const 0x2d)) ;; -
    (i32.store8 (i32.const 12) (i32.const 0x20)) ;; space
    (i32.store8 (i32.const 13) (i32.const 0x62)) ;; b

    ;; Reset position
    (local.set $pos (i32.const 0))
    (local.set $token_idx (i32.const 0))

    ;; Test identifier "my-var"
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

    ;; Test identifier "a"
    (call $next_token (local.get $pos))
    (local.set $token_idx)
    (local.set $next_pos)
    (call $assert_token (local.get $token_idx) (global.get $TOKEN_IDENTIFIER) (i32.const 1) (i32.const 10))
    (local.set $pos (local.get $next_pos))

    ;; Skip whitespace
    (call $next_token (local.get $pos))
    (local.set $token_idx)
    (local.set $next_pos)
    (local.set $pos (local.get $next_pos))

    ;; Test minus operator
    (call $next_token (local.get $pos))
    (local.set $token_idx)
    (local.set $next_pos)
    (call $assert_token (local.get $token_idx) (global.get $TOKEN_MINUS) (i32.const 1) (i32.const 12))
    (local.set $pos (local.get $next_pos))
  )

  ;; Test: Required Spacing Errors
  (func $test_spacing_errors
    (local $pos i32)
    (local $token_idx i32)
    (local $next_pos i32)

    ;; Test input: "a+b a- b a *b"
    (i32.store8 (i32.const 0) (i32.const 0x61)) ;; a
    (i32.store8 (i32.const 1) (i32.const 0x2b)) ;; +
    (i32.store8 (i32.const 2) (i32.const 0x62)) ;; b
    (i32.store8 (i32.const 3) (i32.const 0x20)) ;; space
    (i32.store8 (i32.const 4) (i32.const 0x61)) ;; a
    (i32.store8 (i32.const 5) (i32.const 0x2d)) ;; -
    (i32.store8 (i32.const 6) (i32.const 0x20)) ;; space
    (i32.store8 (i32.const 7) (i32.const 0x62)) ;; b
    (i32.store8 (i32.const 8) (i32.const 0x20)) ;; space
    (i32.store8 (i32.const 9) (i32.const 0x61)) ;; a
    (i32.store8 (i32.const 10) (i32.const 0x20)) ;; space
    (i32.store8 (i32.const 11) (i32.const 0x2a)) ;; *
    (i32.store8 (i32.const 12) (i32.const 0x62)) ;; b

    ;; Reset position
    (local.set $pos (i32.const 0))
    (local.set $token_idx (i32.const 0))

    ;; Test identifier "a"
    (call $next_token (local.get $pos))
    (local.set $token_idx)
    (local.set $next_pos)
    (call $assert_token (local.get $token_idx) (global.get $TOKEN_IDENTIFIER) (i32.const 1) (i32.const 1))
    (local.set $pos (local.get $next_pos))

    ;; Test + without required space (should be error)
    (call $next_token (local.get $pos))
    (local.set $token_idx)
    (local.set $next_pos)
    (call $assert_token (local.get $token_idx) (global.get $TOKEN_ERROR) (i32.const 1) (i32.const 2))
  )

  (export "test_basic_operators" (func $test_basic_operators))
  (export "test_kebab_minus" (func $test_kebab_minus))
  (export "test_spacing_errors" (func $test_spacing_errors))
)
