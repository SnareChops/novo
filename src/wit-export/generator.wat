;; WIT Export Generator
;; Generates WIT (WebAssembly Interface Types) files from Novo AST

(module
  ;; Import shared memory
  (import "memory" "memory" (memory 1))

  ;; Import AST node type constants
  (import "ast_node_types" "DECL_COMPONENT" (global $DECL_COMPONENT i32))
  (import "ast_node_types" "DECL_INTERFACE" (global $DECL_INTERFACE i32))
  (import "ast_node_types" "DECL_IMPORT" (global $DECL_IMPORT i32))
  (import "ast_node_types" "DECL_EXPORT" (global $DECL_EXPORT i32))
  (import "ast_node_types" "DECL_FUNCTION" (global $DECL_FUNCTION i32))
  (import "ast_node_types" "DECL_RECORD" (global $DECL_RECORD i32))
  (import "ast_node_types" "DECL_VARIANT" (global $DECL_VARIANT i32))
  (import "ast_node_types" "DECL_ENUM" (global $DECL_ENUM i32))
  (import "ast_node_types" "DECL_FLAGS" (global $DECL_FLAGS i32))
  (import "ast_node_types" "DECL_RESOURCE" (global $DECL_RESOURCE i32))

  (import "ast_node_types" "NODE_TYPE_OFFSET" (global $NODE_TYPE_OFFSET i32))
  (import "ast_node_types" "NODE_DATA_OFFSET" (global $NODE_DATA_OFFSET i32))
  (import "ast_node_types" "NODE_NEXT_OFFSET" (global $NODE_NEXT_OFFSET i32))
  (import "ast_node_types" "NODE_CHILD_OFFSET" (global $NODE_CHILD_OFFSET i32))

  ;; Import type mapping functions
  (import "wit_export_type_mapping" "init_output_buffer" (func $init_type_mapping))
  (import "wit_export_type_mapping" "map_type_to_wit" (func $map_type_to_wit (param i32) (result i32)))
  (import "wit_export_type_mapping" "get_output_buffer" (func $get_type_output_buffer (result i32)))
  (import "wit_export_type_mapping" "get_output_length" (func $get_type_output_length (result i32)))
  (import "wit_export_type_mapping" "reset_output" (func $reset_type_output))
  (global $output_buffer (mut i32) (i32.const 0))
  (global $output_position (mut i32) (i32.const 0))
  (global $output_capacity (mut i32) (i32.const 65536))  ;; 64KB

  ;; Initialize the output buffer at memory location 0
  (func $init_output_buffer (export "init_output_buffer")
    (global.set $output_buffer (i32.const 0))
    (global.set $output_position (i32.const 0))
    (call $init_type_mapping))

  ;; Helper function to write string to output buffer
  ;; @param $str_ptr i32 - Pointer to string
  ;; @param $str_len i32 - Length of string
  (func $write_to_output (param $str_ptr i32) (param $str_len i32)
    (local $new_pos i32)

    ;; Calculate new position
    (local.set $new_pos
      (i32.add (global.get $output_position) (local.get $str_len)))

    ;; Check if we have enough space
    (if (i32.lt_u (local.get $new_pos) (global.get $output_capacity))
      (then
        ;; Copy string to output buffer
        (memory.copy
          (i32.add (global.get $output_buffer) (global.get $output_position))
          (local.get $str_ptr)
          (local.get $str_len))
        ;; Update position
        (global.set $output_position (local.get $new_pos)))))

  ;; Write a literal string to output buffer
  ;; @param $str_offset i32 - Offset of string in this module's memory
  ;; @param $str_len i32 - Length of string
  (func $write_literal (param $str_offset i32) (param $str_len i32)
    (call $write_to_output (local.get $str_offset) (local.get $str_len)))

  ;; Write a newline character
  (func $write_newline
    (call $write_literal (i32.const 2000) (i32.const 1)))  ;; "\n"

  ;; Write an indentation (2 spaces)
  (func $write_indent
    (call $write_literal (i32.const 2002) (i32.const 2)))  ;; "  "

  ;; Write a node's name from its data section
  ;; @param $node i32 - Pointer to AST node
  (func $write_node_name (param $node i32)
    (local $name_len i32)
    (local $name_ptr i32)

    ;; Get name length from node data
    (local.set $name_len
      (i32.load (i32.add (local.get $node) (global.get $NODE_DATA_OFFSET))))

    ;; Get name pointer (after length field)
    (local.set $name_ptr
      (i32.add
        (local.get $node)
        (i32.add (global.get $NODE_DATA_OFFSET) (i32.const 4))))

    ;; Write name
    (call $write_to_output (local.get $name_ptr) (local.get $name_len)))

  ;; Generate WIT for a component declaration
  ;; @param $component_node i32 - Pointer to component AST node
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $generate_component_wit (export "generate_component_wit") (param $component_node i32) (result i32)
    (local $child i32)

    ;; Handle null pointer
    (if (i32.eqz (local.get $component_node))
      (then (return (i32.const 0))))

    ;; Write component header
    (call $write_literal (i32.const 2005) (i32.const 10))  ;; "component "
    (call $write_node_name (local.get $component_node))
    (call $write_literal (i32.const 2016) (i32.const 2))   ;; " {"
    (call $write_newline)

    ;; Process child nodes (imports, exports, etc.)
    (local.set $child
      (i32.load (i32.add (local.get $component_node) (global.get $NODE_CHILD_OFFSET))))

    (loop $child_loop
      (if (local.get $child)
        (then
          ;; Generate WIT for this child
          (call $generate_declaration_wit (local.get $child))

          ;; Move to next sibling
          (local.set $child
            (i32.load (i32.add (local.get $child) (global.get $NODE_NEXT_OFFSET))))

          (br $child_loop))))

    ;; Write component footer
    (call $write_literal (i32.const 2019) (i32.const 1))   ;; "}"
    (call $write_newline)

    (i32.const 1))

  ;; Generate WIT for an interface declaration
  ;; @param $interface_node i32 - Pointer to interface AST node
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $generate_interface_wit (export "generate_interface_wit") (param $interface_node i32) (result i32)
    (local $child i32)

    ;; Handle null pointer
    (if (i32.eqz (local.get $interface_node))
      (then (return (i32.const 0))))

    ;; Write interface header
    (call $write_literal (i32.const 2021) (i32.const 10))  ;; "interface "
    (call $write_node_name (local.get $interface_node))
    (call $write_literal (i32.const 2016) (i32.const 2))   ;; " {"
    (call $write_newline)

    ;; Process child nodes (type definitions, functions, etc.)
    (local.set $child
      (i32.load (i32.add (local.get $interface_node) (global.get $NODE_CHILD_OFFSET))))

    (loop $child_loop
      (if (local.get $child)
        (then
          ;; Generate WIT for this child
          (call $generate_declaration_wit (local.get $child))

          ;; Move to next sibling
          (local.set $child
            (i32.load (i32.add (local.get $child) (global.get $NODE_NEXT_OFFSET))))

          (br $child_loop))))

    ;; Write interface footer
    (call $write_literal (i32.const 2019) (i32.const 1))   ;; "}"
    (call $write_newline)

    (i32.const 1))

  ;; Generate WIT for an import declaration
  ;; @param $import_node i32 - Pointer to import AST node
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $generate_import_wit (param $import_node i32) (result i32)
    (local $data_offset i32)
    (local $module_len i32)
    (local $item_len i32)
    (local $module_ptr i32)
    (local $item_ptr i32)

    ;; Handle null pointer
    (if (i32.eqz (local.get $import_node))
      (then (return (i32.const 0))))

    ;; Get data offset
    (local.set $data_offset
      (i32.add (local.get $import_node) (global.get $NODE_DATA_OFFSET)))

    ;; Get module name length
    (local.set $module_len (i32.load (local.get $data_offset)))
    (local.set $data_offset (i32.add (local.get $data_offset) (i32.const 4)))

    ;; Get item name length
    (local.set $item_len (i32.load (local.get $data_offset)))
    (local.set $data_offset (i32.add (local.get $data_offset) (i32.const 4)))

    ;; Get module name pointer
    (local.set $module_ptr (local.get $data_offset))
    (local.set $data_offset (i32.add (local.get $data_offset) (local.get $module_len)))

    ;; Get item name pointer (if present)
    (local.set $item_ptr (local.get $data_offset))

    ;; Write import statement
    (call $write_indent)
    (call $write_literal (i32.const 2032) (i32.const 7))   ;; "import "
    (call $write_to_output (local.get $module_ptr) (local.get $module_len))

    ;; If there's a specific item, add it
    (if (local.get $item_len)
      (then
        (call $write_literal (i32.const 2040) (i32.const 1))  ;; "."
        (call $write_to_output (local.get $item_ptr) (local.get $item_len))))

    (call $write_newline)

    (i32.const 1))

  ;; Generate WIT for an export declaration
  ;; @param $export_node i32 - Pointer to export AST node
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $generate_export_wit (param $export_node i32) (result i32)
    (local $data_offset i32)
    (local $name_len i32)
    (local $alias_len i32)
    (local $name_ptr i32)
    (local $alias_ptr i32)

    ;; Handle null pointer
    (if (i32.eqz (local.get $export_node))
      (then (return (i32.const 0))))

    ;; Get data offset
    (local.set $data_offset
      (i32.add (local.get $export_node) (global.get $NODE_DATA_OFFSET)))

    ;; Get name length
    (local.set $name_len (i32.load (local.get $data_offset)))
    (local.set $data_offset (i32.add (local.get $data_offset) (i32.const 4)))

    ;; Get alias length
    (local.set $alias_len (i32.load (local.get $data_offset)))
    (local.set $data_offset (i32.add (local.get $data_offset) (i32.const 4)))

    ;; Get name pointer
    (local.set $name_ptr (local.get $data_offset))
    (local.set $data_offset (i32.add (local.get $data_offset) (local.get $name_len)))

    ;; Get alias pointer (if present)
    (local.set $alias_ptr (local.get $data_offset))

    ;; Write export statement
    (call $write_indent)
    (call $write_literal (i32.const 2042) (i32.const 7))   ;; "export "
    (call $write_to_output (local.get $name_ptr) (local.get $name_len))

    ;; If there's an alias, add it
    (if (local.get $alias_len)
      (then
        (call $write_literal (i32.const 2050) (i32.const 4))  ;; " as "
        (call $write_to_output (local.get $alias_ptr) (local.get $alias_len))))

    (call $write_newline)

    (i32.const 1))

  ;; Generate WIT for any declaration node type
  ;; @param $decl_node i32 - Pointer to declaration AST node
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $generate_declaration_wit (param $decl_node i32) (result i32)
    (local $node_type i32)

    ;; Handle null pointer
    (if (i32.eqz (local.get $decl_node))
      (then (return (i32.const 0))))

    ;; Get node type
    (local.set $node_type
      (i32.load (i32.add (local.get $decl_node) (global.get $NODE_TYPE_OFFSET))))

    ;; Handle based on declaration type
    (if (i32.eq (local.get $node_type) (global.get $DECL_COMPONENT))
      (then (return (call $generate_component_wit (local.get $decl_node)))))

    (if (i32.eq (local.get $node_type) (global.get $DECL_INTERFACE))
      (then (return (call $generate_interface_wit (local.get $decl_node)))))

    (if (i32.eq (local.get $node_type) (global.get $DECL_IMPORT))
      (then (return (call $generate_import_wit (local.get $decl_node)))))

    (if (i32.eq (local.get $node_type) (global.get $DECL_EXPORT))
      (then (return (call $generate_export_wit (local.get $decl_node)))))

    ;; TODO: Handle other declaration types (FUNCTION, RECORD, etc.)
    ;; For now, just skip them
    (i32.const 1))

  ;; Generate complete WIT file from an AST root
  ;; @param $ast_root i32 - Pointer to AST root node
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $generate_wit_file (export "generate_wit_file") (param $ast_root i32) (result i32)
    (local $current i32)

    ;; Initialize output buffer
    (call $init_output_buffer)

    ;; Handle null pointer
    (if (i32.eqz (local.get $ast_root))
      (then (return (i32.const 0))))

    ;; Traverse top-level declarations
    (local.set $current (local.get $ast_root))

    (loop $top_level_loop
      (if (local.get $current)
        (then
          ;; Generate WIT for this declaration
          (call $generate_declaration_wit (local.get $current))

          ;; Move to next sibling
          (local.set $current
            (i32.load (i32.add (local.get $current) (global.get $NODE_NEXT_OFFSET))))

          (br $top_level_loop))))

    (i32.const 1))

  ;; Get the current output buffer contents
  ;; @returns i32 - Pointer to output buffer
  (func $get_output_buffer (export "get_output_buffer") (result i32)
    (global.get $output_buffer))

  ;; Get the current output length
  ;; @returns i32 - Length of output in buffer
  (func $get_output_length (export "get_output_length") (result i32)
    (global.get $output_position))

  ;; Reset the output buffer
  (func $reset_output (export "reset_output")
    (global.set $output_position (i32.const 0)))

  ;; String literals stored in memory
  (data (i32.const 2000) "\n")        ;; offset 2000, length 1
  (data (i32.const 2002) "  ")        ;; offset 2002, length 2 (indent)
  (data (i32.const 2005) "component ")  ;; offset 2005, length 10
  (data (i32.const 2016) " {")        ;; offset 2016, length 2
  (data (i32.const 2019) "}")         ;; offset 2019, length 1
  (data (i32.const 2021) "interface ") ;; offset 2021, length 10
  (data (i32.const 2032) "import ")   ;; offset 2032, length 7
  (data (i32.const 2040) ".")         ;; offset 2040, length 1
  (data (i32.const 2042) "export ")   ;; offset 2042, length 7
  (data (i32.const 2050) " as ")      ;; offset 2050, length 4
)
