;; Novo Pattern Matching Parser
;; Handles parsing of match statements and pattern destructuring

(module $parser_patterns
  ;; Import memory from lexer
  (import "lexer_memory" "memory" (memory 1))

  ;; Import lexer functions
  (import "novo_lexer" "next_token" (func $next_token (param i32) (result i32 i32)))

  ;; Import parser utilities
  (import "parser_utils" "get_token_type" (func $get_token_type (param i32) (result i32)))
  (import "parser_utils" "get_token_start" (func $get_token_start (param i32) (result i32)))
  (import "parser_utils" "get_token_length" (func $get_token_length (param i32) (result i32)))

  ;; Import token type globals
  (import "tokens" "TOKEN_KW_MATCH" (global $TOKEN_KW_MATCH i32))
  (import "tokens" "TOKEN_KW_SOME" (global $TOKEN_KW_SOME i32))
  (import "tokens" "TOKEN_KW_NONE" (global $TOKEN_KW_NONE i32))
  (import "tokens" "TOKEN_KW_OK" (global $TOKEN_KW_OK i32))
  (import "tokens" "TOKEN_KW_ERROR" (global $TOKEN_KW_ERROR i32))
  (import "tokens" "TOKEN_KW_TRUE" (global $TOKEN_KW_TRUE i32))
  (import "tokens" "TOKEN_KW_FALSE" (global $TOKEN_KW_FALSE i32))
  (import "tokens" "TOKEN_ARROW" (global $TOKEN_ARROW i32))
  (import "tokens" "TOKEN_LBRACE" (global $TOKEN_LBRACE i32))
  (import "tokens" "TOKEN_RBRACE" (global $TOKEN_RBRACE i32))
  (import "tokens" "TOKEN_LPAREN" (global $TOKEN_LPAREN i32))
  (import "tokens" "TOKEN_RPAREN" (global $TOKEN_RPAREN i32))
  (import "tokens" "TOKEN_COMMA" (global $TOKEN_COMMA i32))
  (import "tokens" "TOKEN_IDENTIFIER" (global $TOKEN_IDENTIFIER i32))
  (import "tokens" "TOKEN_NUMBER_LITERAL" (global $TOKEN_NUMBER_LITERAL i32))
  (import "tokens" "TOKEN_STRING_LITERAL" (global $TOKEN_STRING_LITERAL i32))

  ;; Import AST node type globals
  (import "ast_node_types" "CTRL_MATCH" (global $CTRL_MATCH i32))
  (import "ast_node_types" "CTRL_MATCH_ARM" (global $CTRL_MATCH_ARM i32))
  (import "ast_node_types" "PAT_LITERAL" (global $PAT_LITERAL i32))
  (import "ast_node_types" "PAT_VARIABLE" (global $PAT_VARIABLE i32))
  (import "ast_node_types" "PAT_TUPLE" (global $PAT_TUPLE i32))
  (import "ast_node_types" "PAT_RECORD" (global $PAT_RECORD i32))
  (import "ast_node_types" "PAT_VARIANT" (global $PAT_VARIANT i32))
  (import "ast_node_types" "PAT_OPTION_SOME" (global $PAT_OPTION_SOME i32))
  (import "ast_node_types" "PAT_OPTION_NONE" (global $PAT_OPTION_NONE i32))
  (import "ast_node_types" "PAT_RESULT_OK" (global $PAT_RESULT_OK i32))
  (import "ast_node_types" "PAT_RESULT_ERR" (global $PAT_RESULT_ERR i32))
  (import "ast_node_types" "PAT_LIST" (global $PAT_LIST i32))
  (import "ast_node_types" "PAT_WILDCARD" (global $PAT_WILDCARD i32))

  ;; Import AST pattern creators
  (import "ast_control_flow_creators" "create_match_node" (func $create_match_node (param i32) (result i32)))
  (import "ast_control_flow_creators" "create_match_arm_node" (func $create_match_arm_node (param i32 i32) (result i32)))
  (import "ast_pattern_creators" "create_pattern_literal_node" (func $create_pattern_literal_node (param i32 i32) (result i32)))
  (import "ast_pattern_creators" "create_pattern_variable_node" (func $create_pattern_variable_node (param i32) (result i32)))
  (import "ast_pattern_creators" "create_pattern_wildcard_node" (func $create_pattern_wildcard_node (result i32)))
  (import "ast_pattern_creators" "create_pattern_option_some_node" (func $create_pattern_option_some_node (param i32) (result i32)))
  (import "ast_pattern_creators" "create_pattern_option_none_node" (func $create_pattern_option_none_node (result i32)))
  (import "ast_pattern_creators" "create_pattern_result_ok_node" (func $create_pattern_result_ok_node (param i32) (result i32)))
  (import "ast_pattern_creators" "create_pattern_result_err_node" (func $create_pattern_result_err_node (param i32) (result i32)))

  ;; Import expression parsing (for match expression and arm bodies)
  (import "parser_expression_parsing" "parse_expression" (func $parse_expression (param i32) (result i32 i32)))

  ;; Import AST core functions
  (import "ast_node_core" "add_child" (func $add_child (param i32 i32) (result i32)))

  ;; Parse a pattern in a match arm
  ;; @param pos i32 - Current token position
  ;; @returns i32 i32 - (pattern_node_ptr << 16) | next_pos
  (func $parse_pattern (param $pos i32) (result i32 i32)
    (local $token_type i32)
    (local $pattern_node i32)
    (local $next_pos i32)

    (local.set $next_pos (local.get $pos))
    (local.set $token_type (call $get_token_type (local.get $pos)))

    (block $pattern_parsed
      ;; Parse identifier patterns (check for wildcard first, then variable binding)
      (if (i32.eq (local.get $token_type) (global.get $TOKEN_IDENTIFIER))
        (then
          ;; For now, treat all identifiers as variable patterns
          ;; TODO: Check if identifier is "_" for wildcard pattern
          (local.set $pattern_node (call $create_pattern_variable_node (local.get $pos)))
          (local.set $next_pos (i32.add (local.get $pos) (i32.const 1)))
          (br $pattern_parsed)
        )
      )

      ;; Parse literal patterns (numbers, strings, booleans)
      (if (i32.eq (local.get $token_type) (global.get $TOKEN_NUMBER_LITERAL))
        (then
          (local.set $pattern_node (call $create_pattern_literal_node (global.get $PAT_LITERAL) (local.get $pos)))
          (local.set $next_pos (i32.add (local.get $pos) (i32.const 1)))
          (br $pattern_parsed)
        )
      )

      (if (i32.eq (local.get $token_type) (global.get $TOKEN_STRING_LITERAL))
        (then
          (local.set $pattern_node (call $create_pattern_literal_node (global.get $PAT_LITERAL) (local.get $pos)))
          (local.set $next_pos (i32.add (local.get $pos) (i32.const 1)))
          (br $pattern_parsed)
        )
      )

      (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_TRUE))
        (then
          (local.set $pattern_node (call $create_pattern_literal_node (global.get $PAT_LITERAL) (local.get $pos)))
          (local.set $next_pos (i32.add (local.get $pos) (i32.const 1)))
          (br $pattern_parsed)
        )
      )

      (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_FALSE))
        (then
          (local.set $pattern_node (call $create_pattern_literal_node (global.get $PAT_LITERAL) (local.get $pos)))
          (local.set $next_pos (i32.add (local.get $pos) (i32.const 1)))
          (br $pattern_parsed)
        )
      )

      ;; Parse option patterns: some(pattern) and none
      (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_SOME))
        (then
          (local.set $next_pos (i32.add (local.get $pos) (i32.const 1)))
          ;; Expect '('
          (if (i32.ne (call $get_token_type (local.get $next_pos)) (global.get $TOKEN_LPAREN))
            (then
              ;; Error: expected '(' after 'some'
              (return (i32.const 0) (local.get $pos))
            )
          )
          (local.set $next_pos (i32.add (local.get $next_pos) (i32.const 1)))

          ;; Parse inner pattern (placeholder for now)
          (local.set $pattern_node (call $create_pattern_option_some_node (i32.const 0)))

          ;; Expect ')'
          (if (i32.ne (call $get_token_type (local.get $next_pos)) (global.get $TOKEN_RPAREN))
            (then
              ;; Error: expected ')' after pattern
              (return (i32.const 0) (local.get $pos))
            )
          )
          (local.set $next_pos (i32.add (local.get $next_pos) (i32.const 1)))
          (br $pattern_parsed)
        )
      )

      (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_NONE))
        (then
          (local.set $pattern_node (call $create_pattern_option_none_node))
          (local.set $next_pos (i32.add (local.get $pos) (i32.const 1)))
          (br $pattern_parsed)
        )
      )

      ;; Parse result patterns: ok(pattern) and error(pattern)
      (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_OK))
        (then
          (local.set $next_pos (i32.add (local.get $pos) (i32.const 1)))
          ;; Expect '('
          (if (i32.ne (call $get_token_type (local.get $next_pos)) (global.get $TOKEN_LPAREN))
            (then
              ;; Error: expected '(' after 'ok'
              (return (i32.const 0) (local.get $pos))
            )
          )
          (local.set $next_pos (i32.add (local.get $next_pos) (i32.const 1)))

          ;; Parse inner pattern (placeholder for now)
          (local.set $pattern_node (call $create_pattern_result_ok_node (i32.const 0)))

          ;; Expect ')'
          (if (i32.ne (call $get_token_type (local.get $next_pos)) (global.get $TOKEN_RPAREN))
            (then
              ;; Error: expected ')' after pattern
              (return (i32.const 0) (local.get $pos))
            )
          )
          (local.set $next_pos (i32.add (local.get $next_pos) (i32.const 1)))
          (br $pattern_parsed)
        )
      )

      (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_ERROR))
        (then
          (local.set $next_pos (i32.add (local.get $pos) (i32.const 1)))
          ;; Expect '('
          (if (i32.ne (call $get_token_type (local.get $next_pos)) (global.get $TOKEN_LPAREN))
            (then
              ;; Error: expected '(' after 'error'
              (return (i32.const 0) (local.get $pos))
            )
          )
          (local.set $next_pos (i32.add (local.get $next_pos) (i32.const 1)))

          ;; Parse inner pattern (placeholder for now)
          (local.set $pattern_node (call $create_pattern_result_err_node (i32.const 0)))

          ;; Expect ')'
          (if (i32.ne (call $get_token_type (local.get $next_pos)) (global.get $TOKEN_RPAREN))
            (then
              ;; Error: expected ')' after pattern
              (return (i32.const 0) (local.get $pos))
            )
          )
          (local.set $next_pos (i32.add (local.get $next_pos) (i32.const 1)))
          (br $pattern_parsed)
        )
      )

      ;; If no pattern matched, return error
      (return (i32.const 0) (local.get $pos))
    )

    ;; Return pattern node and next position
    (return (i32.shl (local.get $pattern_node) (i32.const 16)) (local.get $next_pos))
  )

  ;; Parse a match arm: pattern => expression
  ;; @param pos i32 - Current token position
  ;; @returns i32 i32 - (arm_node_ptr << 16) | next_pos
  (func $parse_match_arm (param $pos i32) (result i32 i32)
    (local $pattern_result i32)
    (local $pattern_node i32)
    (local $next_pos i32)
    (local $arm_node i32)
    (local $body_result i32)
    (local $body_node i32)

    ;; Parse the pattern
    (call $parse_pattern (local.get $pos))
    (local.set $next_pos)
    (local.set $pattern_result)

    (local.set $pattern_node (i32.shr_u (local.get $pattern_result) (i32.const 16)))
    (if (i32.eqz (local.get $pattern_node))
      (then
        ;; Pattern parsing failed
        (return (i32.const 0) (local.get $pos))
      )
    )

    ;; Expect '=>' arrow
    (if (i32.ne (call $get_token_type (local.get $next_pos)) (global.get $TOKEN_ARROW))
      (then
        ;; Error: expected '=>' after pattern
        (return (i32.const 0) (local.get $pos))
      )
    )
    (local.set $next_pos (i32.add (local.get $next_pos) (i32.const 1)))

    ;; Parse the expression body (placeholder for now - create simple identifier node)
    (local.set $body_node (i32.const 1)) ;; Placeholder body node

    ;; Create match arm node
    (local.set $arm_node (call $create_match_arm_node (local.get $pattern_node) (local.get $body_node)))

    ;; Return arm node and next position
    (return (i32.shl (local.get $arm_node) (i32.const 16)) (local.get $next_pos))
  )

  ;; Parse a match statement
  ;; @param pos i32 - Current token position
  ;; @returns i32 i32 - (match_node_ptr << 16) | next_pos
  (func $parse_match_statement (param $pos i32) (result i32 i32)
    (local $next_pos i32)
    (local $match_node i32)
    (local $expr_result i32)
    (local $expr_node i32)
    (local $arm_result i32)
    (local $arm_node i32)

    ;; Expect 'match' keyword
    (if (i32.ne (call $get_token_type (local.get $pos)) (global.get $TOKEN_KW_MATCH))
      (then
        ;; Not a match statement
        (return (i32.const 0) (local.get $pos))
      )
    )
    (local.set $next_pos (i32.add (local.get $pos) (i32.const 1)))

    ;; Parse match expression (placeholder for now)
    (local.set $expr_node (i32.const 1)) ;; Placeholder expression node

    ;; Expect '{'
    (if (i32.ne (call $get_token_type (local.get $next_pos)) (global.get $TOKEN_LBRACE))
      (then
        ;; Error: expected '{' after match expression
        (return (i32.const 0) (local.get $pos))
      )
    )
    (local.set $next_pos (i32.add (local.get $next_pos) (i32.const 1)))

    ;; Create match node
    (local.set $match_node (call $create_match_node (local.get $expr_node)))

    ;; Parse match arms (simplified - parse one arm for now)
    (call $parse_match_arm (local.get $next_pos))
    (local.set $next_pos)
    (local.set $arm_result)

    (local.set $arm_node (i32.shr_u (local.get $arm_result) (i32.const 16)))
    (if (local.get $arm_node)
      (then
        ;; Add arm as child to match node
        (drop (call $add_child (local.get $match_node) (local.get $arm_node)))
      )
    )

    ;; Expect '}' (placeholder - should parse multiple arms)
    (if (i32.ne (call $get_token_type (local.get $next_pos)) (global.get $TOKEN_RBRACE))
      (then
        ;; Error: expected '}' after match arms
        (return (i32.const 0) (local.get $pos))
      )
    )
    (local.set $next_pos (i32.add (local.get $next_pos) (i32.const 1)))

    ;; Return match node and next position
    (return (i32.shl (local.get $match_node) (i32.const 16)) (local.get $next_pos))
  )

  ;; Main pattern matching dispatcher
  ;; @param pos i32 - Current token position
  ;; @returns i32 i32 - (node_ptr << 16) | next_pos
  (func $parse_pattern_matching (export "parse_pattern_matching") (param $pos i32) (result i32 i32)
    (local $token_type i32)

    (local.set $token_type (call $get_token_type (local.get $pos)))

    ;; Check for match statement
    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_MATCH))
      (then
        (return (call $parse_match_statement (local.get $pos)))
      )
    )

    ;; No pattern matching construct found
    (return (i32.const 0) (local.get $pos))
  )
)
