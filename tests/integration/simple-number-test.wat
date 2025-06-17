;; Simple focused test - verify if lexer recognizes '4' as number literal
(module $simple_number_test
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import lexer functions
  (import "novo_lexer" "next_token" (func $next_token (param i32) (result i32 i32)))

  ;; Import token constants
  (import "lexer_tokens" "TOKEN_NUMBER_LITERAL" (global $TOKEN_NUMBER_LITERAL i32))
  (import "lexer_tokens" "TOKEN_EOF" (global $TOKEN_EOF i32))

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

  ;; Test function
  (func $test_single_digit (export "_start")
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

    ;; Check what token type we got
    (local.set $token_type (call $get_token_type (local.get $token_idx)))

    ;; Fail if we didn't get TOKEN_NUMBER_LITERAL (54)
    (if (i32.ne (local.get $token_type) (i32.const 54))
      (then
        (unreachable)  ;; This will cause wasmtime to report failure
      )
    )

    ;; If we reach here, test passed
  )
)
