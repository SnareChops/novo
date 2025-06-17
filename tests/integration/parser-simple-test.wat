;; Simple Parser Test - Just test basic tokenization and simple parsing
;; Tests a single number literal

(module $parser_simple_test
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))
  (import "lexer_memory" "update_position" (func $update_position (param i32)))

  ;; Import lexer functions
  (import "novo_lexer" "next_token" (func $next_token (param i32) (result i32 i32)))

  ;; Import parser functions
  (import "parser_expression_core" "parse_expression" (func $parse_expression (param i32) (result i32 i32)))

  ;; Import token constants for debugging
  (import "lexer_tokens" "TOKEN_NUMBER_LITERAL" (global $TOKEN_NUMBER_LITERAL i32))
  (import "lexer_tokens" "TOKEN_EOF" (global $TOKEN_EOF i32))
  (import "lexer_tokens" "TOKEN_ERROR" (global $TOKEN_ERROR i32))

  ;; Import parser utils to check tokens
  (import "parser_utils" "get_token_type" (func $get_token_type (param i32) (result i32)))

  ;; Test function - parse just "42"
  (func $test_simple_number (export "_start")
    (local $ast_node i32)
    (local $pos i32)
    (local $token_idx i32)
    (local $next_pos i32)
    (local $token_type i32)

    ;; Write test input to memory: "42"
    (i32.store8 (i32.const 0) (i32.const 0x34))  ;; '4'
    (i32.store8 (i32.const 1) (i32.const 0x32))  ;; '2'
    (i32.store8 (i32.const 2) (i32.const 0x00))  ;; null terminator

    ;; Reset lexer to start of input
    (call $update_position (i32.const 0))

    ;; First, test tokenization directly
    (call $next_token (i32.const 0))
    (local.set $next_pos)
    (local.set $token_idx)

    ;; Check what token type we got
    (local.set $token_type (call $get_token_type (local.get $token_idx)))

    ;; Verify we got the right token type
    (if (i32.eq (local.get $token_type) (global.get $TOKEN_ERROR))
      (then
        ;; Tokenization failed
        (unreachable)
      )
    )

    ;; Now try parsing
    (call $parse_expression (i32.const 0))
    (local.set $pos)      ;; Get final position
    (local.set $ast_node) ;; Get AST node

    ;; Verify we got a valid AST node
    (if (i32.eqz (local.get $ast_node))
      (then
        ;; Test failed - no AST node returned
        (unreachable)
      )
    )

    ;; Test passed if we get here
  )
)
