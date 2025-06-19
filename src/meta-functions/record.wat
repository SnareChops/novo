;; Meta Functions for Record Types
;; Implements record-specific meta functions like size()

(module $meta_functions_record
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import meta function core
  (import "meta_functions_core" "META_FUNC_SIZE" (global $META_FUNC_SIZE i32))

  ;; Import AST for record structure access
  (import "ast_node_types" "TYPE_RECORD" (global $TYPE_RECORD i32))
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "ast_node_core" "get_child_count" (func $get_child_count (param i32) (result i32)))
  (import "ast_node_core" "get_child" (func $get_child (param i32 i32) (result i32)))

  ;; Import numeric meta functions for field size calculation
  (import "meta_functions_numeric" "get_numeric_type_size" (func $get_numeric_type_size (param i32) (result i32)))

  ;; Import type constants
  (import "typechecker_main" "TYPE_STRING" (global $TYPE_STRING i32))
  (import "typechecker_main" "TYPE_BOOL" (global $TYPE_BOOL i32))

  ;; Calculate the total size of a record type
  ;; @param record_node: i32 - AST node representing the record
  ;; @returns i32 - Total size in bytes
  (func $get_record_size (export "get_record_size") (param $record_node i32) (result i32)
    (local $field_count i32)
    (local $i i32)
    (local $field_node i32)
    (local $field_type i32)
    (local $field_size i32)
    (local $total_size i32)

    ;; Verify this is a record node
    (if (i32.ne (call $get_node_type (local.get $record_node)) (global.get $TYPE_RECORD))
      (then (return (i32.const 0))))

    ;; Get field count
    (local.set $field_count (call $get_child_count (local.get $record_node)))
    (local.set $total_size (i32.const 0))
    (local.set $i (i32.const 0))

    ;; Iterate through all fields
    (loop $field_loop
      (if (i32.lt_u (local.get $i) (local.get $field_count))
        (then
          ;; Get field node
          (local.set $field_node (call $get_child (local.get $record_node) (local.get $i)))

          ;; Get field type (simplified - in a real implementation, you'd need proper type resolution)
          (local.set $field_type (call $get_node_type (local.get $field_node)))

          ;; Calculate field size
          (local.set $field_size (call $calculate_field_size (local.get $field_type)))

          ;; Add to total size
          (local.set $total_size (i32.add (local.get $total_size) (local.get $field_size)))

          ;; Next field
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $field_loop))))

    (local.get $total_size)
  )

  ;; Calculate the size of an individual field based on its type
  ;; @param field_type: i32 - Type constant for the field
  ;; @returns i32 - Size in bytes
  (func $calculate_field_size (param $field_type i32) (result i32)
    (local $field_size i32)

    ;; Try numeric type first
    (local.set $field_size (call $get_numeric_type_size (local.get $field_type)))
    (if (i32.ne (local.get $field_size) (i32.const 0))
      (then (return (local.get $field_size))))

    ;; Handle string type (pointer size)
    (if (i32.eq (local.get $field_type) (global.get $TYPE_STRING))
      (then (return (i32.const 8))))  ;; String represented as pointer + length

    ;; Handle bool type
    (if (i32.eq (local.get $field_type) (global.get $TYPE_BOOL))
      (then (return (i32.const 1))))

    ;; For complex types (records, variants, etc.), return placeholder size
    ;; In a real implementation, you'd need recursive size calculation
    (i32.const 4)  ;; Default size
  )

  ;; Generate string representation of a record
  ;; @param record_node: i32 - AST node representing the record
  ;; @param dest_ptr: i32 - Destination buffer for string
  ;; @returns i32 - Length of generated string
  (func $record_to_string (export "record_to_string") (param $record_node i32) (param $dest_ptr i32) (result i32)
    (local $field_count i32)
    (local $i i32)
    (local $current_ptr i32)
    (local $written_len i32)
    (local $field_node i32)

    ;; Start with opening brace
    (local.set $current_ptr (local.get $dest_ptr))
    (i32.store8 (local.get $current_ptr) (i32.const 123))  ;; '{'
    (local.set $current_ptr (i32.add (local.get $current_ptr) (i32.const 1)))
    (local.set $written_len (i32.const 1))

    ;; Get field count
    (local.set $field_count (call $get_child_count (local.get $record_node)))
    (local.set $i (i32.const 0))

    ;; Iterate through fields
    (loop $field_loop
      (if (i32.lt_u (local.get $i) (local.get $field_count))
        (then
          ;; Add comma for non-first fields
          (if (i32.gt_u (local.get $i) (i32.const 0))
            (then
              (i32.store8 (local.get $current_ptr) (i32.const 44))  ;; ','
              (local.set $current_ptr (i32.add (local.get $current_ptr) (i32.const 1)))
              (i32.store8 (local.get $current_ptr) (i32.const 32))  ;; ' '
              (local.set $current_ptr (i32.add (local.get $current_ptr) (i32.const 1)))
              (local.set $written_len (i32.add (local.get $written_len) (i32.const 2)))))

          ;; Get field node
          (local.set $field_node (call $get_child (local.get $record_node) (local.get $i)))

          ;; Add field representation (simplified)
          ;; In a real implementation, you'd format field_name: field_value
          (call $add_field_string (local.get $field_node) (local.get $current_ptr))
          (local.set $current_ptr (i32.add (local.get $current_ptr) (i32.const 8)))  ;; Assume 8 chars per field
          (local.set $written_len (i32.add (local.get $written_len) (i32.const 8)))

          ;; Next field
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $field_loop))))

    ;; End with closing brace
    (i32.store8 (local.get $current_ptr) (i32.const 125))  ;; '}'
    (local.set $written_len (i32.add (local.get $written_len) (i32.const 1)))

    (local.get $written_len)
  )

  ;; Helper function to add field string representation
  ;; @param field_node: i32 - Field AST node
  ;; @param dest_ptr: i32 - Destination pointer
  (func $add_field_string (param $field_node i32) (param $dest_ptr i32)
    ;; Simplified field representation
    ;; In a real implementation, you'd format: field_name: field_value
    (i32.store8 (local.get $dest_ptr) (i32.const 102))       ;; 'f'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 1)) (i32.const 105))  ;; 'i'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 2)) (i32.const 101))  ;; 'e'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 3)) (i32.const 108))  ;; 'l'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 4)) (i32.const 100))  ;; 'd'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 5)) (i32.const 58))   ;; ':'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 6)) (i32.const 88))   ;; 'X'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 7)) (i32.const 88))   ;; 'X'
  )

  ;; Get the type name of a record
  ;; @param record_node: i32 - AST node representing the record
  ;; @param dest_ptr: i32 - Destination buffer for type name
  ;; @returns i32 - Length of type name
  (func $get_record_type_name (export "get_record_type_name") (param $record_node i32) (param $dest_ptr i32) (result i32)
    ;; For now, just return "record"
    ;; In a real implementation, you'd return the actual record type name
    (i32.store8 (local.get $dest_ptr) (i32.const 114))       ;; 'r'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 1)) (i32.const 101))  ;; 'e'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 2)) (i32.const 99))   ;; 'c'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 3)) (i32.const 111))  ;; 'o'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 4)) (i32.const 114))  ;; 'r'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 5)) (i32.const 100))  ;; 'd'
    (i32.const 6)
  )

  ;; Check if record has a specific field
  ;; @param record_node: i32 - AST node representing the record
  ;; @param field_name_ptr: i32 - Pointer to field name string
  ;; @param field_name_len: i32 - Length of field name
  ;; @returns i32 - Field index if found, -1 if not found
  (func $find_record_field (export "find_record_field") (param $record_node i32) (param $field_name_ptr i32) (param $field_name_len i32) (result i32)
    (local $field_count i32)
    (local $i i32)
    (local $field_node i32)

    ;; Verify this is a record node
    (if (i32.ne (call $get_node_type (local.get $record_node)) (global.get $TYPE_RECORD))
      (then (return (i32.const -1))))

    ;; Get field count
    (local.set $field_count (call $get_child_count (local.get $record_node)))
    (local.set $i (i32.const 0))

    ;; Iterate through all fields
    (loop $field_search_loop
      (if (i32.lt_u (local.get $i) (local.get $field_count))
        (then
          ;; Get field node
          (local.set $field_node (call $get_child (local.get $record_node) (local.get $i)))

          ;; Check if field name matches (simplified comparison)
          ;; In a real implementation, you'd compare the actual field name
          ;; For now, just return the first field if searching for "field"
          (if (i32.eq (local.get $field_name_len) (i32.const 5))
            (then (return (local.get $i))))

          ;; Next field
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $field_search_loop))))

    ;; Field not found
    (i32.const -1)
  )
)
