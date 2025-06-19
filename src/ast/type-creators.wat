;; AST Type Node Creator Functions
;; Specialized functions for creating type-related AST nodes
;; Handles creation of primitive types, compound types (list, option, result, tuple)

(module $ast_type_creators
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import core node functions
  (import "ast_node_core" "create_node" (func $create_node (param i32 i32) (result i32)))
  (import "ast_node_core" "add_child" (func $add_child (param i32 i32) (result i32)))

  ;; Import type node constants
  (import "ast_node_types" "TYPE_PRIMITIVE" (global $TYPE_PRIMITIVE i32))
  (import "ast_node_types" "TYPE_LIST" (global $TYPE_LIST i32))
  (import "ast_node_types" "TYPE_OPTION" (global $TYPE_OPTION i32))
  (import "ast_node_types" "TYPE_RESULT" (global $TYPE_RESULT i32))
  (import "ast_node_types" "TYPE_TUPLE" (global $TYPE_TUPLE i32))
  (import "ast_node_types" "NODE_DATA_OFFSET" (global $NODE_DATA_OFFSET i32))

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

  ;; Create a list type node
  ;; @param $element_type i32 - Pointer to element type node
  ;; @returns i32 - Pointer to new node
  (func $create_type_list (export "create_type_list") (param $element_type i32) (result i32)
    (local $node i32)

    ;; Create base node with no extra data (children store the type info)
    (local.set $node
      (call $create_node
        (global.get $TYPE_LIST)
        (i32.const 0)))

    ;; If allocation successful and element type provided, add as child
    (if (i32.and
          (local.get $node)
          (local.get $element_type))
      (then
        (drop
          (call $add_child
            (local.get $node)
            (local.get $element_type)))))

    (local.get $node))

  ;; Create an option type node
  ;; @param $inner_type i32 - Pointer to inner type node
  ;; @returns i32 - Pointer to new node
  (func $create_type_option (export "create_type_option") (param $inner_type i32) (result i32)
    (local $node i32)

    ;; Create base node with no extra data (children store the type info)
    (local.set $node
      (call $create_node
        (global.get $TYPE_OPTION)
        (i32.const 0)))

    ;; If allocation successful and inner type provided, add as child
    (if (i32.and
          (local.get $node)
          (local.get $inner_type))
      (then
        (drop
          (call $add_child
            (local.get $node)
            (local.get $inner_type)))))

    (local.get $node))

  ;; Create a result type node
  ;; @param $ok_type i32 - Pointer to OK type node
  ;; @param $err_type i32 - Pointer to error type node
  ;; @returns i32 - Pointer to new node
  (func $create_type_result (export "create_type_result") (param $ok_type i32) (param $err_type i32) (result i32)
    (local $node i32)

    ;; Create base node with no extra data (children store the type info)
    (local.set $node
      (call $create_node
        (global.get $TYPE_RESULT)
        (i32.const 0)))

    ;; If allocation successful, add type children
    (if (local.get $node)
      (then
        ;; Add OK type as first child
        (if (local.get $ok_type)
          (then
            (drop
              (call $add_child
                (local.get $node)
                (local.get $ok_type)))))
        ;; Add error type as second child
        (if (local.get $err_type)
          (then
            (drop
              (call $add_child
                (local.get $node)
                (local.get $err_type)))))))

    (local.get $node))

  ;; Create a tuple type node
  ;; @param $element_count i32 - Number of elements (for validation)
  ;; @returns i32 - Pointer to new node
  ;; Note: Elements are added via add_child calls after creation
  (func $create_type_tuple (export "create_type_tuple") (param $element_count i32) (result i32)
    (local $node i32)

    ;; Create base node with 4 bytes to store element count
    (local.set $node
      (call $create_node
        (global.get $TYPE_TUPLE)
        (i32.const 4)))

    ;; If allocation successful, store element count
    (if (local.get $node)
      (then
        (i32.store
          (i32.add
            (local.get $node)
            (global.get $NODE_DATA_OFFSET))
          (local.get $element_count))))

    (local.get $node))
)
