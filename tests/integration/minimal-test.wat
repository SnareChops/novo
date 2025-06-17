;; Minimal test - just tokenize "4"
(module $minimal_test
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import lexer functions
  (import "novo_lexer" "next_token" (func $next_token (param i32) (result i32 i32)))

  ;; Memory layout constants for token access
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

  ;; Test function - call next_token and check result
  (func $test_minimal (export "_start")
    (local $token_idx i32)
    (local $next_pos i32)
    (local $token_type i32)
    (local $pos i32)

    ;; Write test input to memory: "42"
    (i32.store8 (i32.const 0) (i32.const 0x34))  ;; '4'
    (i32.store8 (i32.const 1) (i32.const 0x32))  ;; '2'
    (i32.store8 (i32.const 2) (i32.const 0x00))  ;; null terminator

    (local.set $pos (i32.const 0))

    ;; Get first token
    (call $next_token (local.get $pos))
    (local.set $next_pos)
    (local.set $token_idx)

    ;; Get the token type
    (local.set $token_type (call $get_token_type (local.get $token_idx)))

    ;; Store token type for debugging
    (i32.store (i32.const 100) (local.get $token_type))
    (i32.store (i32.const 104) (local.get $next_pos))

    ;; If token type is 9 (WHITESPACE), try next token
    (if (i32.eq (local.get $token_type) (i32.const 9))
      (then
        (local.set $pos (local.get $next_pos))
        (call $next_token (local.get $pos))
        (local.set $next_pos)
        (local.set $token_idx)
        (local.set $token_type (call $get_token_type (local.get $token_idx)))

        ;; Store second token type
        (i32.store (i32.const 108) (local.get $token_type))
      )
    )

    ;; If we get token type 54 (NUMBER_LITERAL), test passes
    (if (i32.eq (local.get $token_type) (i32.const 54))
      (then
        ;; Success
        (return)
      )
    )

    ;; Otherwise, fail with the token type as error code
    (i32.store (i32.const 112) (local.get $token_type))
    (unreachable)
  )
)
