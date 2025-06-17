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
  (import "lexer_tokens" "TOKEN_COMMA" (global $TOKEN_COMMA i32))
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
  (import "ast_node_creators" "create_expr_traditional_call" (func $create_expr_traditional_call (param i32 i32) (result i32)))
  (import "ast_node_creators" "create_expr_meta_call" (func $create_expr_meta_call (param i32 i32) (result i32)))

  ;; Import AST core functions
  (import "ast_node_core" "add_child" (func $add_child (param i32 i32) (result i32)))

  ;; Import precedence functions
  (import "parser_precedence" "get_precedence" (func $get_precedence (param i32) (result i32)))
  (import "parser_precedence" "is_binary_operator" (func $is_binary_operator (param i32) (result i32)))
  (import "parser_precedence" "PRECEDENCE_NONE" (global $PRECEDENCE_NONE i32))

  ;; Import helper functions
  (import "parser_utils" "get_token_type" (func $get_token_type (param i32) (result i32)))
  (import "parser_utils" "get_token_start" (func $get_token_start (param i32) (result i32)))
  (import "parser_utils" "get_token_length" (func $get_token_length (param i32) (result i32)))

  ;; No external function call parsers needed - inline the logic

  ;; Memory layout constants
  (global $TOKEN_ARRAY_START i32 (i32.const 2048))
  (global $TOKEN_RECORD_SIZE i32 (i32.const 16))

  ;; Helper function for string comparison
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

  ;; Parse a traditional function call: identifier(arg1, arg2, ...)
  (func $parse_function_call_inline (param $pos i32) (result i32 i32)
    (local $token_idx i32)
    (local $next_pos i32)
    (local $token_type i32)
    (local $token_start i32)
    (local $func_name_node i32)
    (local $call_node i32)
    (local $arg_node i32)
    (local $current_pos i32)

    ;; Parse function name (identifier)
    (call $next_token (local.get $pos))
    (local.set $next_pos) ;; Get next position
    (local.set $token_idx) ;; Get token index

    (local.set $token_type (call $get_token_type (local.get $token_idx)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_IDENTIFIER))
      (then
        ;; Error: expected function name
        (return (i32.const 0) (local.get $next_pos))
      )
    )

    ;; Create function name identifier node
    (local.set $token_start (call $get_token_start (local.get $token_idx)))
    (local.set $func_name_node (call $create_expr_identifier (local.get $token_start) (call $get_token_length (local.get $token_idx))))

    ;; Expect opening parenthesis
    (call $next_token (local.get $next_pos))
    (local.set $next_pos) ;; Update position
    (local.set $token_idx) ;; Get token index

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
        (call $next_token (local.get $current_pos))
        (local.set $token_idx) ;; Get token index
        (drop) ;; Drop next position for now

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
        (drop (call $add_child (local.get $call_node) (local.get $arg_node)))

        ;; Check for comma or closing parenthesis
        (call $next_token (local.get $current_pos))
        (local.set $token_idx) ;; Get token index
        (drop) ;; Drop next position for now

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

  ;; Parse a meta-function call: target::method_name(args...)
  (func $parse_meta_call_inline (param $pos i32) (result i32 i32)
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
    (call $next_token (local.get $pos))
    (local.set $next_pos) ;; Get next position
    (local.set $token_idx) ;; Get token index

    (local.set $token_type (call $get_token_type (local.get $token_idx)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_IDENTIFIER))
      (then
        ;; Error: expected target identifier
        (return (i32.const 0) (local.get $next_pos))
      )
    )

    ;; Create target identifier node
    (local.set $token_start (call $get_token_start (local.get $token_idx)))
    (local.set $target_node (call $create_expr_identifier (local.get $token_start) (call $get_token_length (local.get $token_idx))))

    ;; Expect :: token
    (call $next_token (local.get $next_pos))
    (local.set $next_pos) ;; Update position
    (local.set $token_idx) ;; Get token index

    (local.set $token_type (call $get_token_type (local.get $token_idx)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_META))
      (then
        ;; Error: expected ::
        (return (i32.const 0) (local.get $next_pos))
      )
    )

    ;; Parse method name
    (call $next_token (local.get $next_pos))
    (local.set $next_pos) ;; Update position
    (local.set $token_idx) ;; Get token index

    (local.set $token_type (call $get_token_type (local.get $token_idx)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_IDENTIFIER))
      (then
        ;; Error: expected method name
        (return (i32.const 0) (local.get $next_pos))
      )
    )

    ;; Create method name identifier node
    (local.set $token_start (call $get_token_start (local.get $token_idx)))
    (local.set $method_name_node (call $create_expr_identifier (local.get $token_start) (call $get_token_length (local.get $token_idx))))

    ;; Check if method name is supported
    (if (i32.eqz (call $is_supported_meta_function (local.get $token_start) (call $get_token_length (local.get $token_idx))))
      (then
        ;; Error: unsupported meta-function
        (return (i32.const 0) (local.get $next_pos))
      )
    )

    ;; Create meta-function call node
    (local.set $call_node (call $create_expr_meta_call (local.get $target_node) (local.get $method_name_node)))

    ;; Check for optional parentheses
    (call $next_token (local.get $next_pos))
    (local.set $token_idx) ;; Get token index
    (drop) ;; Drop next position for now

    (local.set $token_type (call $get_token_type (local.get $token_idx)))

    (if (i32.ne (local.get $token_type) (global.get $TOKEN_LPAREN))
      (then
        ;; No parentheses - return as-is (paren-less syntax)
        (return (local.get $call_node) (local.get $next_pos))
      )
    )

    ;; Parse arguments with parentheses
    (local.set $current_pos (local.get $next_pos)) ;; Update position past opening paren

    ;; Parse arguments (similar to function calls)
    (block $parse_args_done
      (loop $parse_args_loop
        ;; Check for closing parenthesis
        (call $next_token (local.get $current_pos))
        (local.set $token_idx) ;; Get token index
        (drop) ;; Drop next position for now

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
        (drop (call $add_child (local.get $call_node) (local.get $arg_node)))

        ;; Check for comma or closing parenthesis
        (call $next_token (local.get $current_pos))
        (local.set $token_idx) ;; Get token index
        (drop) ;; Drop next position for now

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
        ;; Check if this is a function call (lookahead for parenthesis)
        (local.set $temp_pos (local.get $next_pos))
        (call $next_token (local.get $temp_pos))
        (drop) ;; Ignore next position
        (local.set $token_idx) ;; Get next token index
        (local.set $token_type (call $get_token_type (local.get $token_idx)))

        (if (i32.eq (local.get $token_type) (global.get $TOKEN_LPAREN))
          (then
            ;; This is a function call
            (call $parse_function_call_inline (local.get $pos))
            (local.set $next_pos)
            (local.set $ast_node)
            (return (local.get $ast_node) (local.get $next_pos))
          )
        )

        (if (i32.eq (local.get $token_type) (global.get $TOKEN_META))
          (then
            ;; This is a meta-function call
            (call $parse_meta_call_inline (local.get $pos))
            (local.set $next_pos)
            (local.set $ast_node)
            (return (local.get $ast_node) (local.get $next_pos))
          )
        )

        ;; Simple identifier - restore original token info
        (call $next_token (local.get $pos))
        (local.set $next_pos)
        (local.set $token_idx)
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
