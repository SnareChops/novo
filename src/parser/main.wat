;; Novo Parser Main Orchestration
;; Coordinates all parser components and provides main parsing interface

(module $novo_parser_main
  ;; Import memory from lexer memory module
  (import "lexer_memory" "memory" (memory 1))

  ;; Export memory for typechecker access
  (export "memory" (memory 0))

  ;; Import lexer functions
  (import "novo_lexer" "next_token" (func $next_token (param i32) (result i32 i32)))

  ;; Import token constants
  (import "lexer_tokens" "TOKEN_ERROR" (global $TOKEN_ERROR i32))
  (import "lexer_tokens" "TOKEN_EOF" (global $TOKEN_EOF i32))
  (import "lexer_tokens" "TOKEN_IDENTIFIER" (global $TOKEN_IDENTIFIER i32))
  (import "lexer_tokens" "TOKEN_NUMBER_LITERAL" (global $TOKEN_NUMBER_LITERAL i32))
  (import "lexer_tokens" "TOKEN_STRING_LITERAL" (global $TOKEN_STRING_LITERAL i32))
  (import "lexer_tokens" "TOKEN_LPAREN" (global $TOKEN_LPAREN i32))
  (import "lexer_tokens" "TOKEN_RPAREN" (global $TOKEN_RPAREN i32))

  ;; Import AST creation functions
  (import "ast_node_creators" "create_expr_identifier" (func $create_expr_identifier (param i32 i32) (result i32)))
  (import "ast_node_creators" "create_expr_integer_literal" (func $create_expr_integer_literal (param i64) (result i32)))
  (import "ast_node_creators" "create_expr_string_literal" (func $create_expr_string_literal (param i32 i32) (result i32)))

  ;; Import utility functions
  (import "parser_utils" "get_token_type" (func $get_token_type (param i32) (result i32)))
  (import "parser_utils" "get_token_start" (func $get_token_start (param i32) (result i32)))

  ;; Main parsing entry point (placeholder for now)
  ;; @param pos i32 - Current position in input
  ;; @returns i32 i32 - AST node pointer, next position
  (func $parse (export "parse") (param $pos i32) (result i32 i32)
    ;; For now, return error - this will be implemented later
    ;; when we have a full parser orchestration
    (i32.const 0)
    (local.get $pos)
  )
)
