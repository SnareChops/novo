;; Parser Utility Functions Test
;; Tests the parser utility functions for token manipulation

(module $parser_utils_test
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import functions to test
  (import "parser_utils" "get_token_type" (func $get_token_type (param i32) (result i32)))
  (import "parser_utils" "get_token_start" (func $get_token_start (param i32) (result i32)))
  (import "parser_utils" "get_token_length" (func $get_token_length (param i32) (result i32)))

  ;; Import token constants for testing
  (import "lexer_tokens" "TOKEN_IDENTIFIER" (global $TOKEN_IDENTIFIER i32))
  (import "lexer_tokens" "TOKEN_NUMBER_LITERAL" (global $TOKEN_NUMBER_LITERAL i32))
  (import "lexer_tokens" "TOKEN_KW_FUNC" (global $TOKEN_KW_FUNC i32))

  ;; Set up test tokens in memory
  ;; Token array starts at offset 2048, each token is 16 bytes
  ;; Token format: [type:4][start:4][line:4][column:4]
  (func $setup_test_tokens
    ;; Token 0: IDENTIFIER at position 100, length will be inferred as 5
    (i32.store (i32.const 2048)  (global.get $TOKEN_IDENTIFIER))  ;; type
    (i32.store (i32.const 2052)  (i32.const 100))                ;; start
    (i32.store (i32.const 2056)  (i32.const 5))                  ;; length (stored in line field for test)
    (i32.store (i32.const 2060)  (i32.const 1))                  ;; column

    ;; Token 1: NUMBER_LITERAL at position 200, length 3
    (i32.store (i32.const 2064)  (global.get $TOKEN_NUMBER_LITERAL)) ;; type
    (i32.store (i32.const 2068)  (i32.const 200))                    ;; start
    (i32.store (i32.const 2072)  (i32.const 3))                      ;; length (stored in line field for test)
    (i32.store (i32.const 2076)  (i32.const 10))                     ;; column

    ;; Token 2: KW_FUNC at position 300, length 4
    (i32.store (i32.const 2080)  (global.get $TOKEN_KW_FUNC))    ;; type
    (i32.store (i32.const 2084)  (i32.const 300))                ;; start
    (i32.store (i32.const 2088)  (i32.const 4))                  ;; length (stored in line field for test)
    (i32.store (i32.const 2092)  (i32.const 15))                 ;; column
  )

  ;; Test get_token_type function
  (func $test_get_token_type (export "test_get_token_type") (result i32)
    (local $token_type i32)

    ;; Setup test data
    (call $setup_test_tokens)

    ;; Test token 0 - should be IDENTIFIER
    (local.set $token_type (call $get_token_type (i32.const 0)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_IDENTIFIER))
      (then (return (i32.const 0)))
    )

    ;; Test token 1 - should be NUMBER_LITERAL
    (local.set $token_type (call $get_token_type (i32.const 1)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_NUMBER_LITERAL))
      (then (return (i32.const 0)))
    )

    ;; Test token 2 - should be KW_FUNC
    (local.set $token_type (call $get_token_type (i32.const 2)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_KW_FUNC))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test get_token_start function
  (func $test_get_token_start (export "test_get_token_start") (result i32)
    (local $token_start i32)

    ;; Setup test data
    (call $setup_test_tokens)

    ;; Test token 0 - should start at position 100
    (local.set $token_start (call $get_token_start (i32.const 0)))
    (if (i32.ne (local.get $token_start) (i32.const 100))
      (then (return (i32.const 0)))
    )

    ;; Test token 1 - should start at position 200
    (local.set $token_start (call $get_token_start (i32.const 1)))
    (if (i32.ne (local.get $token_start) (i32.const 200))
      (then (return (i32.const 0)))
    )

    ;; Test token 2 - should start at position 300
    (local.set $token_start (call $get_token_start (i32.const 2)))
    (if (i32.ne (local.get $token_start) (i32.const 300))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test get_token_length function
  (func $test_get_token_length (export "test_get_token_length") (result i32)
    (local $token_length i32)

    ;; Setup test data
    (call $setup_test_tokens)

    ;; Test token 0 - should have length 5
    (local.set $token_length (call $get_token_length (i32.const 0)))
    (if (i32.ne (local.get $token_length) (i32.const 5))
      (then (return (i32.const 0)))
    )

    ;; Test token 1 - should have length 3
    (local.set $token_length (call $get_token_length (i32.const 1)))
    (if (i32.ne (local.get $token_length) (i32.const 3))
      (then (return (i32.const 0)))
    )

    ;; Test token 2 - should have length 4
    (local.set $token_length (call $get_token_length (i32.const 2)))
    (if (i32.ne (local.get $token_length) (i32.const 4))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test boundary conditions
  (func $test_boundary_conditions (export "test_boundary_conditions") (result i32)
    (local $token_type i32)
    (local $token_start i32)
    (local $token_length i32)

    ;; Setup test data
    (call $setup_test_tokens)

    ;; Test token at boundary (token index 2, last valid token)
    (local.set $token_type (call $get_token_type (i32.const 2)))
    (local.set $token_start (call $get_token_start (i32.const 2)))
    (local.set $token_length (call $get_token_length (i32.const 2)))

    ;; Verify all fields are correct for boundary token
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_KW_FUNC))
      (then (return (i32.const 0)))
    )
    (if (i32.ne (local.get $token_start) (i32.const 300))
      (then (return (i32.const 0)))
    )
    (if (i32.ne (local.get $token_length) (i32.const 4))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test token indexing consistency
  (func $test_token_indexing_consistency (export "test_token_indexing_consistency") (result i32)
    ;; Setup test data
    (call $setup_test_tokens)

    ;; Verify that accessing the same token multiple times gives consistent results
    (if (i32.ne (call $get_token_type (i32.const 1)) (call $get_token_type (i32.const 1)))
      (then (return (i32.const 0)))
    )
    (if (i32.ne (call $get_token_start (i32.const 1)) (call $get_token_start (i32.const 1)))
      (then (return (i32.const 0)))
    )
    (if (i32.ne (call $get_token_length (i32.const 1)) (call $get_token_length (i32.const 1)))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Run all tests
  (func $run_tests (export "run_tests") (result i32)
    (local $result i32)

    ;; Test 1: get_token_type
    (local.set $result (call $test_get_token_type))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 2: get_token_start
    (local.set $result (call $test_get_token_start))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 3: get_token_length
    (local.set $result (call $test_get_token_length))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 4: boundary conditions
    (local.set $result (call $test_boundary_conditions))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 5: token indexing consistency
    (local.set $result (call $test_token_indexing_consistency))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; All tests passed
    (i32.const 1)
  )
)
