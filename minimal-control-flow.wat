;; Minimal control flow test

(module $minimal_control_flow
  (import "lexer_memory" "memory" (memory 1))
  (import "novo_lexer" "next_token" (func $next_token (param i32) (result i32 i32)))
  (import "lexer_tokens" "TOKEN_KW_BREAK" (global $TOKEN_KW_BREAK i32))
  (import "parser_utils" "get_token_type" (func $get_token_type (param i32) (result i32)))
  (import "ast_node_creators" "create_ctrl_break" (func $create_ctrl_break (result i32)))

  ;; Simple break parser
  (func $parse_break_statement (export "parse_break_statement") (param $pos i32) (result i32)
    (local $token_index i32)
    (local $new_pos i32)

    ;; Get current token
    (local.set $token_index (call $next_token (local.get $pos)))
    (local.set $new_pos (i32.and (local.get $token_index) (i32.const 0xFFFF)))
    (local.set $token_index (i32.shr_u (local.get $token_index) (i32.const 16)))

    ;; Create break AST node
    (local.set $token_index (call $create_ctrl_break))

    ;; Return packed result
    (i32.or
      (i32.shl (local.get $token_index) (i32.const 16))
      (local.get $new_pos)
    )
  )
)
