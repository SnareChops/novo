;; AST Control Flow Node Creator Functions
;; Specialized functions for creating control flow AST nodes
;; Handles if/else, while loops, break, continue, return, and match statements

(module $ast_control_flow_creators
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import core node functions
  (import "ast_node_core" "create_node" (func $create_node (param i32 i32) (result i32)))
  (import "ast_node_core" "add_child" (func $add_child (param i32 i32) (result i32)))

  ;; Import control flow node type constants
  (import "ast_node_types" "CTRL_IF" (global $CTRL_IF i32))
  (import "ast_node_types" "CTRL_WHILE" (global $CTRL_WHILE i32))
  (import "ast_node_types" "CTRL_BREAK" (global $CTRL_BREAK i32))
  (import "ast_node_types" "CTRL_CONTINUE" (global $CTRL_CONTINUE i32))
  (import "ast_node_types" "CTRL_RETURN" (global $CTRL_RETURN i32))
  (import "ast_node_types" "CTRL_MATCH" (global $CTRL_MATCH i32))
  (import "ast_node_types" "CTRL_MATCH_ARM" (global $CTRL_MATCH_ARM i32))
  (import "ast_node_types" "NODE_DATA_OFFSET" (global $NODE_DATA_OFFSET i32))

  ;; Create if statement node
  ;; @param condition i32 - Pointer to condition expression
  ;; @param then_block i32 - Pointer to then block
  ;; @param else_block i32 - Pointer to else block (or 0 if no else)
  ;; @returns i32 - Pointer to new node
  (func $create_ctrl_if (export "create_ctrl_if") (param $condition i32) (param $then_block i32) (param $else_block i32) (result i32)
    (local $node i32)

    ;; Create base node with space for 3 pointers (condition, then, else)
    (local.set $node
      (call $create_node
        (global.get $CTRL_IF)
        (i32.const 12))) ;; 3 * 4 bytes

    ;; If allocation successful, store the pointers
    (if (local.get $node)
      (then
        ;; Store condition pointer
        (i32.store
          (i32.add (local.get $node) (global.get $NODE_DATA_OFFSET))
          (local.get $condition))

        ;; Store then block pointer
        (i32.store
          (i32.add (local.get $node) (i32.add (global.get $NODE_DATA_OFFSET) (i32.const 4)))
          (local.get $then_block))

        ;; Store else block pointer (may be 0)
        (i32.store
          (i32.add (local.get $node) (i32.add (global.get $NODE_DATA_OFFSET) (i32.const 8)))
          (local.get $else_block))))

    (local.get $node)
  )

  ;; Create while loop node
  ;; @param condition i32 - Pointer to condition expression
  ;; @param body i32 - Pointer to loop body
  ;; @returns i32 - Pointer to new node
  (func $create_ctrl_while (export "create_ctrl_while") (param $condition i32) (param $body i32) (result i32)
    (local $node i32)

    ;; Create base node with space for 2 pointers (condition, body)
    (local.set $node
      (call $create_node
        (global.get $CTRL_WHILE)
        (i32.const 8))) ;; 2 * 4 bytes

    ;; If allocation successful, store the pointers
    (if (local.get $node)
      (then
        ;; Store condition pointer
        (i32.store
          (i32.add (local.get $node) (global.get $NODE_DATA_OFFSET))
          (local.get $condition))

        ;; Store body pointer
        (i32.store
          (i32.add (local.get $node) (i32.add (global.get $NODE_DATA_OFFSET) (i32.const 4)))
          (local.get $body))))

    (local.get $node)
  )

  ;; Create return statement node
  ;; @param value i32 - Pointer to return value expression (or 0 for no value)
  ;; @returns i32 - Pointer to new node
  (func $create_ctrl_return (export "create_ctrl_return") (param $value i32) (result i32)
    (local $node i32)

    ;; Create base node with space for 1 pointer (value)
    (local.set $node
      (call $create_node
        (global.get $CTRL_RETURN)
        (i32.const 4))) ;; 1 * 4 bytes

    ;; If allocation successful, store the value pointer
    (if (local.get $node)
      (then
        (i32.store
          (i32.add (local.get $node) (global.get $NODE_DATA_OFFSET))
          (local.get $value))))

    (local.get $node)
  )

  ;; Create break statement node
  ;; @returns i32 - Pointer to new node
  (func $create_ctrl_break (export "create_ctrl_break") (result i32)
    ;; Break statement has no additional data
    (call $create_node (global.get $CTRL_BREAK) (i32.const 0))
  )

  ;; Create continue statement node
  ;; @returns i32 - Pointer to new node
  (func $create_ctrl_continue (export "create_ctrl_continue") (result i32)
    ;; Continue statement has no additional data
    (call $create_node (global.get $CTRL_CONTINUE) (i32.const 0))
  )

  ;; Create a match control flow node
  ;; @param $expression i32 - Pointer to expression being matched
  ;; @param $then_block i32 - Pointer to match arms block (optional)
  ;; @param $else_block i32 - Pointer to else block (optional)
  ;; @returns i32 - Pointer to new match node
  (func $create_ctrl_match (export "create_ctrl_match") (param $expression i32) (param $then_block i32) (param $else_block i32) (result i32)
    (local $node i32)

    ;; Create base node with no additional data
    (local.set $node
      (call $create_node
        (global.get $CTRL_MATCH)
        (i32.const 0)))

    ;; If allocation successful, add children
    (if (local.get $node)
      (then
        ;; Add expression as first child
        (if (local.get $expression)
          (then
            (drop (call $add_child (local.get $node) (local.get $expression)))))

        ;; Add then block as second child (if provided)
        (if (local.get $then_block)
          (then
            (drop (call $add_child (local.get $node) (local.get $then_block)))))

        ;; Add else block as third child (if provided)
        (if (local.get $else_block)
          (then
            (drop (call $add_child (local.get $node) (local.get $else_block)))))))

    (local.get $node)
  )

  ;; Create match statement node
  ;; @param $expr_node i32 - Expression to match against
  ;; @returns i32 - Pointer to new node
  (func $create_match_node (export "create_match_node") (param $expr_node i32) (result i32)
    (local $node i32)

    ;; Create node with 4 bytes for expression pointer
    (local.set $node (call $create_node (global.get $CTRL_MATCH) (i32.const 4)))

    (if (local.get $node)
      (then
        ;; Store expression node pointer
        (i32.store
          (i32.add (local.get $node) (global.get $NODE_DATA_OFFSET))
          (local.get $expr_node))))

    (local.get $node)
  )

  ;; Create match arm node
  ;; @param $pattern_node i32 - Pattern node
  ;; @param $body_node i32 - Body expression node
  ;; @returns i32 - Pointer to new node
  (func $create_match_arm_node (export "create_match_arm_node") (param $pattern_node i32) (param $body_node i32) (result i32)
    (local $node i32)

    ;; Create node with 8 bytes for pattern and body pointers
    (local.set $node (call $create_node (global.get $CTRL_MATCH_ARM) (i32.const 8)))

    (if (local.get $node)
      (then
        ;; Store pattern node pointer
        (i32.store
          (i32.add (local.get $node) (global.get $NODE_DATA_OFFSET))
          (local.get $pattern_node))
        ;; Store body node pointer
        (i32.store
          (i32.add (local.get $node) (i32.add (global.get $NODE_DATA_OFFSET) (i32.const 4)))
          (local.get $body_node))))

    (local.get $node)
  )

  ;; Create control flow match arm node
  ;; @param $pattern i32 - Pointer to pattern node
  ;; @param $body i32 - Pointer to body node
  ;; @returns i32 - Pointer to new match arm node
  (func $create_ctrl_match_arm (export "create_ctrl_match_arm") (param $pattern i32) (param $body i32) (result i32)
    (local $node i32)

    ;; Create base node with no additional data
    (local.set $node
      (call $create_node
        (global.get $CTRL_MATCH_ARM)
        (i32.const 0)))

    ;; If allocation successful, add children
    (if (local.get $node)
      (then
        ;; Add pattern as first child
        (if (local.get $pattern)
          (then
            (drop (call $add_child (local.get $node) (local.get $pattern)))))

        ;; Add body as second child
        (if (local.get $body)
          (then
            (drop (call $add_child (local.get $node) (local.get $body)))))))

    (local.get $node)
  )
)
