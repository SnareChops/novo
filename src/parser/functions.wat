;; Novo Function Declaration Parser
;; Handles parsing of function declarations, parameters, return types, and function bodies

(module $novo_parser_functions
  ;; Import memory from lexer memory module
  (import "lexer_memory" "memory" (memory 1))

  ;; Import lexer functions
  (import "novo_lexer" "next_token" (func $next_token (param i32) (result i32 i32)))

  ;; Import token constants
  (import "lexer_tokens" "TOKEN_ERROR" (global $TOKEN_ERROR i32))
  (import "lexer_tokens" "TOKEN_EOF" (global $TOKEN_EOF i32))
  (import "lexer_tokens" "TOKEN_IDENTIFIER" (global $TOKEN_IDENTIFIER i32))
  (import "lexer_tokens" "TOKEN_KW_FUNC" (global $TOKEN_KW_FUNC i32))
  (import "lexer_tokens" "TOKEN_KW_INLINE" (global $TOKEN_KW_INLINE i32))
  (import "lexer_tokens" "TOKEN_LPAREN" (global $TOKEN_LPAREN i32))
  (import "lexer_tokens" "TOKEN_RPAREN" (global $TOKEN_RPAREN i32))
  (import "lexer_tokens" "TOKEN_LBRACE" (global $TOKEN_LBRACE i32))
  (import "lexer_tokens" "TOKEN_RBRACE" (global $TOKEN_RBRACE i32))
  (import "lexer_tokens" "TOKEN_COLON" (global $TOKEN_COLON i32))
  (import "lexer_tokens" "TOKEN_ASSIGN" (global $TOKEN_ASSIGN i32))
  (import "lexer_tokens" "TOKEN_ARROW" (global $TOKEN_ARROW i32))
  (import "lexer_tokens" "TOKEN_COMMA" (global $TOKEN_COMMA i32))

  ;; Import AST node types
  (import "ast_node_types" "DECL_FUNCTION" (global $DECL_FUNCTION i32))

  ;; Import AST creation functions
  (import "ast_declaration_creators" "create_decl_function" (func $create_decl_function (param i32 i32 i32) (result i32)))
  (import "ast_node_core" "add_child" (func $add_child (param i32 i32) (result i32)))

  ;; Import utility functions
  (import "parser_utils" "get_token_type" (func $get_token_type (param i32) (result i32)))
  (import "parser_utils" "get_token_start" (func $get_token_start (param i32) (result i32)))
  (import "parser_utils" "get_token_length" (func $get_token_length (param i32) (result i32)))

  ;; Import type parsing
  (import "parser_types" "parse_type" (func $parse_type (param i32) (result i32 i32)))

  ;; Parse a function declaration (simplified version for initial implementation)
  ;; @param pos i32 - Current position in input
  ;; @returns i32 i32 - AST node pointer, next position
  (func $parse_function_declaration (export "parse_function_declaration") (param $pos i32) (result i32 i32)
    (local $token i32)
    (local $token_type i32)
    (local $next_pos i32)
    (local $func_node i32)
    (local $func_name_start i32)
    (local $func_name_len i32)
    (local $current_pos i32)
    (local $is_inline i32)  ;; Track if function is declared inline

    (local.set $current_pos (local.get $pos))
    (local.set $is_inline (i32.const 0))  ;; Default to not inline

    ;; Get first token
    (call $next_token (local.get $current_pos))
    (local.set $next_pos) ;; Second return value (next position)
    (local.set $token) ;; First return value (token)
    (local.set $token_type (call $get_token_type (local.get $token)))

    ;; Check for optional 'inline' keyword
    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_INLINE))
      (then
        (local.set $is_inline (i32.const 1))  ;; Mark as inline
        (local.set $current_pos (local.get $next_pos))
        (call $next_token (local.get $current_pos))
        (local.set $next_pos) ;; Second return value (next position)
        (local.set $token) ;; First return value (token)
        (local.set $token_type (call $get_token_type (local.get $token)))
      )
    )

    ;; Check for 'func' keyword
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_KW_FUNC))
      (then
        ;; Error: expected 'func' keyword
        (return (i32.const 0) (local.get $current_pos))
      )
    )

    ;; Move past 'func' keyword
    (local.set $current_pos (local.get $next_pos))

    ;; Expect function name (identifier)
    (call $next_token (local.get $current_pos))
    (local.set $next_pos) ;; Second return value (next position)
    (local.set $token) ;; First return value (token)
    (local.set $token_type (call $get_token_type (local.get $token)))

    (if (i32.ne (local.get $token_type) (global.get $TOKEN_IDENTIFIER))
      (then
        ;; Error: expected function name
        (return (i32.const 0) (local.get $current_pos))
      )
    )

    ;; Get function name details
    (local.set $func_name_start (call $get_token_start (local.get $token)))
    (local.set $func_name_len (call $get_token_length (local.get $token)))

    ;; Create function declaration node with inline flag
    (local.set $func_node
      (call $create_decl_function
        (local.get $func_name_start)
        (local.get $func_name_len)
        (local.get $is_inline)))

    (if (i32.eqz (local.get $func_node))
      (then
        ;; Error: failed to create function node
        (return (i32.const 0) (local.get $current_pos))
      )
    )

    ;; Move past function name
    (local.set $current_pos (local.get $next_pos))

    ;; For now, skip to opening brace (simplified parsing)
    (local.set $current_pos (call $skip_to_brace (local.get $current_pos)))

    ;; Skip the function body (simplified - just find matching closing brace)
    (local.set $current_pos (call $skip_function_body (local.get $current_pos)))

    ;; Return function node and updated position
    (local.get $func_node)
    (local.get $current_pos)
  )

  ;; Helper function to skip to opening brace
  ;; @param pos i32 - Current position in input
  ;; @returns i32 - Position of opening brace (or after it)
  (func $skip_to_brace (param $pos i32) (result i32)
    (local $token i32)
    (local $token_type i32)
    (local $next_pos i32)
    (local $current_pos i32)

    (local.set $current_pos (local.get $pos))

    (loop $find_brace
      (call $next_token (local.get $current_pos))
      (local.set $next_pos) ;; Second return value (next position)
      (local.set $token) ;; First return value (token)
      (local.set $token_type (call $get_token_type (local.get $token)))

      (if (i32.eq (local.get $token_type) (global.get $TOKEN_EOF))
        (then
          ;; Reached end of input
          (return (local.get $current_pos))
        )
      )

      (if (i32.eq (local.get $token_type) (global.get $TOKEN_LBRACE))
        (then
          ;; Found opening brace - return position after it
          (return (local.get $next_pos))
        )
      )

      ;; Move to next token
      (local.set $current_pos (local.get $next_pos))
      (br $find_brace)
    )

    (local.get $current_pos)
  )

  ;; Helper function to skip function body (find matching closing brace)
  ;; @param pos i32 - Current position in input (should be after opening brace)
  ;; @returns i32 - Position after closing brace
  (func $skip_function_body (param $pos i32) (result i32)
    (local $token i32)
    (local $token_type i32)
    (local $next_pos i32)
    (local $brace_count i32)
    (local $current_pos i32)

    (local.set $current_pos (local.get $pos))
    (local.set $brace_count (i32.const 1)) ;; We've already seen opening brace

    (loop $skip_body
      (call $next_token (local.get $current_pos))
      (local.set $next_pos) ;; Second return value (next position)
      (local.set $token) ;; First return value (token)
      (local.set $token_type (call $get_token_type (local.get $token)))

      (if (i32.eq (local.get $token_type) (global.get $TOKEN_EOF))
        (then
          ;; Reached end of input
          (return (local.get $current_pos))
        )
      )

      (if (i32.eq (local.get $token_type) (global.get $TOKEN_LBRACE))
        (then
          ;; Found opening brace - increment count
          (local.set $brace_count (i32.add (local.get $brace_count) (i32.const 1)))
        )
      )

      (if (i32.eq (local.get $token_type) (global.get $TOKEN_RBRACE))
        (then
          ;; Found closing brace - decrement count
          (local.set $brace_count (i32.sub (local.get $brace_count) (i32.const 1)))

          ;; If count reaches zero, we found our matching brace
          (if (i32.eqz (local.get $brace_count))
            (then
              ;; Return position after closing brace
              (return (local.get $next_pos))
            )
          )
        )
      )

      ;; Move to next token
      (local.set $current_pos (local.get $next_pos))
      (br $skip_body)
    )

    (local.get $current_pos)
  )
)
