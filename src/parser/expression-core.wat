;; Novo Parser Expression Core
;; Core expression parsing logic using precedence climbing

(module $novo_parser_expression_core
  ;; Import memory from lexer
  (import "lexer_memory" "memory" (memory 1))

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
  (import "lexer_tokens" "TOKEN_META" (global $TOKEN_META i32))
  (import "lexer_tokens" "TOKEN_KW_TRUE" (global $TOKEN_KW_TRUE i32))
  (import "lexer_tokens" "TOKEN_KW_FALSE" (global $TOKEN_KW_FALSE i32))
  (import "lexer_tokens" "TOKEN_PLUS" (global $TOKEN_PLUS i32))
  (import "lexer_tokens" "TOKEN_MINUS" (global $TOKEN_MINUS i32))
  (import "lexer_tokens" "TOKEN_MULTIPLY" (global $TOKEN_MULTIPLY i32))
  (import "lexer_tokens" "TOKEN_DIVIDE" (global $TOKEN_DIVIDE i32))
  (import "lexer_tokens" "TOKEN_MODULO" (global $TOKEN_MODULO i32))

  ;; Import AST node creators
  (import "ast_node_creators" "create_expr_identifier" (func $create_expr_identifier (param i32 i32) (result i32)))
  (import "ast_node_creators" "create_expr_integer_literal" (func $create_expr_integer_literal (param i64) (result i32)))
  (import "ast_node_creators" "create_expr_string_literal" (func $create_expr_string_literal (param i32 i32) (result i32)))
  (import "ast_node_creators" "create_expr_bool_literal" (func $create_expr_bool_literal (param i32) (result i32)))
  (import "ast_node_creators" "create_expr_add" (func $create_expr_add (param i32 i32) (result i32)))
  (import "ast_node_creators" "create_expr_sub" (func $create_expr_sub (param i32 i32) (result i32)))
  (import "ast_node_creators" "create_expr_mul" (func $create_expr_mul (param i32 i32) (result i32)))
  (import "ast_node_creators" "create_expr_div" (func $create_expr_div (param i32 i32) (result i32)))
  (import "ast_node_creators" "create_expr_mod" (func $create_expr_mod (param i32 i32) (result i32)))

  ;; Import precedence functions
  (import "parser_precedence" "get_precedence" (func $get_precedence (param i32) (result i32)))
  (import "parser_precedence" "is_binary_operator" (func $is_binary_operator (param i32) (result i32)))
  (import "parser_precedence" "PRECEDENCE_NONE" (global $PRECEDENCE_NONE i32))

  ;; Import helper functions
  (import "parser_utils" "get_token_type" (func $get_token_type (param i32) (result i32)))
  (import "parser_utils" "get_token_start" (func $get_token_start (param i32) (result i32)))
  (import "parser_utils" "get_token_length" (func $get_token_length (param i32) (result i32)))

  ;; Memory layout constants
  (global $TOKEN_ARRAY_START i32 (i32.const 2048))
  (global $TOKEN_RECORD_SIZE i32 (i32.const 16))

  ;; Parse a primary expression (literals, identifiers, parenthesized expressions)
  (func $parse_primary (param $pos i32) (result i32 i32)
    (local $token_idx i32)
    (local $next_pos i32)
    (local $token_type i32)
    (local $token_start i32)
    (local $ast_node i32)
    (local $temp_pos i32)

    ;; Get next token
    (call $next_token (local.get $pos))
    (local.tee $next_pos) ;; Store and keep on stack
    (local.set $token_idx) ;; Pop token index from stack

    ;; Get token information
    (local.set $token_type (call $get_token_type (local.get $token_idx)))
    (local.set $token_start (call $get_token_start (local.get $token_idx)))

    ;; Handle different primary expression types
    (if (i32.eq (local.get $token_type) (global.get $TOKEN_NUMBER_LITERAL))
      (then
        ;; Create integer literal node (simplified - parse actual number later)
        (local.set $ast_node (call $create_expr_integer_literal (i64.const 42)))
        (return (local.get $ast_node) (local.get $next_pos))
      )
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_STRING_LITERAL))
      (then
        ;; Create string literal node
        (local.set $ast_node (call $create_expr_string_literal (local.get $token_start) (i32.const 10)))
        (return (local.get $ast_node) (local.get $next_pos))
      )
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_TRUE))
      (then
        ;; Create boolean literal node (true)
        (local.set $ast_node (call $create_expr_bool_literal (i32.const 1)))
        (return (local.get $ast_node) (local.get $next_pos))
      )
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_FALSE))
      (then
        ;; Create boolean literal node (false)
        (local.set $ast_node (call $create_expr_bool_literal (i32.const 0)))
        (return (local.get $ast_node) (local.get $next_pos))
      )
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_IDENTIFIER))
      (then
        ;; Simple identifier (no function calls or meta-calls for now)
        (local.set $ast_node
          (call $create_expr_identifier
            (call $get_token_start (local.get $token_idx))
            (call $get_token_length (local.get $token_idx))))
        (return (local.get $ast_node) (local.get $next_pos))
      )
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_LPAREN))
      (then
        ;; Parenthesized expression
        (call $parse_expression (local.get $next_pos))
        (local.set $ast_node)  ;; First return value
        (local.set $next_pos)  ;; Second return value

        ;; Expect closing parenthesis
        (call $next_token (local.get $next_pos))
        (local.set $token_idx) ;; First return value
        (local.set $next_pos)  ;; Second return value
        (local.set $token_type (call $get_token_type (local.get $token_idx)))

        (if (i32.ne (local.get $token_type) (global.get $TOKEN_RPAREN))
          (then
            ;; Error: expected closing parenthesis
            (return (i32.const 0) (local.get $next_pos))
          )
        )

        (return (local.get $ast_node) (local.get $next_pos))
      )
    )

    ;; Error: unexpected token
    (return (i32.const 0) (local.get $next_pos))
  )

  ;; Parse expression with precedence climbing
  (func $parse_expression_prec (param $pos i32) (param $min_prec i32) (result i32 i32)
    (local $left_node i32)
    (local $right_node i32)
    (local $token_idx i32)
    (local $next_pos i32)
    (local $token_type i32)
    (local $precedence i32)
    (local $ast_node i32)

    ;; Parse left operand
    (call $parse_primary (local.get $pos))
    (local.set $left_node) ;; First return value
    (local.set $next_pos)  ;; Second return value

    ;; If primary parsing failed, return error
    (if (i32.eqz (local.get $left_node))
      (then (return (i32.const 0) (local.get $next_pos)))
    )

    ;; Handle binary operators with precedence climbing
    (loop $operator_loop
      ;; Get next token
      (call $next_token (local.get $next_pos))
      (local.set $token_idx) ;; First return value
      (drop)                 ;; Ignore position for now (lookahead)
      (local.set $token_type (call $get_token_type (local.get $token_idx)))

      ;; Check if it's a binary operator
      (if (i32.eqz (call $is_binary_operator (local.get $token_type)))
        (then (br $operator_loop)) ;; Exit loop - not an operator
      )

      ;; Get operator precedence
      (local.set $precedence (call $get_precedence (local.get $token_type)))

      ;; Check if precedence is high enough
      (if (i32.lt_s (local.get $precedence) (local.get $min_prec))
        (then (br $operator_loop)) ;; Exit loop - precedence too low
      )

      ;; Consume the operator token
      (call $next_token (local.get $next_pos))
      (drop)                 ;; Ignore token index
      (local.set $next_pos)  ;; Update position past operator

      ;; Parse right operand with higher precedence
      (call $parse_expression_prec
        (local.get $next_pos)
        (i32.add (local.get $precedence) (i32.const 1)) ;; Left associative
      )
      (local.set $right_node) ;; First return value
      (local.set $next_pos)   ;; Second return value

      ;; If right operand parsing failed, return error
      (if (i32.eqz (local.get $right_node))
        (then (return (i32.const 0) (local.get $next_pos)))
      )

      ;; Create binary operation AST node based on operator type
      (if (i32.eq (local.get $token_type) (global.get $TOKEN_PLUS))
        (then
          (local.set $left_node (call $create_expr_add (local.get $left_node) (local.get $right_node)))
        )
      )
      (if (i32.eq (local.get $token_type) (global.get $TOKEN_MINUS))
        (then
          (local.set $left_node (call $create_expr_sub (local.get $left_node) (local.get $right_node)))
        )
      )
      (if (i32.eq (local.get $token_type) (global.get $TOKEN_MULTIPLY))
        (then
          (local.set $left_node (call $create_expr_mul (local.get $left_node) (local.get $right_node)))
        )
      )
      (if (i32.eq (local.get $token_type) (global.get $TOKEN_DIVIDE))
        (then
          (local.set $left_node (call $create_expr_div (local.get $left_node) (local.get $right_node)))
        )
      )
      (if (i32.eq (local.get $token_type) (global.get $TOKEN_MODULO))
        (then
          (local.set $left_node (call $create_expr_mod (local.get $left_node) (local.get $right_node)))
        )
      )

      (br $operator_loop) ;; Continue parsing operators
    )

    (return (local.get $left_node) (local.get $next_pos))
  )

  ;; Main expression parsing entry point
  (func $parse_expression (export "parse_expression") (param $pos i32) (result i32 i32)
    (call $parse_expression_prec (local.get $pos) (global.get $PRECEDENCE_NONE))
  )
)
