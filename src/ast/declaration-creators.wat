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
  (import "ast_node_types" "NODE_DATA_OFFSET" (global $NODE_DATA_OFFSET i32))

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
)
