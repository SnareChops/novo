;; WIT Type Mapping Utilities
;; Converts Novo AST type nodes to WIT format strings

(module
  ;; Import shared memory
  (import "memory" "memory" (memory 1))

  ;; Import AST node type constants
  (import "ast_node_types" "TYPE_PRIMITIVE" (global $TYPE_PRIMITIVE i32))
  (import "ast_node_types" "TYPE_LIST" (global $TYPE_LIST i32))
  (import "ast_node_types" "TYPE_OPTION" (global $TYPE_OPTION i32))
  (import "ast_node_types" "TYPE_RESULT" (global $TYPE_RESULT i32))
  (import "ast_node_types" "TYPE_TUPLE" (global $TYPE_TUPLE i32))
  (import "ast_node_types" "TYPE_RECORD" (global $TYPE_RECORD i32))
  (import "ast_node_types" "TYPE_VARIANT" (global $TYPE_VARIANT i32))
  (import "ast_node_types" "TYPE_ENUM" (global $TYPE_ENUM i32))
  (import "ast_node_types" "TYPE_FLAGS" (global $TYPE_FLAGS i32))
  (import "ast_node_types" "TYPE_RESOURCE" (global $TYPE_RESOURCE i32))

  (import "ast_node_types" "NODE_TYPE_OFFSET" (global $NODE_TYPE_OFFSET i32))
  (import "ast_node_types" "NODE_DATA_OFFSET" (global $NODE_DATA_OFFSET i32))

  ;; Primitive type IDs (from type-creators.wat comment)
  ;; 0=i32, 1=i64, 2=f32, 3=f64, 4=bool, 5=string
  (global $PRIM_I32 i32 (i32.const 0))
  (global $PRIM_I64 i32 (i32.const 1))
  (global $PRIM_F32 i32 (i32.const 2))
  (global $PRIM_F64 i32 (i32.const 3))
  (global $PRIM_BOOL i32 (i32.const 4))
  (global $PRIM_STRING i32 (i32.const 5))
  (global $output_buffer (mut i32) (i32.const 0))
  (global $output_position (mut i32) (i32.const 0))
  (global $output_capacity (mut i32) (i32.const 65536))  ;; 64KB

  ;; Initialize the output buffer at memory location 0
  (func $init_output_buffer (export "init_output_buffer")
    (global.set $output_buffer (i32.const 0))
    (global.set $output_position (i32.const 0)))

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

  ;; Convert a Novo type AST node to WIT format string
  ;; @param $type_node i32 - Pointer to type AST node
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $map_type_to_wit (export "map_type_to_wit") (param $type_node i32) (result i32)
    (local $node_type i32)

    ;; Handle null pointer
    (if (i32.eqz (local.get $type_node))
      (then (return (i32.const 0))))

    ;; Get node type
    (local.set $node_type
      (i32.load (i32.add (local.get $type_node) (global.get $NODE_TYPE_OFFSET))))

    ;; Handle primitive types
    (if (i32.eq (local.get $node_type) (global.get $TYPE_PRIMITIVE))
      (then (return (call $map_primitive_type (local.get $type_node)))))

    ;; Handle complex types
    (if (i32.eq (local.get $node_type) (global.get $TYPE_LIST))
      (then (return (call $map_list_type (local.get $type_node)))))

    (if (i32.eq (local.get $node_type) (global.get $TYPE_OPTION))
      (then (return (call $map_option_type (local.get $type_node)))))

    (if (i32.eq (local.get $node_type) (global.get $TYPE_RESULT))
      (then (return (call $map_result_type (local.get $type_node)))))

    ;; Unknown type
    (i32.const 0))

  ;; Map primitive type to WIT format
  ;; @param $prim_node i32 - Pointer to primitive type node
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $map_primitive_type (param $prim_node i32) (result i32)
    (local $type_id i32)

    ;; Get the primitive type ID from node data
    (local.set $type_id
      (i32.load (i32.add (local.get $prim_node) (global.get $NODE_DATA_OFFSET))))

    ;; Map based on type ID
    (if (i32.eq (local.get $type_id) (global.get $PRIM_I32))
      (then (call $write_literal (i32.const 1000) (i32.const 3)) (return (i32.const 1))))  ;; "s32"

    (if (i32.eq (local.get $type_id) (global.get $PRIM_I64))
      (then (call $write_literal (i32.const 1004) (i32.const 3)) (return (i32.const 1))))  ;; "s64"

    (if (i32.eq (local.get $type_id) (global.get $PRIM_F32))
      (then (call $write_literal (i32.const 1008) (i32.const 7)) (return (i32.const 1))))  ;; "float32"

    (if (i32.eq (local.get $type_id) (global.get $PRIM_F64))
      (then (call $write_literal (i32.const 1016) (i32.const 7)) (return (i32.const 1))))  ;; "float64"

    (if (i32.eq (local.get $type_id) (global.get $PRIM_BOOL))
      (then (call $write_literal (i32.const 1024) (i32.const 4)) (return (i32.const 1))))  ;; "bool"

    (if (i32.eq (local.get $type_id) (global.get $PRIM_STRING))
      (then (call $write_literal (i32.const 1029) (i32.const 6)) (return (i32.const 1))))  ;; "string"

    ;; Unknown primitive type
    (i32.const 0))

  ;; Map list type to WIT format: list<T>
  ;; @param $list_node i32 - Pointer to list type node
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $map_list_type (param $list_node i32) (result i32)
    ;; TODO: Extract element type from list node and recursively map
    ;; For now, return a placeholder
    (call $write_literal (i32.const 1036) (i32.const 11))  ;; "list<TODO>"
    (i32.const 1))

  ;; Map option type to WIT format: option<T>
  ;; @param $option_node i32 - Pointer to option type node
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $map_option_type (param $option_node i32) (result i32)
    ;; TODO: Extract wrapped type from option node and recursively map
    ;; For now, return a placeholder
    (call $write_literal (i32.const 1048) (i32.const 13))  ;; "option<TODO>"
    (i32.const 1))

  ;; Map result type to WIT format: result<T, E>
  ;; @param $result_node i32 - Pointer to result type node
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $map_result_type (param $result_node i32) (result i32)
    ;; TODO: Extract success and error types from result node and recursively map
    ;; For now, return a placeholder
    (call $write_literal (i32.const 1062) (i32.const 13))  ;; "result<TODO>"
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
  (data (i32.const 1000) "s32")        ;; offset 1000, length 3
  (data (i32.const 1004) "s64")        ;; offset 1004, length 3
  (data (i32.const 1008) "float32")    ;; offset 1008, length 7
  (data (i32.const 1016) "float64")    ;; offset 1016, length 7
  (data (i32.const 1024) "bool")       ;; offset 1024, length 4
  (data (i32.const 1029) "string")     ;; offset 1029, length 6
  (data (i32.const 1036) "list<TODO>") ;; offset 1036, length 11
  (data (i32.const 1048) "option<TODO>") ;; offset 1048, length 13
  (data (i32.const 1062) "result<TODO>") ;; offset 1062, length 13
)
