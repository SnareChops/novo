;; AST Expression Node Creator Functions
;; Specialized functions for creating expression-related AST nodes
;; Handles literals, identifiers, binary operations, and function calls

(module $ast_expression_creators
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import core node functions
  (import "ast_node_core" "create_node" (func $create_node (param i32 i32) (result i32)))
  (import "ast_node_core" "add_child" (func $add_child (param i32 i32) (result i32)))

  ;; Import expression node type constants
  (import "ast_node_types" "EXPR_IDENTIFIER" (global $EXPR_IDENTIFIER i32))
  (import "ast_node_types" "EXPR_INTEGER_LITERAL" (global $EXPR_INTEGER_LITERAL i32))
  (import "ast_node_types" "EXPR_FLOAT_LITERAL" (global $EXPR_FLOAT_LITERAL i32))
  (import "ast_node_types" "EXPR_STRING_LITERAL" (global $EXPR_STRING_LITERAL i32))
  (import "ast_node_types" "EXPR_BOOL_LITERAL" (global $EXPR_BOOL_LITERAL i32))
  (import "ast_node_types" "EXPR_ADD" (global $EXPR_ADD i32))
  (import "ast_node_types" "EXPR_SUB" (global $EXPR_SUB i32))
  (import "ast_node_types" "EXPR_MUL" (global $EXPR_MUL i32))
  (import "ast_node_types" "EXPR_DIV" (global $EXPR_DIV i32))
  (import "ast_node_types" "EXPR_MOD" (global $EXPR_MOD i32))
  (import "ast_node_types" "EXPR_TRADITIONAL_CALL" (global $EXPR_TRADITIONAL_CALL i32))
  (import "ast_node_types" "EXPR_META_CALL" (global $EXPR_META_CALL i32))
  (import "ast_node_types" "NODE_DATA_OFFSET" (global $NODE_DATA_OFFSET i32))

  ;; Create a variable reference expression node
  ;; @param $name_ptr i32 - Pointer to variable name string
  ;; @param $name_len i32 - Length of variable name string
  ;; @returns i32 - Pointer to new node
  (func $create_expr_identifier (export "create_expr_identifier")
    (param $name_ptr i32) (param $name_len i32) (result i32)
    (local $node i32)
    (local $data_size i32)

    ;; Calculate data size (name length + size field)
    (local.set $data_size
      (i32.add
        (local.get $name_len)
        (i32.const 4)))

    ;; Create base node
    (local.set $node
      (call $create_node
        (global.get $EXPR_IDENTIFIER)
        (local.get $data_size)))

    ;; If allocation successful, copy data
    (if (local.get $node)
      (then
        ;; Store name length
        (i32.store
          (i32.add
            (local.get $node)
            (global.get $NODE_DATA_OFFSET))
          (local.get $name_len))
        ;; Copy name string
        (memory.copy
          (i32.add
            (local.get $node)
            (i32.add
              (global.get $NODE_DATA_OFFSET)
              (i32.const 4)))  ;; After length field
          (local.get $name_ptr)
          (local.get $name_len))))

    (local.get $node))

  ;; Create an integer literal expression node
  ;; @param $value i64 - Integer value
  ;; @returns i32 - Pointer to new node
  (func $create_expr_integer_literal (export "create_expr_integer_literal") (param $value i64) (result i32)
    (local $node i32)

    ;; Create base node with 8 bytes for i64 value
    (local.set $node
      (call $create_node
        (global.get $EXPR_INTEGER_LITERAL)
        (i32.const 8)))

    ;; If allocation successful, store value
    (if (local.get $node)
      (then
        (i64.store
          (i32.add
            (local.get $node)
            (global.get $NODE_DATA_OFFSET))
          (local.get $value))))

    (local.get $node))

  ;; Create a float literal expression node
  ;; @param $value f64 - Float value
  ;; @returns i32 - Pointer to new node
  (func $create_expr_float_literal (export "create_expr_float_literal") (param $value f64) (result i32)
    (local $node i32)

    ;; Create base node with 8 bytes for f64 value
    (local.set $node
      (call $create_node
        (global.get $EXPR_FLOAT_LITERAL)
        (i32.const 8)))

    ;; If allocation successful, store value
    (if (local.get $node)
      (then
        (f64.store
          (i32.add
            (local.get $node)
            (global.get $NODE_DATA_OFFSET))
          (local.get $value))))

    (local.get $node))

  ;; Create a boolean literal expression node
  ;; @param $value i32 - Boolean value (0 or 1)
  ;; @returns i32 - Pointer to new node
  (func $create_expr_bool_literal (export "create_expr_bool_literal") (param $value i32) (result i32)
    (local $node i32)

    ;; Create base node with 4 bytes for boolean value
    (local.set $node
      (call $create_node
        (global.get $EXPR_BOOL_LITERAL)
        (i32.const 4)))

    ;; If allocation successful, store value
    (if (local.get $node)
      (then
        (i32.store
          (i32.add
            (local.get $node)
            (global.get $NODE_DATA_OFFSET))
          (local.get $value))))

    ;; Return node pointer
    (local.get $node))

  ;; Create a string literal expression node
  ;; @param $str_ptr i32 - Pointer to string data
  ;; @param $str_len i32 - Length of string
  ;; @returns i32 - Pointer to new node
  (func $create_expr_string_literal (export "create_expr_string_literal")
    (param $str_ptr i32) (param $str_len i32) (result i32)
    (local $node i32)
    (local $data_size i32)

    ;; Calculate data size (string length + size field)
    (local.set $data_size
      (i32.add
        (local.get $str_len)
        (i32.const 4)))  ;; 4 bytes for length

    ;; Create base node with space for string data
    (local.set $node
      (call $create_node
        (global.get $EXPR_STRING_LITERAL)
        (local.get $data_size)))

    ;; If allocation successful, copy string data
    (if (local.get $node)
      (then
        ;; Store string length
        (i32.store
          (i32.add
            (local.get $node)
            (global.get $NODE_DATA_OFFSET))
          (local.get $str_len))

        ;; Copy string content
        (memory.copy
          (i32.add
            (i32.add
              (local.get $node)
              (global.get $NODE_DATA_OFFSET))
            (i32.const 4))        ;; Skip length field
          (local.get $str_ptr)
          (local.get $str_len))))

    ;; Return node pointer
    (local.get $node))

  ;; Create binary operation expression nodes
  ;; All binary operations store left and right operands as children

  ;; Create addition expression node
  (func $create_expr_add (export "create_expr_add") (param $left i32) (param $right i32) (result i32)
    (local $node i32)

    ;; Create base node (no additional data, operands are children)
    (local.set $node (call $create_node (global.get $EXPR_ADD) (i32.const 0)))

    ;; Add left and right operands as children
    (if (local.get $node)
      (then
        (drop (call $add_child (local.get $node) (local.get $left)))
        (drop (call $add_child (local.get $node) (local.get $right)))
      )
    )

    (local.get $node)
  )

  ;; Create subtraction expression node
  (func $create_expr_sub (export "create_expr_sub") (param $left i32) (param $right i32) (result i32)
    (local $node i32)

    (local.set $node (call $create_node (global.get $EXPR_SUB) (i32.const 0)))

    (if (local.get $node)
      (then
        (drop (call $add_child (local.get $node) (local.get $left)))
        (drop (call $add_child (local.get $node) (local.get $right)))
      )
    )

    (local.get $node)
  )

  ;; Create multiplication expression node
  (func $create_expr_mul (export "create_expr_mul") (param $left i32) (param $right i32) (result i32)
    (local $node i32)

    (local.set $node (call $create_node (global.get $EXPR_MUL) (i32.const 0)))

    (if (local.get $node)
      (then
        (drop (call $add_child (local.get $node) (local.get $left)))
        (drop (call $add_child (local.get $node) (local.get $right)))
      )
    )

    (local.get $node)
  )

  ;; Create division expression node
  (func $create_expr_div (export "create_expr_div") (param $left i32) (param $right i32) (result i32)
    (local $node i32)

    (local.set $node (call $create_node (global.get $EXPR_DIV) (i32.const 0)))

    (if (local.get $node)
      (then
        (drop (call $add_child (local.get $node) (local.get $left)))
        (drop (call $add_child (local.get $node) (local.get $right)))
      )
    )

    (local.get $node)
  )

  ;; Create modulo expression node
  (func $create_expr_mod (export "create_expr_mod") (param $left i32) (param $right i32) (result i32)
    (local $node i32)

    (local.set $node (call $create_node (global.get $EXPR_MOD) (i32.const 0)))

    (if (local.get $node)
      (then
        (drop (call $add_child (local.get $node) (local.get $left)))
        (drop (call $add_child (local.get $node) (local.get $right)))
      )
    )

    (local.get $node)
  )

  ;; Create traditional function call expression node
  (func $create_expr_traditional_call (export "create_expr_traditional_call") (param $func_name i32) (param $args_count i32) (result i32)
    (local $node i32)

    ;; Create base node with space for function name reference
    (local.set $node (call $create_node (global.get $EXPR_TRADITIONAL_CALL) (i32.const 4)))

    (if (local.get $node)
      (then
        ;; Store function name as first child
        (drop (call $add_child (local.get $node) (local.get $func_name)))
        ;; Arguments will be added as additional children by caller
      )
    )

    (local.get $node)
  )

  ;; Create meta-function call expression node
  (func $create_expr_meta_call (export "create_expr_meta_call") (param $target i32) (param $method i32) (result i32)
    (local $node i32)

    ;; Create base node (target and method are children)
    (local.set $node (call $create_node (global.get $EXPR_META_CALL) (i32.const 0)))

    (if (local.get $node)
      (then
        ;; Add target and method as children
        (drop (call $add_child (local.get $node) (local.get $target)))
        (drop (call $add_child (local.get $node) (local.get $method)))
        ;; Arguments will be added as additional children by caller
      )
    )

    (local.get $node)
  )
)
