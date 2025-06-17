;; Comprehensive test for scan_colon_op function
(module $scan_colon_op_test
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import token constants
  (import "tokens" "TOKEN_COLON" (global $TOKEN_COLON i32))
  (import "tokens" "TOKEN_ASSIGN" (global $TOKEN_ASSIGN i32))
  (import "tokens" "TOKEN_META" (global $TOKEN_META i32))

  ;; Import scan_colon_op
  (import "operators" "scan_colon_op" (func $scan_colon_op (param i32) (result i32 i32)))

  ;; Test function
  (func $test_scan_colon_op (export "_start")
    (local $token_type i32)
    (local $next_pos i32)

    ;; Test single colon ":"
    (i32.store8 (i32.const 0) (i32.const 0x3a))  ;; ':'
    (i32.store8 (i32.const 1) (i32.const 0x20))  ;; space (not = or :)
    (call $scan_colon_op (i32.const 0))
    (local.set $next_pos)
    (local.set $token_type)
    ;; Should return TOKEN_COLON and position 1
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_COLON))
      (then (unreachable))  ;; Fail - should return TOKEN_COLON
    )
    (if (i32.ne (local.get $next_pos) (i32.const 1))
      (then (unreachable))  ;; Fail - should advance by 1
    )

    ;; Test assignment ":="
    (i32.store8 (i32.const 10) (i32.const 0x3a)) ;; ':'
    (i32.store8 (i32.const 11) (i32.const 0x3d)) ;; '='
    (call $scan_colon_op (i32.const 10))
    (local.set $next_pos)
    (local.set $token_type)
    ;; Should return TOKEN_ASSIGN and position 12
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_ASSIGN))
      (then (unreachable))  ;; Fail - should return TOKEN_ASSIGN
    )
    (if (i32.ne (local.get $next_pos) (i32.const 12))
      (then (unreachable))  ;; Fail - should advance by 2
    )

    ;; Test meta operator "::"
    (i32.store8 (i32.const 20) (i32.const 0x3a)) ;; ':'
    (i32.store8 (i32.const 21) (i32.const 0x3a)) ;; ':'
    (call $scan_colon_op (i32.const 20))
    (local.set $next_pos)
    (local.set $token_type)
    ;; Should return TOKEN_META and position 22
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_META))
      (then (unreachable))  ;; Fail - should return TOKEN_META
    )
    (if (i32.ne (local.get $next_pos) (i32.const 22))
      (then (unreachable))  ;; Fail - should advance by 2
    )

    ;; Test colon at end of input (null terminator)
    (i32.store8 (i32.const 30) (i32.const 0x3a)) ;; ':'
    (i32.store8 (i32.const 31) (i32.const 0x00)) ;; null
    (call $scan_colon_op (i32.const 30))
    (local.set $next_pos)
    (local.set $token_type)
    ;; Should return TOKEN_COLON and position 31
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_COLON))
      (then (unreachable))  ;; Fail - should return TOKEN_COLON
    )
    (if (i32.ne (local.get $next_pos) (i32.const 31))
      (then (unreachable))  ;; Fail - should advance by 1
    )

    ;; Test colon followed by different character ":+"
    (i32.store8 (i32.const 40) (i32.const 0x3a)) ;; ':'
    (i32.store8 (i32.const 41) (i32.const 0x2b)) ;; '+'
    (call $scan_colon_op (i32.const 40))
    (local.set $next_pos)
    (local.set $token_type)
    ;; Should return TOKEN_COLON and position 41
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_COLON))
      (then (unreachable))  ;; Fail - should return TOKEN_COLON
    )
    (if (i32.ne (local.get $next_pos) (i32.const 41))
      (then (unreachable))  ;; Fail - should advance by 1
    )

    ;; Test passed
  )
)
