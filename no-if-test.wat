;; Test without if statements

(module $no_if_test
  (import "lexer_memory" "memory" (memory 1))
  (import "ast_node_creators" "create_ctrl_break" (func $create_ctrl_break (result i32)))

  ;; Simple function without if statements
  (func $parse_break_simple (export "parse_break_simple") (result i32)
    (local $node i32)
    (local.set $node (call $create_ctrl_break))
    (local.get $node)
  )
)
