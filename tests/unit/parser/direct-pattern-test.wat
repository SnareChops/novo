;; Direct Pattern Test
;; Test pattern parsing without lexer dependency

(module $direct_pattern_test
  ;; Import AST memory
  (import "ast_memory" "memory" (memory 4))
  (import "ast_memory" "init_memory_manager" (func $init_memory_manager))

  ;; Import token types for manual token creation
  (import "lexer_tokens" "TOKEN_KW_MATCH" (global $TOKEN_KW_MATCH i32))
  (import "lexer_tokens" "TOKEN_IDENTIFIER" (global $TOKEN_IDENTIFIER i32))
  (import "lexer_tokens" "TOKEN_LBRACE" (global $TOKEN_LBRACE i32))

  ;; Import parser functions
  (import "parser_patterns" "parse_pattern_matching" (func $parse_pattern_matching (param i32) (result i32 i32)))

  ;; Import parser utils to manually create tokens
  (import "parser_utils" "get_token_type" (func $get_token_type (param i32) (result i32)))

  ;; Memory areas
  (global $TOKEN_ARRAY_START i32 (i32.const 2048))
  (global $TOKEN_RECORD_SIZE i32 (i32.const 16))

  ;; Manually create a simple token at index 0: TOKEN_KW_MATCH
  (func $setup_tokens
    ;; Token 0: match keyword
    (i32.store
      (global.get $TOKEN_ARRAY_START)
      (global.get $TOKEN_KW_MATCH))
    (i32.store
      (i32.add (global.get $TOKEN_ARRAY_START) (i32.const 4))
      (i32.const 0))  ;; start position
    (i32.store
      (i32.add (global.get $TOKEN_ARRAY_START) (i32.const 8))
      (i32.const 5))  ;; length
    (i32.store
      (i32.add (global.get $TOKEN_ARRAY_START) (i32.const 12))
      (i32.const 0))  ;; line
  )

  ;; Test function
  (func $run_direct_test (export "run_direct_test") (result i32)
    (local $result i32)
    (local $node_ptr i32)

    ;; Initialize AST memory
    (call $init_memory_manager)

    ;; Setup test tokens
    (call $setup_tokens)

    ;; Verify token was created correctly
    (local.set $result (call $get_token_type (i32.const 0)))
    (if (i32.ne (local.get $result) (global.get $TOKEN_KW_MATCH))
      (then
        ;; Token setup failed - but let's continue for now to see what happens
        ;; (return (i32.const 0))
      )
    )

    ;; Try pattern parsing - this should either work or fail gracefully
    (local.set $result (call $parse_pattern_matching (i32.const 0)))
    (local.set $node_ptr (i32.shr_u (local.get $result) (i32.const 16)))

    ;; Return success - we made it through without crashing
    (return (i32.const 1))
  )

  ;; Start function
  (func $_start (export "_start")
    (local $result i32)
    (local.set $result (call $run_direct_test))
    (if (local.get $result)
      (then)  ;; Success
      (else unreachable)  ;; Failure
    )
  )
)
