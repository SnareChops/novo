;; Novo Lexer Token Storage
;; Functions for storing and managing tokens

(module $novo_lexer_token_storage
  ;; Import memory from memory module
  (import "memory" "memory" (memory 1))

  ;; Import memory globals and utility functions
  (import "memory" "TOKEN_ARRAY_START" (global $TOKEN_ARRAY_START i32))
  (import "memory" "TOKEN_RECORD_SIZE" (global $TOKEN_RECORD_SIZE i32))
  (import "memory" "TOKEN_TYPE_OFFSET" (global $TOKEN_TYPE_OFFSET i32))
  (import "memory" "TOKEN_START_OFFSET" (global $TOKEN_START_OFFSET i32))
  (import "memory" "TOKEN_LINE_OFFSET" (global $TOKEN_LINE_OFFSET i32))
  (import "memory" "TOKEN_COLUMN_OFFSET" (global $TOKEN_COLUMN_OFFSET i32))
  (import "memory" "current_line" (global $current_line (mut i32)))
  (import "memory" "current_col" (global $current_col (mut i32)))
  (import "memory" "token_count" (global $token_count (mut i32)))

  ;; Store a token in the token array
  (func $store_token (param $type i32) (param $start i32) (result i32)
    (local $token_offset i32)

    ;; Calculate offset in token array
    (local.set $token_offset
      (i32.add
        (global.get $TOKEN_ARRAY_START)
        (i32.mul
          (global.get $token_count)
          (global.get $TOKEN_RECORD_SIZE)
        )
      )
    )

    ;; Store token fields
    (i32.store (i32.add (local.get $token_offset) (global.get $TOKEN_TYPE_OFFSET))
              (local.get $type))
    (i32.store (i32.add (local.get $token_offset) (global.get $TOKEN_START_OFFSET))
              (local.get $start))
    (i32.store (i32.add (local.get $token_offset) (global.get $TOKEN_LINE_OFFSET))
              (global.get $current_line))
    (i32.store (i32.add (local.get $token_offset) (global.get $TOKEN_COLUMN_OFFSET))
              (global.get $current_col))

    ;; Increment token count
    (global.set $token_count
      (i32.add (global.get $token_count) (i32.const 1))
    )

    ;; Return token index
    (i32.sub (global.get $token_count) (i32.const 1))
  )

  ;; Store an identifier in the token array
  (func $store_identifier (param $start i32) (param $len i32) (result i32)
    (local $token_offset i32)

    ;; Calculate offset in token array
    (local.set $token_offset
      (i32.add
        (global.get $TOKEN_ARRAY_START)
        (i32.mul
          (global.get $token_count)
          (global.get $TOKEN_RECORD_SIZE)
        )
      )
    )

    ;; Store identifier fields
    (i32.store (i32.add (local.get $token_offset) (global.get $TOKEN_TYPE_OFFSET))
              (i32.const 1)) ;; Assuming type 1 is for identifiers
    (i32.store (i32.add (local.get $token_offset) (global.get $TOKEN_START_OFFSET))
              (local.get $start))
    (i32.store (i32.add (local.get $token_offset) (global.get $TOKEN_LINE_OFFSET))
              (global.get $current_line))
    (i32.store (i32.add (local.get $token_offset) (global.get $TOKEN_COLUMN_OFFSET))
              (global.get $current_col))

    ;; Increment token count
    (global.set $token_count
      (i32.add (global.get $token_count) (i32.const 1))
    )

    ;; Return token index
    (i32.sub (global.get $token_count) (i32.const 1))
  )

  ;; Export token storage functions
  (export "store_token" (func $store_token))
  (export "store_identifier" (func $store_identifier))
)
