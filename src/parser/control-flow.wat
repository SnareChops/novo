;; Novo Parser Control Flow
;; Parsing logic for control flow statements: if/else, while, break, continue, return

(module $novo_parser_control_flow
  ;; Import memory from lexer
  (import "lexer_memory" "memory" (memory 1))

  ;; Import lexer functions
  (import "novo_lexer" "next_token" (func $next_token (param i32) (result i32 i32)))

  ;; Import token constants - control flow keywords
  (import "lexer_tokens" "TOKEN_ERROR" (global $TOKEN_ERROR i32))
  (import "lexer_tokens" "TOKEN_EOF" (global $TOKEN_EOF i32))
  (import "lexer_tokens" "TOKEN_KW_IF" (global $TOKEN_KW_IF i32))
  (import "lexer_tokens" "TOKEN_KW_ELSE" (global $TOKEN_KW_ELSE i32))
  (import "lexer_tokens" "TOKEN_KW_WHILE" (global $TOKEN_KW_WHILE i32))
  (import "lexer_tokens" "TOKEN_KW_BREAK" (global $TOKEN_KW_BREAK i32))
  (import "lexer_tokens" "TOKEN_KW_CONTINUE" (global $TOKEN_KW_CONTINUE i32))
  (import "lexer_tokens" "TOKEN_KW_RETURN" (global $TOKEN_KW_RETURN i32))

  ;; Import structure tokens
  (import "lexer_tokens" "TOKEN_LPAREN" (global $TOKEN_LPAREN i32))
  (import "lexer_tokens" "TOKEN_RPAREN" (global $TOKEN_RPAREN i32))
  (import "lexer_tokens" "TOKEN_LBRACE" (global $TOKEN_LBRACE i32))
  (import "lexer_tokens" "TOKEN_RBRACE" (global $TOKEN_RBRACE i32))

  ;; Import AST control flow node creators
  (import "ast_node_creators" "create_ctrl_if" (func $create_ctrl_if (param i32 i32 i32) (result i32)))
  (import "ast_node_creators" "create_ctrl_while" (func $create_ctrl_while (param i32 i32) (result i32)))
  (import "ast_node_creators" "create_ctrl_return" (func $create_ctrl_return (param i32) (result i32)))
  (import "ast_node_creators" "create_ctrl_break" (func $create_ctrl_break (result i32)))
  (import "ast_node_creators" "create_ctrl_continue" (func $create_ctrl_continue (result i32)))

  ;; Import expression parsing (for conditions and return values) - TODO: enable when needed
  ;; (import "parser_expression_core" "parse_expression" (func $parse_expression (param i32) (result i32 i32)))

  ;; Import utility functions
  (import "parser_utils" "get_token_type" (func $get_token_type (param i32) (result i32)))
  (import "parser_utils" "get_token_start" (func $get_token_start (param i32) (result i32)))
  (import "parser_utils" "get_token_length" (func $get_token_length (param i32) (result i32)))

  ;; Memory layout constants
  (global $TOKEN_ARRAY_START i32 (i32.const 2048))
  (global $TOKEN_RECORD_SIZE i32 (i32.const 16))

  ;; Parse break statement
  ;; Syntax: break
  ;; @param pos i32 - Current position in input
  ;; @returns i32 i32 - AST node pointer, next position
  (func $parse_break_statement (export "parse_break_statement") (param $pos i32) (result i32 i32)
    (local $token_index i32)
    (local $token_type i32)
    (local $new_pos i32)

    ;; Get current token (should be 'break')
    (local.set $token_index (call $next_token (local.get $pos)))
    (local.set $new_pos (i32.and (local.get $token_index) (i32.const 0xFFFF)))
    (local.set $token_index (i32.shr_u (local.get $token_index) (i32.const 16)))

    (local.set $token_type (call $get_token_type (local.get $token_index)))

    ;; Verify this is a 'break' token
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_KW_BREAK))
      (then
        ;; Error: expected 'break'
        (return (i32.const 0) (local.get $pos))
      )
      (else
        ;; Continue processing
        (nop)
      )
    )

    ;; Create break AST node
    (local.set $token_index (call $create_ctrl_break))

    ;; Return AST node and next position
    (return (local.get $token_index) (local.get $new_pos))
  )

  ;; Parse continue statement
  ;; Syntax: continue
  ;; @param pos i32 - Current position in input
  ;; @returns i32 i32 - AST node pointer, next position
  (func $parse_continue_statement (export "parse_continue_statement") (param $pos i32) (result i32 i32)
    (local $token_index i32)
    (local $token_type i32)
    (local $new_pos i32)

    ;; Get current token (should be 'continue')
    (local.set $token_index (call $next_token (local.get $pos)))
    (local.set $new_pos (i32.and (local.get $token_index) (i32.const 0xFFFF)))
    (local.set $token_index (i32.shr_u (local.get $token_index) (i32.const 16)))

    (local.set $token_type (call $get_token_type (local.get $token_index)))

    ;; Verify this is a 'continue' token
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_KW_CONTINUE))
      (then
        ;; Error: expected 'continue'
        (return (i32.const 0) (local.get $pos))
      )
    )

    ;; Create continue AST node
    (local.set $token_index (call $create_ctrl_continue))

    ;; Return AST node and next position
    (return (local.get $token_index) (local.get $new_pos))
  )

  ;; Parse return statement
  ;; Syntax: return [expression]
  ;; @param pos i32 - Current position in input
  ;; @returns i32 i32 - AST node pointer, next position
  (func $parse_return_statement (export "parse_return_statement") (param $pos i32) (result i32 i32)
    (local $token_index i32)
    (local $token_type i32)
    (local $return_value i32)
    (local $new_pos i32)

    ;; Get current token (should be 'return')
    (local.set $token_index (call $next_token (local.get $pos)))
    (local.set $new_pos (i32.and (local.get $token_index) (i32.const 0xFFFF)))
    (local.set $token_index (i32.shr_u (local.get $token_index) (i32.const 16)))

    (local.set $token_type (call $get_token_type (local.get $token_index)))

    ;; Verify this is a 'return' token
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_KW_RETURN))
      (then
        ;; Error: expected 'return'
        (return (i32.const 0) (local.get $pos))
      )
    )

    ;; For now, just handle return without value
    ;; TODO: Parse optional return expression
    (local.set $return_value (i32.const 0))

    ;; Create return AST node
    (local.set $token_index (call $create_ctrl_return (local.get $return_value)))

    ;; Return AST node and next position
    (return (local.get $token_index) (local.get $new_pos))
  )

  ;; Main entry point for control flow parsing
  ;; Determines which control flow statement to parse based on token type
  ;; @param pos i32 - Current position in input
  ;; @returns i32 i32 - AST node pointer, next position
  (func $parse_control_flow (export "parse_control_flow") (param $pos i32) (result i32 i32)
    (local $token_index i32)
    (local $token_type i32)

    ;; Peek at current token to determine control flow type
    (local.set $token_index (call $next_token (local.get $pos)))
    (local.set $token_type (call $get_token_type (i32.shr_u (local.get $token_index) (i32.const 16))))

    ;; Dispatch to appropriate parser based on token type
    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_RETURN))
      (then (return (call $parse_return_statement (local.get $pos))))
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_BREAK))
      (then (return (call $parse_break_statement (local.get $pos))))
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_CONTINUE))
      (then (return (call $parse_continue_statement (local.get $pos))))
    )

    ;; Not a control flow statement
    (return (i32.const 0) (local.get $pos))
  )
)
