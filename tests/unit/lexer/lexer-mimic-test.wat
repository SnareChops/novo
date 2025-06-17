;; Minimal lexer mimic - step by step exactly like the real lexer
(module $lexer_mimic_test
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import all functions used by lexer
  (import "char_utils" "is_whitespace" (func $is_whitespace (param i32) (result i32)))
  (import "char_utils" "is_digit" (func $is_digit (param i32) (result i32)))
  (import "char_utils" "skip_whitespace" (func $skip_whitespace (param i32) (result i32)))

  ;; Import memory tracking functions
  (import "lexer_memory" "update_position" (func $update_position (param i32)))

  ;; Import space tracking functions
  (import "lexer_operators" "update_space_tracking" (func $update_space_tracking (param i32)))

  ;; Import token storage
  (import "lexer_token_storage" "store_token" (func $store_token (param i32 i32) (result i32)))

  ;; Import tokens
  (import "lexer_tokens" "TOKEN_EOF" (global $TOKEN_EOF i32))
  (import "lexer_tokens" "TOKEN_WHITESPACE" (global $TOKEN_WHITESPACE i32))
  (import "lexer_tokens" "TOKEN_NUMBER_LITERAL" (global $TOKEN_NUMBER_LITERAL i32))
  (import "lexer_tokens" "TOKEN_ERROR" (global $TOKEN_ERROR i32))

  ;; Mimic scan_number
  (func $scan_number (param $pos i32) (result i32)
    (local $current_pos i32)
    (local $char i32)

    (local.set $current_pos (local.get $pos))

    ;; Skip digits
    (loop $scan_digits
      (local.set $char (i32.load8_u (local.get $current_pos)))

      (if (call $is_digit (local.get $char))
        (then
          (local.set $current_pos (i32.add (local.get $current_pos) (i32.const 1)))
          (br $scan_digits)
        )
      )
    )

    (local.get $current_pos)
  )

  ;; Mimic next_token exactly
  (func $next_token (param $pos i32) (result i32 i32)
    (local $char i32)
    (local $start_pos i32)
    (local $token_idx i32)
    (local $next_pos i32)
    (local $token_type i32)

    ;; Store starting position
    (local.set $start_pos (local.get $pos))

    ;; Read current character
    (local.set $char (i32.load8_u (local.get $pos)))

    ;; Handle EOF
    (if (i32.eqz (local.get $char))
      (then
        (local.set $token_idx
          (call $store_token
            (global.get $TOKEN_EOF)
            (local.get $pos)
          )
        )
        (return (local.get $token_idx) (local.get $pos))
      )
    )

    ;; Update position tracking for this character
    (call $update_position (local.get $char))
    (call $update_space_tracking (local.get $char))

    (block $token_handled
      ;; Handle whitespace
      (if (call $is_whitespace (local.get $char))
        (then
          (local.set $next_pos (call $skip_whitespace (local.get $pos)))
          (local.set $token_idx
            (call $store_token
              (global.get $TOKEN_WHITESPACE)
              (local.get $pos)
            )
          )
          (br $token_handled)
        )
      )

      ;; Handle number literals
      (if (call $is_digit (local.get $char))
        (then
          (local.set $next_pos (call $scan_number (local.get $pos)))
          (local.set $token_idx
            (call $store_token
              (global.get $TOKEN_NUMBER_LITERAL)
              (local.get $pos)
            )
          )
          (br $token_handled)
        )
      )

      ;; If we get here, character is unknown
      (local.set $token_idx
        (call $store_token
          (global.get $TOKEN_ERROR)
          (local.get $pos)
        )
      )
      (local.set $next_pos
        (i32.add (local.get $pos) (i32.const 1))
      )
    )

    ;; Return token index and next position
    (return (local.get $token_idx) (local.get $next_pos))
  )

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
  (func $test_lexer_mimic (export "_start")
    (local $token_idx i32)
    (local $next_pos i32)
    (local $token_type i32)

    ;; Write test input: "4"
    (i32.store8 (i32.const 0) (i32.const 0x34))  ;; '4'
    (i32.store8 (i32.const 1) (i32.const 0x00))  ;; null terminator

    ;; Call our mimic function
    (call $next_token (i32.const 0))
    (local.set $next_pos)
    (local.set $token_idx)

    ;; Check what token type we got
    (local.set $token_type (call $get_token_type (local.get $token_idx)))

    ;; Fail if we didn't get TOKEN_NUMBER_LITERAL
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_NUMBER_LITERAL))
      (then
        (unreachable)  ;; This will cause wasmtime to report failure
      )
    )

    ;; If we reach here, test passed
  )
)
