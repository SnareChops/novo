;; AST Declaration Node Creator Functions
;; Specialized functions for creating declaration AST nodes
;; Handles function declarations and other declaration types

(module $ast_declaration_creators
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import core node functions
  (import "ast_node_core" "create_node" (func $create_node (param i32 i32) (result i32)))
  (import "ast_node_core" "add_child" (func $add_child (param i32 i32) (result i32)))

  ;; Import declaration node type constants
  (import "ast_node_types" "DECL_FUNCTION" (global $DECL_FUNCTION i32))
  (import "ast_node_types" "DECL_COMPONENT" (global $DECL_COMPONENT i32))
  (import "ast_node_types" "DECL_INTERFACE" (global $DECL_INTERFACE i32))
  (import "ast_node_types" "DECL_IMPORT" (global $DECL_IMPORT i32))
  (import "ast_node_types" "DECL_EXPORT" (global $DECL_EXPORT i32))
  (import "ast_node_types" "NODE_DATA_OFFSET" (global $NODE_DATA_OFFSET i32))

  ;; Create a function declaration node
  ;; @param $name_ptr i32 - Pointer to function name string
  ;; @param $name_len i32 - Length of function name string
  ;; @param $is_inline i32 - 1 if function is declared inline, 0 otherwise
  ;; @returns i32 - Pointer to new node
  (func $create_decl_function (export "create_decl_function")
    (param $name_ptr i32) (param $name_len i32) (param $is_inline i32) (result i32)
    (local $node i32)
    (local $data_size i32)

    ;; Calculate data size (inline flag + name length + name string)
    (local.set $data_size
      (i32.add
        (i32.add
          (local.get $name_len)
          (i32.const 4))    ;; name length field
        (i32.const 4)))     ;; inline flag field

    ;; Create base node
    (local.set $node
      (call $create_node
        (global.get $DECL_FUNCTION)
        (local.get $data_size)))

    ;; If allocation successful, copy data
    (if (local.get $node)
      (then
        ;; Store inline flag
        (i32.store
          (i32.add
            (local.get $node)
            (global.get $NODE_DATA_OFFSET))
          (local.get $is_inline))
        ;; Store name length
        (i32.store
          (i32.add
            (local.get $node)
            (i32.add
              (global.get $NODE_DATA_OFFSET)
              (i32.const 4)))
          (local.get $name_len))
        ;; Copy name string
        (memory.copy
          (i32.add
            (local.get $node)
            (i32.add
              (global.get $NODE_DATA_OFFSET)
              (i32.const 8)))  ;; After inline flag and length field
          (local.get $name_ptr)
          (local.get $name_len))))

    (local.get $node))

  ;; Create a component declaration node
  ;; @param $name_ptr i32 - Pointer to component name string
  ;; @param $name_len i32 - Length of component name string
  ;; @returns i32 - Pointer to new node
  (func $create_decl_component (export "create_decl_component")
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
        (global.get $DECL_COMPONENT)
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

  ;; Create an interface declaration node
  ;; @param $name_ptr i32 - Pointer to interface name string
  ;; @param $name_len i32 - Length of interface name string
  ;; @returns i32 - Pointer to new node
  (func $create_decl_interface (export "create_decl_interface")
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
        (global.get $DECL_INTERFACE)
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

  ;; Create an import declaration node
  ;; @param $module_ptr i32 - Pointer to module name string
  ;; @param $module_len i32 - Length of module name string
  ;; @param $item_ptr i32 - Pointer to imported item string (can be 0 for whole module)
  ;; @param $item_len i32 - Length of imported item string (can be 0 for whole module)
  ;; @returns i32 - Pointer to new node
  (func $create_decl_import (export "create_decl_import")
    (param $module_ptr i32) (param $module_len i32)
    (param $item_ptr i32) (param $item_len i32) (result i32)
    (local $node i32)
    (local $data_size i32)
    (local $data_offset i32)

    ;; Calculate data size (two lengths + two strings)
    (local.set $data_size
      (i32.add
        (i32.add
          (local.get $module_len)
          (local.get $item_len))
        (i32.const 8)))  ;; Two length fields

    ;; Create base node
    (local.set $node
      (call $create_node
        (global.get $DECL_IMPORT)
        (local.get $data_size)))

    ;; If allocation successful, copy data
    (if (local.get $node)
      (then
        (local.set $data_offset (i32.add (local.get $node) (global.get $NODE_DATA_OFFSET)))

        ;; Store module name length
        (i32.store (local.get $data_offset) (local.get $module_len))
        (local.set $data_offset (i32.add (local.get $data_offset) (i32.const 4)))

        ;; Store item name length
        (i32.store (local.get $data_offset) (local.get $item_len))
        (local.set $data_offset (i32.add (local.get $data_offset) (i32.const 4)))

        ;; Copy module name string
        (memory.copy (local.get $data_offset) (local.get $module_ptr) (local.get $module_len))
        (local.set $data_offset (i32.add (local.get $data_offset) (local.get $module_len)))

        ;; Copy item name string (if present)
        (if (local.get $item_len)
          (then
            (memory.copy (local.get $data_offset) (local.get $item_ptr) (local.get $item_len))))))

    (local.get $node))

  ;; Create an export declaration node
  ;; @param $name_ptr i32 - Pointer to exported name string
  ;; @param $name_len i32 - Length of exported name string
  ;; @param $alias_ptr i32 - Pointer to export alias string (can be 0 for same name)
  ;; @param $alias_len i32 - Length of export alias string (can be 0 for same name)
  ;; @returns i32 - Pointer to new node
  (func $create_decl_export (export "create_decl_export")
    (param $name_ptr i32) (param $name_len i32)
    (param $alias_ptr i32) (param $alias_len i32) (result i32)
    (local $node i32)
    (local $data_size i32)
    (local $data_offset i32)

    ;; Calculate data size (two lengths + two strings)
    (local.set $data_size
      (i32.add
        (i32.add
          (local.get $name_len)
          (local.get $alias_len))
        (i32.const 8)))  ;; Two length fields

    ;; Create base node
    (local.set $node
      (call $create_node
        (global.get $DECL_EXPORT)
        (local.get $data_size)))

    ;; If allocation successful, copy data
    (if (local.get $node)
      (then
        (local.set $data_offset (i32.add (local.get $node) (global.get $NODE_DATA_OFFSET)))

        ;; Store name length
        (i32.store (local.get $data_offset) (local.get $name_len))
        (local.set $data_offset (i32.add (local.get $data_offset) (i32.const 4)))

        ;; Store alias length
        (i32.store (local.get $data_offset) (local.get $alias_len))
        (local.set $data_offset (i32.add (local.get $data_offset) (i32.const 4)))

        ;; Copy name string
        (memory.copy (local.get $data_offset) (local.get $name_ptr) (local.get $name_len))
        (local.set $data_offset (i32.add (local.get $data_offset) (local.get $name_len)))

        ;; Copy alias string (if present)
        (if (local.get $alias_len)
          (then
            (memory.copy (local.get $data_offset) (local.get $alias_ptr) (local.get $alias_len))))))

    (local.get $node))

  ;; Get the inline flag from a function declaration node
  ;; @param $node i32 - Pointer to function declaration node
  ;; @returns i32 - 1 if function is inline, 0 otherwise
  (func $get_function_inline_flag (export "get_function_inline_flag")
    (param $node i32) (result i32)
    (i32.load
      (i32.add
        (local.get $node)
        (global.get $NODE_DATA_OFFSET)))
  )

  ;; Get the name length from a function declaration node
  ;; @param $node i32 - Pointer to function declaration node
  ;; @returns i32 - Length of function name
  (func $get_function_name_length (export "get_function_name_length")
    (param $node i32) (result i32)
    (i32.load
      (i32.add
        (local.get $node)
        (i32.add
          (global.get $NODE_DATA_OFFSET)
          (i32.const 4))))
  )

  ;; Get pointer to the function name string
  ;; @param $node i32 - Pointer to function declaration node
  ;; @returns i32 - Pointer to function name string
  (func $get_function_name_ptr (export "get_function_name_ptr")
    (param $node i32) (result i32)
    (i32.add
      (local.get $node)
      (i32.add
        (global.get $NODE_DATA_OFFSET)
        (i32.const 8)))
  )
)
