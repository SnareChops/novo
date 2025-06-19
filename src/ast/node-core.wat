;; AST Node Core Operations
;; Core functions for creating and manipulating AST nodes
;; Handles basic node operations and tree structure management

(module $ast_node_core
  ;; Import memory from main AST module
  (import "ast_memory" "memory" (memory 4))

  ;; Import memory management functions
  (import "ast_memory" "allocate" (func $allocate (param i32) (result i32)))
  (import "ast_memory" "free" (func $free (param i32)))

  ;; Import node structure constants
  (import "ast_node_types" "NODE_TYPE_OFFSET" (global $NODE_TYPE_OFFSET i32))
  (import "ast_node_types" "NODE_SIZE_OFFSET" (global $NODE_SIZE_OFFSET i32))
  (import "ast_node_types" "NODE_NEXT_OFFSET" (global $NODE_NEXT_OFFSET i32))
  (import "ast_node_types" "NODE_CHILD_OFFSET" (global $NODE_CHILD_OFFSET i32))
  (import "ast_node_types" "NODE_DATA_OFFSET" (global $NODE_DATA_OFFSET i32))

  ;; Create node base structure with given type
  ;; @param $type i32 - Node type constant
  ;; @param $data_size i32 - Size of node-specific data
  ;; @returns i32 - Pointer to the new node (0 if allocation failed)
  (func $create_node (export "create_node") (param $type i32) (param $data_size i32) (result i32)
    (local $node_ptr i32)
    (local $total_size i32)

    ;; Calculate total node size (base + data)
    (local.set $total_size
      (i32.add
        (global.get $NODE_DATA_OFFSET)
        (local.get $data_size)))

    ;; Allocate memory for node
    (local.set $node_ptr
      (call $allocate (local.get $total_size)))

    ;; Return 0 if allocation failed
    (if (i32.eqz (local.get $node_ptr))
      (then (return (i32.const 0))))

    ;; Initialize node fields
    (i32.store
      (local.get $node_ptr)
      (local.get $type))  ;; Node type
    (i32.store offset=4
      (local.get $node_ptr)
      (local.get $total_size))  ;; Node size
    (i32.store offset=8
      (local.get $node_ptr)
      (i32.const 0))  ;; Next sibling
    (i32.store offset=12
      (local.get $node_ptr)
      (i32.const 0))  ;; First child

    (local.get $node_ptr))  ;; Return node pointer

  ;; Node relationship management functions

  ;; Add child node to parent
  ;; @param $parent i32 - Pointer to parent node
  ;; @param $child i32 - Pointer to child node
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $add_child (export "add_child") (param $parent i32) (param $child i32) (result i32)
    (local $curr i32)

    ;; Validate parameters
    (if (i32.or
          (i32.eqz (local.get $parent))
          (i32.eqz (local.get $child)))
      (then (return (i32.const 0))))

    ;; Check if parent has no children
    (local.set $curr
      (i32.load offset=12 (local.get $parent)))

    (if (i32.eqz (local.get $curr))
      (then
        ;; Set as first child
        (i32.store offset=12
          (local.get $parent)
          (local.get $child)))
      (else
        ;; Find last sibling
        (loop $find_last
          (local.set $curr
            (i32.load offset=8 (local.get $curr)))
          (if (local.get $curr)
            (then (br $find_last))))

        ;; Add as next sibling of last child
        (i32.store offset=8
          (local.get $curr)
          (local.get $child))))

    (i32.const 1))  ;; Success

  ;; Get node type
  ;; @param $node i32 - Pointer to node
  ;; @returns i32 - Node type constant
  (func $get_node_type (export "get_node_type") (param $node i32) (result i32)
    (if (i32.eqz (local.get $node))
      (then (return (i32.const -1))))

    (i32.load (local.get $node)))

  ;; Get node size
  ;; @param $node i32 - Pointer to node
  ;; @returns i32 - Node size in bytes
  (func $get_node_size (export "get_node_size") (param $node i32) (result i32)
    (if (i32.eqz (local.get $node))
      (then (return (i32.const 0))))

    (i32.load offset=4 (local.get $node)))

  ;; Get next sibling
  ;; @param $node i32 - Pointer to node
  ;; @returns i32 - Pointer to next sibling (0 if none)
  (func $get_next_sibling (export "get_next_sibling") (param $node i32) (result i32)
    (if (i32.eqz (local.get $node))
      (then (return (i32.const 0))))

    (i32.load offset=8 (local.get $node)))

  ;; Get first child
  ;; @param $node i32 - Pointer to node
  ;; @returns i32 - Pointer to first child (0 if none)
  (func $get_first_child (export "get_first_child") (param $node i32) (result i32)
    (if (i32.eqz (local.get $node))
      (then (return (i32.const 0))))

    (i32.load offset=12 (local.get $node)))

  ;; Free a node and all its children recursively
  ;; @param $node i32 - Pointer to node to free
  (func $free_node_tree (export "free_node_tree") (param $node i32)
    (local $child i32)
    (local $next_sibling i32)

    (if (i32.eqz (local.get $node))
      (then (return)))

    ;; Free all children first
    (local.set $child (call $get_first_child (local.get $node)))
    (loop $free_children
      (if (local.get $child)
        (then
          (local.set $next_sibling (call $get_next_sibling (local.get $child)))
          (call $free_node_tree (local.get $child))
          (local.set $child (local.get $next_sibling))
          (br $free_children))))

    ;; Free the node itself
    (call $free (local.get $node)))

  ;; Count the number of children for a node
  ;; @param $node i32 - Pointer to the node
  ;; @returns i32 - Number of children
  (func $get_child_count (export "get_child_count") (param $node i32) (result i32)
    (local $child i32)
    (local $count i32)

    (if (i32.eqz (local.get $node))
      (then (return (i32.const 0))))

    ;; Start with first child
    (local.set $child (call $get_first_child (local.get $node)))
    (local.set $count (i32.const 0))

    ;; Count all children by traversing sibling chain
    (loop $count_children
      (if (local.get $child)
        (then
          (local.set $count (i32.add (local.get $count) (i32.const 1)))
          (local.set $child (call $get_next_sibling (local.get $child)))
          (br $count_children))))

    (local.get $count))

  ;; Get the nth child of a node (0-indexed)
  ;; @param $node i32 - Pointer to the node
  ;; @param $index i32 - Index of child to get (0-based)
  ;; @returns i32 - Pointer to child node (0 if not found)
  (func $get_child (export "get_child") (param $node i32) (param $index i32) (result i32)
    (local $child i32)
    (local $current_index i32)

    (if (i32.eqz (local.get $node))
      (then (return (i32.const 0))))

    ;; Start with first child
    (local.set $child (call $get_first_child (local.get $node)))
    (local.set $current_index (i32.const 0))

    ;; Traverse to the nth child
    (loop $find_child
      (if (local.get $child)
        (then
          (if (i32.eq (local.get $current_index) (local.get $index))
            (then (return (local.get $child))))

          (local.set $current_index (i32.add (local.get $current_index) (i32.const 1)))
          (local.set $child (call $get_next_sibling (local.get $child)))
          (br $find_child))))

    ;; Not found
    (i32.const 0))

  ;; Get node value (first 4 bytes of node data)
  ;; @param $node i32 - Pointer to node
  ;; @returns i32 - Value stored in node data (0 if invalid node)
  (func $get_node_value (export "get_node_value") (param $node i32) (result i32)
    (if (i32.eqz (local.get $node))
      (then (return (i32.const 0))))

    ;; Load value from node data section
    (i32.load offset=16 (local.get $node)))
)
