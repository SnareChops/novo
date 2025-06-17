;; Test to see the exact token type value
(module $token_value_test
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import lexer functions
  (import "novo_lexer" "next_token" (func $next_token (param i32) (result i32 i32)))

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
  (func $test_token_value (export "_start")
    (local $token_idx i32)
    (local $next_pos i32)
    (local $token_type i32)

    ;; Write test input: "4"
    (i32.store8 (i32.const 0) (i32.const 0x34))  ;; '4'
    (i32.store8 (i32.const 1) (i32.const 0x00))  ;; null terminator

    ;; Call lexer
    (call $next_token (i32.const 0))
    (local.set $next_pos)
    (local.set $token_idx)

    ;; Read back the token type
    (local.set $token_type (call $get_token_type (local.get $token_idx)))

    ;; Use token_type value to cause different errors for diagnosis
    ;; If token_type is 0 (TOKEN_ERROR), cause specific error
    (if (i32.eqz (local.get $token_type))
      (then
        (i32.store8 (i32.const 999999) (i32.const 1))  ;; TOKEN_ERROR (0)
      )
    )

    ;; If token_type is 54 (TOKEN_NUMBER_LITERAL), pass
    (if (i32.eq (local.get $token_type) (i32.const 54))
      (then
        (return)  ;; Success
      )
    )

    ;; If token_type is some other specific values, cause specific errors
    (if (i32.eq (local.get $token_type) (i32.const 1))
      (then
        (i32.store8 (i32.const 999998) (i32.const 1))  ;; Value 1
      )
    )

    (if (i32.eq (local.get $token_type) (i32.const 10))
      (then
        (i32.store8 (i32.const 999997) (i32.const 1))  ;; Value 10 (TOKEN_EOF)
      )
    )

    ;; Default case - unknown value
    (unreachable)
  )
)
