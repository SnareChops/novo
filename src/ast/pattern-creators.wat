;; AST Pattern Node Creator Functions
;; Specialized functions for creating pattern matching AST nodes
;; Handles literal patterns, variable patterns, destructuring patterns, etc.

(module $ast_pattern_creators
  ;; Import memory
  (import "memory" "memory" (memory 1))

  ;; Import core node functions
  (import "ast_node_core" "create_node" (func $create_node (param i32 i32) (result i32)))
  (import "ast_node_core" "add_child" (func $add_child (param i32 i32) (result i32)))

  ;; Import pattern node type constants
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
  (import "ast_node_types" "NODE_DATA_OFFSET" (global $NODE_DATA_OFFSET i32))

  ;; Create pattern literal node
  ;; @param $pattern_type i32 - Pattern type constant
  ;; @param $token_pos i32 - Position of literal token
  ;; @returns i32 - Pointer to new node
  (func $create_pattern_literal_node (export "create_pattern_literal_node") (param $pattern_type i32) (param $token_pos i32) (result i32)
    (local $node i32)

    ;; Create node with 4 bytes for token position
    (local.set $node (call $create_node (local.get $pattern_type) (i32.const 4)))

    (if (local.get $node)
      (then
        ;; Store token position
        (i32.store
          (i32.add (local.get $node) (global.get $NODE_DATA_OFFSET))
          (local.get $token_pos))))

    (local.get $node)
  )

  ;; Create pattern variable node
  ;; @param $token_pos i32 - Position of identifier token
  ;; @returns i32 - Pointer to new node
  (func $create_pattern_variable_node (export "create_pattern_variable_node") (param $token_pos i32) (result i32)
    (local $node i32)

    ;; Create node with 4 bytes for token position
    (local.set $node (call $create_node (global.get $PAT_VARIABLE) (i32.const 4)))

    (if (local.get $node)
      (then
        ;; Store token position
        (i32.store
          (i32.add (local.get $node) (global.get $NODE_DATA_OFFSET))
          (local.get $token_pos))))

    (local.get $node)
  )

  ;; Create pattern wildcard node
  ;; @returns i32 - Pointer to new node
  (func $create_pattern_wildcard_node (export "create_pattern_wildcard_node") (result i32)
    ;; Wildcard pattern has no additional data
    (call $create_node (global.get $PAT_WILDCARD) (i32.const 0))
  )

  ;; Create pattern option some node
  ;; @param $inner_pattern i32 - Inner pattern node
  ;; @returns i32 - Pointer to new node
  (func $create_pattern_option_some_node (export "create_pattern_option_some_node") (param $inner_pattern i32) (result i32)
    (local $node i32)

    ;; Create node with 4 bytes for inner pattern pointer
    (local.set $node (call $create_node (global.get $PAT_OPTION_SOME) (i32.const 4)))

    (if (local.get $node)
      (then
        ;; Store inner pattern pointer
        (i32.store
          (i32.add (local.get $node) (global.get $NODE_DATA_OFFSET))
          (local.get $inner_pattern))))

    (local.get $node)
  )

  ;; Create pattern option none node
  ;; @returns i32 - Pointer to new node
  (func $create_pattern_option_none_node (export "create_pattern_option_none_node") (result i32)
    ;; None pattern has no additional data
    (call $create_node (global.get $PAT_OPTION_NONE) (i32.const 0))
  )

  ;; Create pattern result ok node
  ;; @param $inner_pattern i32 - Inner pattern node
  ;; @returns i32 - Pointer to new node
  (func $create_pattern_result_ok_node (export "create_pattern_result_ok_node") (param $inner_pattern i32) (result i32)
    (local $node i32)

    ;; Create node with 4 bytes for inner pattern pointer
    (local.set $node (call $create_node (global.get $PAT_RESULT_OK) (i32.const 4)))

    (if (local.get $node)
      (then
        ;; Store inner pattern pointer
        (i32.store
          (i32.add (local.get $node) (global.get $NODE_DATA_OFFSET))
          (local.get $inner_pattern))))

    (local.get $node)
  )

  ;; Create pattern result error node
  ;; @param $inner_pattern i32 - Inner pattern node
  ;; @returns i32 - Pointer to new node
  (func $create_pattern_result_err_node (export "create_pattern_result_err_node") (param $inner_pattern i32) (result i32)
    (local $node i32)

    ;; Create node with 4 bytes for inner pattern pointer
    (local.set $node (call $create_node (global.get $PAT_RESULT_ERR) (i32.const 4)))

    (if (local.get $node)
      (then
        ;; Store inner pattern pointer
        (i32.store
          (i32.add (local.get $node) (global.get $NODE_DATA_OFFSET))
          (local.get $inner_pattern))))

    (local.get $node)
  )

  ;; Create pattern literal node (generic)
  ;; @param $pattern_type i32 - Pattern type constant
  ;; @returns i32 - Pointer to new pattern literal node
  (func $create_pat_literal (export "create_pat_literal") (param $pattern_type i32) (result i32)
    (local $node i32)

    ;; Create base pattern node
    (local.set $node
      (call $create_node
        (local.get $pattern_type)
        (i32.const 0)))

    (local.get $node)
  )

  ;; Create pattern variable node (generic)
  ;; @param $pattern_type i32 - Pattern type constant
  ;; @returns i32 - Pointer to new pattern variable node
  (func $create_pat_variable (export "create_pat_variable") (param $pattern_type i32) (result i32)
    (local $node i32)

    ;; Create base pattern node
    (local.set $node
      (call $create_node
        (local.get $pattern_type)
        (i32.const 0)))

    (local.get $node)
  )

  ;; Create pattern wildcard node (generic)
  ;; @returns i32 - Pointer to new pattern wildcard node
  (func $create_pat_wildcard (export "create_pat_wildcard") (result i32)
    (local $node i32)

    ;; Create wildcard pattern node
    (local.set $node
      (call $create_node
        (global.get $PAT_WILDCARD)
        (i32.const 0)))

    (local.get $node)
  )

  ;; Create pattern tuple node
  ;; @param $element_count i32 - Number of elements in tuple
  ;; @returns i32 - Pointer to new pattern tuple node
  (func $create_pat_tuple (export "create_pat_tuple") (param $element_count i32) (result i32)
    (local $node i32)

    ;; Create tuple pattern node with space for element count
    (local.set $node
      (call $create_node
        (global.get $PAT_TUPLE)
        (i32.const 4)))

    (if (local.get $node)
      (then
        ;; Store element count
        (i32.store
          (i32.add (local.get $node) (global.get $NODE_DATA_OFFSET))
          (local.get $element_count))))

    (local.get $node)
  )

  ;; Create pattern record node
  ;; @param $field_count i32 - Number of fields in record
  ;; @returns i32 - Pointer to new pattern record node
  (func $create_pat_record (export "create_pat_record") (param $field_count i32) (result i32)
    (local $node i32)

    ;; Create record pattern node with space for field count
    (local.set $node
      (call $create_node
        (global.get $PAT_RECORD)
        (i32.const 4)))

    (if (local.get $node)
      (then
        ;; Store field count
        (i32.store
          (i32.add (local.get $node) (global.get $NODE_DATA_OFFSET))
          (local.get $field_count))))

    (local.get $node)
  )

  ;; Create pattern variant node
  ;; @param $variant_name_ptr i32 - Pointer to variant name string
  ;; @param $variant_name_len i32 - Length of variant name string
  ;; @returns i32 - Pointer to new pattern variant node
  (func $create_pat_variant (export "create_pat_variant") (param $variant_name_ptr i32) (param $variant_name_len i32) (result i32)
    (local $node i32)
    (local $data_size i32)

    ;; Calculate data size (name length + size field)
    (local.set $data_size
      (i32.add
        (local.get $variant_name_len)
        (i32.const 4)))

    ;; Create variant pattern node
    (local.set $node
      (call $create_node
        (global.get $PAT_VARIANT)
        (local.get $data_size)))

    (if (local.get $node)
      (then
        ;; Store name length
        (i32.store
          (i32.add (local.get $node) (global.get $NODE_DATA_OFFSET))
          (local.get $variant_name_len))
        ;; Copy name string
        (memory.copy
          (i32.add
            (local.get $node)
            (i32.add
              (global.get $NODE_DATA_OFFSET)
              (i32.const 4)))  ;; After length field
          (local.get $variant_name_ptr)
          (local.get $variant_name_len))))

    (local.get $node)
  )

  ;; Create pattern list node
  ;; @param $element_count i32 - Number of elements in list pattern
  ;; @returns i32 - Pointer to new pattern list node
  (func $create_pat_list (export "create_pat_list") (param $element_count i32) (result i32)
    (local $node i32)

    ;; Create list pattern node with space for element count
    (local.set $node
      (call $create_node
        (global.get $PAT_LIST)
        (i32.const 4)))

    (if (local.get $node)
      (then
        ;; Store element count
        (i32.store
          (i32.add (local.get $node) (global.get $NODE_DATA_OFFSET))
          (local.get $element_count))))

    (local.get $node)
  )
)
