;; Novo Parser Utilities
;; Shared utility functions for all parser modules

(module $novo_parser_utils
  ;; Import memory from lexer memory module
  (import "lexer_memory" "memory" (memory 1))

  ;; Memory layout constants
  (global $TOKEN_ARRAY_START i32 (i32.const 2048))
  (global $TOKEN_RECORD_SIZE i32 (i32.const 16))
  (global $TOKEN_TYPE_OFFSET i32 (i32.const 0))
  (global $TOKEN_START_OFFSET i32 (i32.const 4))

  ;; Helper function to get token type from token index
  (func $get_token_type (export "get_token_type") (param $token_idx i32) (result i32)
    (local $token_offset i32)

    (local.set $token_offset
      (i32.add
        (global.get $TOKEN_ARRAY_START)
        (i32.mul (local.get $token_idx) (global.get $TOKEN_RECORD_SIZE))
      )
    )

    (i32.load (local.get $token_offset))
  )

  ;; Helper function to get token start position from token index
  (func $get_token_start (export "get_token_start") (param $token_idx i32) (result i32)
    (local $token_offset i32)

    (local.set $token_offset
      (i32.add
        (global.get $TOKEN_ARRAY_START)
        (i32.mul (local.get $token_idx) (global.get $TOKEN_RECORD_SIZE))
      )
    )

    (i32.load offset=4 (local.get $token_offset))
  )

  ;; Helper function to get token length from token index
  (func $get_token_length (export "get_token_length") (param $token_idx i32) (result i32)
    (local $token_offset i32)

    (local.set $token_offset
      (i32.add
        (global.get $TOKEN_ARRAY_START)
        (i32.mul (local.get $token_idx) (global.get $TOKEN_RECORD_SIZE))
      )
    )

    (i32.load offset=8 (local.get $token_offset))
  )
)
