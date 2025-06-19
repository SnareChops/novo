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
  (import "ast_control_flow_creators" "create_ctrl_if" (func $create_ctrl_if (param i32 i32 i32) (result i32)))
  (import "ast_control_flow_creators" "create_ctrl_while" (func $create_ctrl_while (param i32 i32) (result i32)))
  (import "ast_control_flow_creators" "create_ctrl_return" (func $create_ctrl_return (param i32) (result i32)))
  (import "ast_control_flow_creators" "create_ctrl_break" (func $create_ctrl_break (result i32)))
  (import "ast_control_flow_creators" "create_ctrl_continue" (func $create_ctrl_continue (result i32)))

  ;; Import expression parsing (for conditions and return values) - TODO: temporarily disabled
  (import "parser_expression_parsing" "parse_expression" (func $parse_expression (param i32) (result i32 i32)))

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

  ;; Parse if statement
  ;; Syntax: if condition { body } [else { body }]
  ;; @param pos i32 - Current position in input
  ;; @returns i32 i32 - AST node pointer, next position
  (func $parse_if_statement (export "parse_if_statement") (param $pos i32) (result i32 i32)
    (local $token_index i32)
    (local $token_type i32)
    (local $new_pos i32)
    (local $condition_node i32)
    (local $then_body i32)
    (local $else_body i32)
    (local $if_node i32)

    ;; Get current token (should be 'if')
    (call $next_token (local.get $pos))
    (local.set $new_pos) ;; Second return value (next position)
    (local.set $token_index) ;; First return value (token)

    (local.set $token_type (call $get_token_type (local.get $token_index)))

    ;; Verify this is an 'if' token
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_KW_IF))
      (then
        ;; Error: expected 'if'
        (return (i32.const 0) (local.get $pos))
      )
    )

    ;; Parse condition expression (placeholder for now)
    ;; TODO: Enable real expression parsing
    (local.set $condition_node (i32.const 42)) ;; Placeholder

    (if (i32.eqz (local.get $condition_node))
      (then
        ;; Error: failed to parse condition
        (return (i32.const 0) (local.get $new_pos))
      )
    )

    ;; For now, create simple placeholders and return basic if node
    (local.set $then_body (i32.const 1)) ;; Placeholder
    (local.set $else_body (i32.const 0)) ;; No else clause

    ;; Create if AST node
    (local.set $if_node (call $create_ctrl_if (local.get $condition_node) (local.get $then_body) (local.get $else_body)))

    ;; Return AST node and next position
    (return (local.get $if_node) (local.get $new_pos))
  )

  ;; Parse while statement
  ;; Syntax: while condition { body }
  ;; @param pos i32 - Current position in input
  ;; @returns i32 i32 - AST node pointer, next position
  (func $parse_while_statement (export "parse_while_statement") (param $pos i32) (result i32 i32)
    (local $token_index i32)
    (local $token_type i32)
    (local $new_pos i32)
    (local $condition_node i32)
    (local $body_node i32)
    (local $while_node i32)

    ;; Get current token (should be 'while')
    (call $next_token (local.get $pos))
    (local.set $new_pos) ;; Second return value (next position)
    (local.set $token_index) ;; First return value (token)

    (local.set $token_type (call $get_token_type (local.get $token_index)))

    ;; Verify this is a 'while' token
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_KW_WHILE))
      (then
        ;; Error: expected 'while'
        (return (i32.const 0) (local.get $pos))
      )
    )

    ;; Parse condition expression (placeholder for now)
    ;; TODO: Enable real expression parsing
    (local.set $condition_node (i32.const 43)) ;; Placeholder

    (if (i32.eqz (local.get $condition_node))
      (then
        ;; Error: failed to parse condition
        (return (i32.const 0) (local.get $new_pos))
      )
    )

    ;; For now, create a simple placeholder for the body
    (local.set $body_node (i32.const 1)) ;; Placeholder

    ;; Create while AST node
    (local.set $while_node (call $create_ctrl_while (local.get $condition_node) (local.get $body_node)))

    ;; Return AST node and next position
    (return (local.get $while_node) (local.get $new_pos))
  )

  ;; Helper function to skip to closing brace
  ;; @param pos i32 - Current position (should be after opening brace)
  ;; @returns i32 - Position after closing brace
  (func $skip_to_closing_brace (param $pos i32) (result i32)
    (local $token_index i32)
    (local $token_type i32)
    (local $new_pos i32)
    (local $brace_count i32)

    (local.set $new_pos (local.get $pos))
    (local.set $brace_count (i32.const 1)) ;; We're inside one brace already

    (loop $find_closing_brace
      (local.set $token_index (call $next_token (local.get $new_pos)))
      (local.set $new_pos (i32.and (local.get $token_index) (i32.const 0xFFFF)))
      (local.set $token_index (i32.shr_u (local.get $token_index) (i32.const 16)))
      (local.set $token_type (call $get_token_type (local.get $token_index)))

      (if (i32.eq (local.get $token_type) (global.get $TOKEN_EOF))
        (then
          ;; Reached end of input - return current position
          (return (local.get $new_pos))
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
              (return (local.get $new_pos))
            )
          )
        )
      )

      ;; Continue to next token
      (br $find_closing_brace)
    )

    (local.get $new_pos)
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
    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_IF))
      (then (return (call $parse_if_statement (local.get $pos))))
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_WHILE))
      (then (return (call $parse_while_statement (local.get $pos))))
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_RETURN))
      (then (return (call $parse_return_statement (local.get $pos))))
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_BREAK))
      (then (return (call $parse_break_statement (local.get $pos))))
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_CONTINUE))
      (then (return (call $parse_continue_statement (local.get $pos))))
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_IF))
      (then (return (call $parse_if_statement (local.get $pos))))
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_WHILE))
      (then (return (call $parse_while_statement (local.get $pos))))
    )

    ;; Not a control flow statement
    (return (i32.const 0) (local.get $pos))
  )
)
