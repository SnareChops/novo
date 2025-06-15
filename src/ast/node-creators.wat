;; AST Node Creator Functions
;; Specialized functions for creating specific types of AST nodes
;; Each function handles the creation and initialization of a particular node type

(module $ast_node_creators
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import core node functions
  (import "ast_node_core" "create_node" (func $create_node (param i32 i32) (result i32)))

  ;; Import node type constants
  (import "ast_node_types" "TYPE_PRIMITIVE" (global $TYPE_PRIMITIVE i32))
  (import "ast_node_types" "EXPR_IDENTIFIER" (global $EXPR_IDENTIFIER i32))
  (import "ast_node_types" "DECL_FUNCTION" (global $DECL_FUNCTION i32))
  (import "ast_node_types" "NODE_DATA_OFFSET" (global $NODE_DATA_OFFSET i32))
  (import "ast_node_types" "EXPR_INTEGER_LITERAL" (global $EXPR_INTEGER_LITERAL i32))
  (import "ast_node_types" "EXPR_FLOAT_LITERAL" (global $EXPR_FLOAT_LITERAL i32))
  (import "ast_node_types" "EXPR_STRING_LITERAL" (global $EXPR_STRING_LITERAL i32))
  (import "ast_node_types" "EXPR_BOOL_LITERAL" (global $EXPR_BOOL_LITERAL i32))

  ;; Create a primitive type node
  ;; @param $type_id i32 - Primitive type identifier (0=i32, 1=i64, 2=f32, 3=f64, 4=bool, 5=string)
  ;; @returns i32 - Pointer to new node
  (func $create_type_primitive (export "create_type_primitive") (param $type_id i32) (result i32)
    (local $node i32)

    ;; Create base node with 4 bytes for type_id
    (local.set $node
      (call $create_node
        (global.get $TYPE_PRIMITIVE)
        (i32.const 4)))

    ;; If allocation successful, store type_id
    (if (local.get $node)
      (then
        (i32.store
          (i32.add
            (local.get $node)
            (global.get $NODE_DATA_OFFSET))
          (local.get $type_id))))

    (local.get $node))

  ;; Create a function declaration node
  ;; @param $name_ptr i32 - Pointer to function name string
  ;; @param $name_len i32 - Length of function name string
  ;; @returns i32 - Pointer to new node
  (func $create_decl_function (export "create_decl_function")
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
        (global.get $DECL_FUNCTION)
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
)
