;; Novo Parser Function Calls
;; Handles traditional function call syntax: func(arg1, arg2, ...)

(module $parser_function_calls
  ;; Import memory from lexer
  (import "lexer_memory" "memory" (memory 1))

  ;; Import lexer functions
  (import "novo_lexer" "next_token" (func $next_token (param i32) (result i32 i32)))

  ;; Import helper functions
  (import "parser_utils" "get_token_type" (func $get_token_type (param i32) (result i32)))
  (import "parser_utils" "get_token_start" (func $get_token_start (param i32) (result i32)))
  (import "parser_utils" "get_token_length" (func $get_token_length (param i32) (result i32)))

  ;; Import token constants
  (import "lexer_tokens" "TOKEN_ERROR" (global $TOKEN_ERROR i32))
  (import "lexer_tokens" "TOKEN_IDENTIFIER" (global $TOKEN_IDENTIFIER i32))
  (import "lexer_tokens" "TOKEN_LPAREN" (global $TOKEN_LPAREN i32))
  (import "lexer_tokens" "TOKEN_RPAREN" (global $TOKEN_RPAREN i32))
  (import "lexer_tokens" "TOKEN_COMMA" (global $TOKEN_COMMA i32))

  ;; Import AST expression creators
  (import "ast_expression_creators" "create_expr_traditional_call" (func $create_expr_traditional_call (param i32 i32) (result i32)))
  (import "ast_expression_creators" "create_expr_identifier" (func $create_expr_identifier (param i32 i32) (result i32)))

  ;; Import AST core functions
  (import "ast_node_core" "add_child" (func $add_child (param i32 i32) (result i32)))

  ;; Import expression parser for arguments
  (import "parser_expression_parsing" "parse_expression" (func $parse_expression (param i32) (result i32 i32)))

  ;; Parse a traditional function call: identifier(arg1, arg2, ...)
  (func $parse_function_call (export "parse_function_call") (param $pos i32) (result i32 i32)
    (local $token_idx i32)
    (local $next_pos i32)
    (local $token_type i32)
    (local $token_start i32)
    (local $func_name_node i32)
    (local $call_node i32)
    (local $arg_node i32)
    (local $current_pos i32)

    ;; Parse function name (identifier)
    (local.set $token_idx (call $next_token (local.get $pos)))
    (local.set $next_pos) ;; Get next position

    (local.set $token_type (call $get_token_type (local.get $token_idx)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_IDENTIFIER))
      (then
        ;; Error: expected function name
        (return (i32.const 0) (local.get $next_pos))
      )
    )

    ;; Create function name identifier node
    (local.set $token_start (call $get_token_start (local.get $token_idx)))
    (local.set $func_name_node (call $create_expr_identifier (local.get $token_start) (i32.const 10)))

    ;; Expect opening parenthesis
    (local.set $token_idx (call $next_token (local.get $next_pos)))
    (local.set $next_pos) ;; Update position

    (local.set $token_type (call $get_token_type (local.get $token_idx)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_LPAREN))
      (then
        ;; Error: expected opening parenthesis
        (return (i32.const 0) (local.get $next_pos))
      )
    )

    ;; Create function call node
    (local.set $call_node (call $create_expr_traditional_call (local.get $func_name_node) (i32.const 0)))

    ;; Set current position past opening parenthesis
    (local.set $current_pos (local.get $next_pos))

    ;; Parse arguments (if any)
    (block $parse_args_done
      (loop $parse_args_loop
        ;; Check for closing parenthesis (empty arguments or end of list)
        (local.set $token_idx (call $next_token (local.get $current_pos)))
        (local.set $token_type (call $get_token_type (local.get $token_idx)))

        (if (i32.eq (local.get $token_type) (global.get $TOKEN_RPAREN))
          (then
            ;; End of arguments
            (local.set $current_pos (i32.add (local.get $current_pos) (i32.const 1))) ;; Update position past closing paren
            (br $parse_args_done)
          )
        )

        ;; Parse argument expression
        (call $parse_expression (local.get $current_pos))
        (local.set $current_pos) ;; Get updated position from parse_expression
        (local.set $arg_node) ;; Get node from parse_expression

        ;; If argument parsing failed, return error
        (if (i32.eqz (local.get $arg_node))
          (then (return (i32.const 0) (local.get $current_pos)))
        )

        ;; Add argument as child to function call node
        (call $add_child (local.get $call_node) (local.get $arg_node))

        ;; Check for comma or closing parenthesis
        (local.set $token_idx (call $next_token (local.get $current_pos)))
        (local.set $token_type (call $get_token_type (local.get $token_idx)))

        (if (i32.eq (local.get $token_type) (global.get $TOKEN_COMMA))
          (then
            ;; More arguments - consume comma and continue
            (local.set $current_pos (i32.add (local.get $current_pos) (i32.const 1))) ;; Update position past comma
            (br $parse_args_loop)
          )
        )

        (if (i32.eq (local.get $token_type) (global.get $TOKEN_RPAREN))
          (then
            ;; End of arguments
            (local.set $current_pos (i32.add (local.get $current_pos) (i32.const 1))) ;; Update position past closing paren
            (br $parse_args_done)
          )
        )

        ;; Error: expected comma or closing parenthesis
        (return (i32.const 0) (local.get $current_pos))
      )
    )

    ;; Return function call node and updated position
    (return (local.get $call_node) (local.get $current_pos))
  )
)
