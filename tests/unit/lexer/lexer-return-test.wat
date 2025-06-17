;; Test lexer without token storage - just check the return values directly
(module $lexer_return_test
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import lexer functions
  (import "novo_lexer" "next_token" (func $next_token (param i32) (result i32 i32)))

  ;; Test function
  (func $test_lexer_returns (export "_start")
    (local $token_idx i32)
    (local $next_pos i32)

    ;; Write test input: "4"
    (i32.store8 (i32.const 0) (i32.const 0x34))  ;; '4'
    (i32.store8 (i32.const 1) (i32.const 0x00))  ;; null terminator

    ;; Call lexer
    (call $next_token (i32.const 0))
    (local.set $next_pos)
    (local.set $token_idx)

    ;; Check if token_idx is reasonable (should be 0 for first token)
    ;; If token_idx is some huge number, that suggests an issue
    (if (i32.gt_u (local.get $token_idx) (i32.const 1000))
      (then
        (unreachable)  ;; Fail - token_idx is unreasonably large
      )
    )

    ;; Check if next_pos is reasonable (should be 1)
    (if (i32.ne (local.get $next_pos) (i32.const 1))
      (then
        ;; Different failure for wrong next_pos
        (i32.store8 (i32.const 999999) (i32.const 1))  ;; Out-of-bounds = wrong next_pos
      )
    )

    ;; If we reach here, the basic return values look reasonable
  )
)
