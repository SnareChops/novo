;; Novo Parser Main Orchestrator
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
  (import "lexer_tokens" "TOKEN_KW_COMPONENT" (global $TOKEN_KW_COMPONENT i32))
  (import "lexer_tokens" "TOKEN_KW_INTERFACE" (global $TOKEN_KW_INTERFACE i32))
  (import "lexer_tokens" "TOKEN_KW_WORLD" (global $TOKEN_KW_WORLD i32))
  (import "lexer_tokens" "TOKEN_KW_FUNC" (global $TOKEN_KW_FUNC i32))

  ;; Import AST creation functions
  (import "ast_expression_creators" "create_expr_identifier" (func $create_expr_identifier (param i32 i32) (result i32)))
  (import "ast_expression_creators" "create_expr_integer_literal" (func $create_expr_integer_literal (param i64) (result i32)))
  (import "ast_expression_creators" "create_expr_string_literal" (func $create_expr_string_literal (param i32 i32) (result i32)))

  ;; Import component parsing functions
  (import "parser_components" "parse_component_declaration" (func $parse_component_declaration (param i32) (result i32 i32)))
  (import "parser_components" "parse_interface_declaration" (func $parse_interface_declaration (param i32) (result i32 i32)))
  (import "parser_components" "parse_world_declaration" (func $parse_world_declaration (param i32) (result i32 i32)))

  ;; Import function parsing
  (import "parser_functions" "parse_function_declaration" (func $parse_function_declaration (param i32) (result i32 i32)))

  ;; Import utility functions
  (import "parser_utils" "get_token_type" (func $get_token_type (param i32) (result i32)))
  (import "parser_utils" "get_token_start" (func $get_token_start (param i32) (result i32)))

  ;; Main parsing entry point
  ;; @param pos i32 - Current position in input
  ;; @returns i32 i32 - AST node pointer, next position
  (func $parse (export "parse") (param $pos i32) (result i32 i32)
    (local $token i32)
    (local $token_type i32)
    (local $next_pos i32)
    (local $ast_node i32)

    ;; Get first token to determine what kind of declaration this is
    (call $next_token (local.get $pos))
    (local.set $next_pos)
    (local.set $token)

    (local.set $token_type (call $get_token_type (local.get $token)))

    ;; Try parsing component declarations
    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_COMPONENT))
      (then
        (call $parse_component_declaration (local.get $pos))
        (return)))

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_INTERFACE))
      (then
        (call $parse_interface_declaration (local.get $pos))
        (return)))

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_WORLD))
      (then
        (call $parse_world_declaration (local.get $pos))
        (return)))

    ;; Try parsing function declarations
    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_FUNC))
      (then
        (call $parse_function_declaration (local.get $pos))
        (return)))

    ;; TODO: Add other top-level constructs (types, etc.)

    ;; Unknown construct
    (i32.const 0)
    (local.get $pos)
  )
)
