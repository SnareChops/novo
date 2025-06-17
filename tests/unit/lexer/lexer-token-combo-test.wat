;; Test lexer + token retrieval combination
(module $lexer_token_combo_test
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import lexer functions
  (import "novo_lexer" "next_token" (func $next_token (param i32) (result i32 i32)))

  ;; Import tokens for comparison
  (import "lexer_tokens" "TOKEN_NUMBER_LITERAL" (global $TOKEN_NUMBER_LITERAL i32))

  ;; Memory layout constants
  (global $TOKEN_ARRAY_START i32 (i32.const 2048))
  (global $TOKEN_RECORD_SIZE i32 (i32.const 16))

  ;; Helper function to get token type from token index
  (func $get_token_type (param $token_idx i32) (result i32)
    (local $token_offset i32)

    (local.set $token_offset
      (i32.add
        (global.get $TOKEN_ARRAY_START)
        (i32.mul (local.get $token_idx) (global.get $TOKEN_RECORD_SIZE))
      )
    )

    (i32.load (local.get $token_offset))
  )

  ;; Test function
  (func $test_lexer_token_combo (export "_start")
    (local $token_idx i32)
    (local $next_pos i32)
    (local $token_type i32)
    (local $expected_token_type i32)

    ;; Write test input: "4"
    (i32.store8 (i32.const 0) (i32.const 0x34))  ;; '4'
    (i32.store8 (i32.const 1) (i32.const 0x00))  ;; null terminator

    ;; Get expected token type
    (local.set $expected_token_type (global.get $TOKEN_NUMBER_LITERAL))

    ;; Call lexer
    (call $next_token (i32.const 0))
    (local.set $next_pos)
    (local.set $token_idx)

    ;; Read back the token type
    (local.set $token_type (call $get_token_type (local.get $token_idx)))

    ;; Debug: Check token_idx value first
    (if (i32.ne (local.get $token_idx) (i32.const 0))
      (then
        ;; Wrong token index
        (i32.store8 (i32.const 999999) (i32.const 1))  ;; token_idx issue
      )
    )

    ;; Debug: Check next_pos value
    (if (i32.ne (local.get $next_pos) (i32.const 1))
      (then
        ;; Wrong next position
        (i32.store8 (i32.const 999998) (i32.const 1))  ;; next_pos issue
      )
    )

    ;; Main test: Check token type
    (if (i32.ne (local.get $token_type) (local.get $expected_token_type))
      (then
        ;; Wrong token type - this is our main issue
        (unreachable)  ;; token_type issue
      )
    )

    ;; Test passed
  )
)
