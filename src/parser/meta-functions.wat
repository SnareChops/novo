;; Novo Parser Meta Functions
;; Handles meta-function call syntax: value::size(), type::new(), etc.

(module $parser_meta_functions
  ;; Import memory from lexer
  (import "lexer_memory" "memory" (memory 1))

  ;; Import lexer functions
  (import "novo_lexer" "next_token" (func $next_token (param i32) (result i32 i32)))

  ;; Import token constants
  (import "lexer_tokens" "TOKEN_ERROR" (global $TOKEN_ERROR i32))
  (import "lexer_tokens" "TOKEN_IDENTIFIER" (global $TOKEN_IDENTIFIER i32))
  (import "lexer_tokens" "TOKEN_META" (global $TOKEN_META i32))
  (import "lexer_tokens" "TOKEN_LPAREN" (global $TOKEN_LPAREN i32))
  (import "lexer_tokens" "TOKEN_RPAREN" (global $TOKEN_RPAREN i32))
  (import "lexer_tokens" "TOKEN_COMMA" (global $TOKEN_COMMA i32))

  ;; Import AST expression creators
  (import "ast_expression_creators" "create_expr_meta_call" (func $create_expr_meta_call (param i32 i32) (result i32)))
  (import "ast_expression_creators" "create_expr_identifier" (func $create_expr_identifier (param i32 i32) (result i32)))

  ;; Import AST core functions
  (import "ast_node_core" "add_child" (func $add_child (param i32 i32) (result i32)))

  ;; Import helper functions
  (import "parser_utils" "get_token_type" (func $get_token_type (param i32) (result i32)))
  (import "parser_utils" "get_token_start" (func $get_token_start (param i32) (result i32)))
  (import "parser_utils" "get_token_length" (func $get_token_length (param i32) (result i32)))

  ;; Import expression parser for arguments
  (import "parser_expression_parsing" "parse_expression" (func $parse_expression (param i32) (result i32 i32)))

  ;; Memory helpers for string comparison
  (func $string_equals (param $str1_start i32) (param $str1_len i32) (param $str2_start i32) (param $str2_len i32) (result i32)
    (local $i i32)

    ;; Different lengths means not equal
    (if (i32.ne (local.get $str1_len) (local.get $str2_len))
      (then (return (i32.const 0)))
    )

    ;; Compare character by character
    (local.set $i (i32.const 0))
    (loop $compare_loop
      (if (i32.ge_u (local.get $i) (local.get $str1_len))
        (then (return (i32.const 1))) ;; All characters matched
      )

      (if (i32.ne
            (i32.load8_u (i32.add (local.get $str1_start) (local.get $i)))
            (i32.load8_u (i32.add (local.get $str2_start) (local.get $i)))
          )
        (then (return (i32.const 0))) ;; Characters don't match
      )

      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $compare_loop)
    )

    (i32.const 1) ;; Should not reach here
  )

  ;; Check if identifier is a supported meta-function
  (func $is_supported_meta_function (param $name_start i32) (param $name_len i32) (result i32)
    ;; For now, support "size" and "type"
    ;; TODO: Add string literals for comparison

    ;; Simplified check - just return true for now
    ;; In a real implementation, we'd compare against known meta-function names
    (i32.const 1)
  )

  ;; Parse a meta-function call: target::method_name(args...)
  (func $parse_meta_call (export "parse_meta_call") (param $pos i32) (result i32 i32)
    (local $token_idx i32)
    (local $next_pos i32)
    (local $token_type i32)
    (local $token_start i32)
    (local $target_node i32)
    (local $method_name_node i32)
    (local $call_node i32)
    (local $arg_node i32)
    (local $current_pos i32)

    ;; Parse target (identifier or expression)
    (local.set $token_idx (call $next_token (local.get $pos)))
    (local.set $next_pos) ;; Get next position

    (local.set $token_type (call $get_token_type (local.get $token_idx)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_IDENTIFIER))
      (then
        ;; Error: expected target identifier
        (return (i32.const 0) (local.get $next_pos))
      )
    )

    ;; Create target identifier node
    (local.set $token_start (call $get_token_start (local.get $token_idx)))
    (local.set $target_node (call $create_expr_identifier (local.get $token_start) (i32.const 10)))

    ;; Expect :: token
    (local.set $token_idx (call $next_token (local.get $next_pos)))
    (local.set $next_pos) ;; Update position

    (local.set $token_type (call $get_token_type (local.get $token_idx)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_META))
      (then
        ;; Error: expected ::
        (return (i32.const 0) (local.get $next_pos))
      )
    )

    ;; Parse method name
    (local.set $token_idx (call $next_token (local.get $next_pos)))
    (local.set $next_pos) ;; Update position

    (local.set $token_type (call $get_token_type (local.get $token_idx)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_IDENTIFIER))
      (then
        ;; Error: expected method name
        (return (i32.const 0) (local.get $next_pos))
      )
    )

    ;; Create method name identifier node
    (local.set $token_start (call $get_token_start (local.get $token_idx)))
    (local.set $method_name_node (call $create_expr_identifier (local.get $token_start) (i32.const 10)))

    ;; Check if method name is supported
    (if (i32.eqz (call $is_supported_meta_function (local.get $token_start) (i32.const 10)))
      (then
        ;; Error: unsupported meta-function
        (return (i32.const 0) (local.get $next_pos))
      )
    )

    ;; Create meta-function call node
    (local.set $call_node (call $create_expr_meta_call (local.get $target_node) (local.get $method_name_node)))

    ;; Check for optional parentheses
    (local.set $token_idx (call $next_token (local.get $next_pos)))
    (local.set $token_type (call $get_token_type (local.get $token_idx)))

    (if (i32.ne (local.get $token_type) (global.get $TOKEN_LPAREN))
      (then
        ;; No parentheses - return as-is (paren-less syntax)
        (return (local.get $call_node) (local.get $next_pos))
      )
    )

    ;; Parse arguments with parentheses
    (local.set $current_pos) ;; Update position past opening paren

    ;; Parse arguments (similar to function calls)
    (block $parse_args_done
      (loop $parse_args_loop
        ;; Check for closing parenthesis
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

        ;; Add argument as child to meta-function call node
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

    ;; Return meta-function call node and updated position
    (return (local.get $call_node) (local.get $current_pos))
  )
)
