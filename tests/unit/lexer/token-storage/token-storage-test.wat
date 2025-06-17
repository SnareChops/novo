;; Test token storage directly
(module $token_storage_test
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import token storage
  (import "lexer_token_storage" "store_token" (func $store_token (param i32 i32) (result i32)))

  ;; Import tokens
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
  (func $test_token_storage (export "_start")
    (local $token_idx i32)
    (local $stored_token_type i32)
    (local $expected_token_type i32)

    ;; Get expected token type
    (local.set $expected_token_type (global.get $TOKEN_NUMBER_LITERAL))

    ;; Store a token
    (local.set $token_idx
      (call $store_token
        (local.get $expected_token_type)
        (i32.const 0)  ;; start position
      )
    )

    ;; Read back the token type
    (local.set $stored_token_type (call $get_token_type (local.get $token_idx)))

    ;; Check if they match
    (if (i32.ne (local.get $stored_token_type) (local.get $expected_token_type))
      (then
        (unreachable)  ;; Fail - token storage/retrieval is broken
      )
    )

    ;; Test passed
  )
)
