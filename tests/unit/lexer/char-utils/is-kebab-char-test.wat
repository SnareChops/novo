;; Comprehensive test for is_kebab_char function
(module $is_kebab_char_test
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import is_kebab_char
  (import "char_utils" "is_kebab_char" (func $is_kebab_char (param i32) (result i32)))

  ;; Test function
  (func $test_is_kebab_char (export "_start")
    (local $result i32)

    ;; Test lowercase letters (should return true)
    (local.set $result (call $is_kebab_char (i32.const 97)))  ;; 'a'
    (if (i32.eqz (local.get $result))
      (then (unreachable))  ;; Fail - 'a' should be kebab char
    )

    (local.set $result (call $is_kebab_char (i32.const 122))) ;; 'z'
    (if (i32.eqz (local.get $result))
      (then (unreachable))  ;; Fail - 'z' should be kebab char
    )

    (local.set $result (call $is_kebab_char (i32.const 109))) ;; 'm'
    (if (i32.eqz (local.get $result))
      (then (unreachable))  ;; Fail - 'm' should be kebab char
    )

    ;; Test digits (should return true)
    (local.set $result (call $is_kebab_char (i32.const 48)))  ;; '0'
    (if (i32.eqz (local.get $result))
      (then (unreachable))  ;; Fail - '0' should be kebab char
    )

    (local.set $result (call $is_kebab_char (i32.const 57)))  ;; '9'
    (if (i32.eqz (local.get $result))
      (then (unreachable))  ;; Fail - '9' should be kebab char
    )

    (local.set $result (call $is_kebab_char (i32.const 53)))  ;; '5'
    (if (i32.eqz (local.get $result))
      (then (unreachable))  ;; Fail - '5' should be kebab char
    )

    ;; Test hyphen/dash (should return true)
    (local.set $result (call $is_kebab_char (i32.const 45)))  ;; '-'
    (if (i32.eqz (local.get $result))
      (then (unreachable))  ;; Fail - '-' should be kebab char
    )

    ;; Test invalid characters (should return false)
    (local.set $result (call $is_kebab_char (i32.const 65)))  ;; 'A' (uppercase)
    (if (local.get $result)
      (then (unreachable))  ;; Fail - 'A' should not be kebab char
    )

    (local.set $result (call $is_kebab_char (i32.const 32)))  ;; space
    (if (local.get $result)
      (then (unreachable))  ;; Fail - space should not be kebab char
    )

    (local.set $result (call $is_kebab_char (i32.const 43)))  ;; '+'
    (if (local.get $result)
      (then (unreachable))  ;; Fail - '+' should not be kebab char
    )

    (local.set $result (call $is_kebab_char (i32.const 95)))  ;; '_'
    (if (local.get $result)
      (then (unreachable))  ;; Fail - '_' should not be kebab char
    )

    (local.set $result (call $is_kebab_char (i32.const 46)))  ;; '.'
    (if (local.get $result)
      (then (unreachable))  ;; Fail - '.' should not be kebab char
    )

    ;; Test boundary cases
    (local.set $result (call $is_kebab_char (i32.const 96)))  ;; '`' (before 'a')
    (if (local.get $result)
      (then (unreachable))  ;; Fail - '`' should not be kebab char
    )

    (local.set $result (call $is_kebab_char (i32.const 123))) ;; '{' (after 'z')
    (if (local.get $result)
      (then (unreachable))  ;; Fail - '{' should not be kebab char
    )

    (local.set $result (call $is_kebab_char (i32.const 47)))  ;; '/' (before '0')
    (if (local.get $result)
      (then (unreachable))  ;; Fail - '/' should not be kebab char
    )

    (local.set $result (call $is_kebab_char (i32.const 58)))  ;; ':' (after '9')
    (if (local.get $result)
      (then (unreachable))  ;; Fail - ':' should not be kebab char
    )

    ;; Test passed
  )
)
