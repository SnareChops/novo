;; Comprehensive test for is_valid_identifier_start function
(module $is_valid_identifier_start_test
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import is_valid_identifier_start
  (import "char_utils" "is_valid_identifier_start" (func $is_valid_identifier_start (param i32) (result i32)))

  ;; Test function
  (func $test_is_valid_identifier_start (export "_start")
    (local $result i32)

    ;; Test lowercase letters (should return true)
    (local.set $result (call $is_valid_identifier_start (i32.const 97)))  ;; 'a'
    (if (i32.eqz (local.get $result))
      (then (unreachable))  ;; Fail - 'a' should be valid identifier start
    )

    (local.set $result (call $is_valid_identifier_start (i32.const 122))) ;; 'z'
    (if (i32.eqz (local.get $result))
      (then (unreachable))  ;; Fail - 'z' should be valid identifier start
    )

    (local.set $result (call $is_valid_identifier_start (i32.const 109))) ;; 'm'
    (if (i32.eqz (local.get $result))
      (then (unreachable))  ;; Fail - 'm' should be valid identifier start
    )

    ;; Test % sign (should return true - for special identifiers)
    (local.set $result (call $is_valid_identifier_start (i32.const 0x25))) ;; '%'
    (if (i32.eqz (local.get $result))
      (then (unreachable))  ;; Fail - '%' should be valid identifier start
    )

    ;; Test invalid characters (should return false)
    (local.set $result (call $is_valid_identifier_start (i32.const 65)))  ;; 'A' (uppercase)
    (if (local.get $result)
      (then (unreachable))  ;; Fail - 'A' should not be valid identifier start
    )

    (local.set $result (call $is_valid_identifier_start (i32.const 48)))  ;; '0' (digit)
    (if (local.get $result)
      (then (unreachable))  ;; Fail - '0' should not be valid identifier start
    )

    (local.set $result (call $is_valid_identifier_start (i32.const 57)))  ;; '9' (digit)
    (if (local.get $result)
      (then (unreachable))  ;; Fail - '9' should not be valid identifier start
    )

    (local.set $result (call $is_valid_identifier_start (i32.const 45)))  ;; '-'
    (if (local.get $result)
      (then (unreachable))  ;; Fail - '-' should not be valid identifier start
    )

    (local.set $result (call $is_valid_identifier_start (i32.const 32)))  ;; space
    (if (local.get $result)
      (then (unreachable))  ;; Fail - space should not be valid identifier start
    )

    (local.set $result (call $is_valid_identifier_start (i32.const 95)))  ;; '_'
    (if (local.get $result)
      (then (unreachable))  ;; Fail - '_' should not be valid identifier start
    )

    (local.set $result (call $is_valid_identifier_start (i32.const 43)))  ;; '+'
    (if (local.get $result)
      (then (unreachable))  ;; Fail - '+' should not be valid identifier start
    )

    (local.set $result (call $is_valid_identifier_start (i32.const 42)))  ;; '*'
    (if (local.get $result)
      (then (unreachable))  ;; Fail - '*' should not be valid identifier start
    )

    ;; Test boundary cases
    (local.set $result (call $is_valid_identifier_start (i32.const 96)))  ;; '`' (before 'a')
    (if (local.get $result)
      (then (unreachable))  ;; Fail - '`' should not be valid identifier start
    )

    (local.set $result (call $is_valid_identifier_start (i32.const 123))) ;; '{' (after 'z')
    (if (local.get $result)
      (then (unreachable))  ;; Fail - '{' should not be valid identifier start
    )

    ;; Test other special characters that should not be valid
    (local.set $result (call $is_valid_identifier_start (i32.const 0x24))) ;; '$'
    (if (local.get $result)
      (then (unreachable))  ;; Fail - '$' should not be valid identifier start
    )

    (local.set $result (call $is_valid_identifier_start (i32.const 0x26))) ;; '&'
    (if (local.get $result)
      (then (unreachable))  ;; Fail - '&' should not be valid identifier start
    )

    ;; Test passed
  )
)
