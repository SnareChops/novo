;; Debug test - see what token we actually get for "4"
(module $debug_token_test
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

  ;; Test function - just get token and fail with token type as error code
  (func $test_debug (export "_start")
    (local $token_idx i32)
    (local $next_pos i32)
    (local $token_type i32)

    ;; Write test input: "4"
    (i32.store8 (i32.const 0) (i32.const 0x34))  ;; '4'
    (i32.store8 (i32.const 1) (i32.const 0x00))  ;; null terminator

    ;; Get first token (start at position 0)
    (call $next_token (i32.const 0))
    (local.set $next_pos)
    (local.set $token_idx)

    ;; Get token type
    (local.set $token_type (call $get_token_type (local.get $token_idx)))

    ;; Store results for inspection AND then fail with token type info
    (i32.store (i32.const 200) (local.get $token_type))   ;; Actual token type
    (i32.store (i32.const 204) (i32.const 54))           ;; Expected token type

    ;; If token type is 54 (NUMBER_LITERAL), pass
    (if (i32.eq (local.get $token_type) (i32.const 54))
      (then (return))
    )

    ;; Otherwise fail - but the memory values will show what we got vs expected
    (unreachable)
  )
)
