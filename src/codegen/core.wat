;; Core Code Generation Infrastructure
;; Provides fundamental code generation utilities and state management

(module $codegen_core
  ;; Import memory for code generation workspace
  (import "lexer_memory" "memory" (memory 1))

  ;; Import AST for node traversal
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "ast_node_core" "get_child_count" (func $get_child_count (param i32) (result i32)))
  (import "ast_node_core" "get_child" (func $get_child (param i32 i32) (result i32)))
  (import "ast_node_core" "get_node_value" (func $get_node_value (param i32) (result i32)))

  ;; Import type checker for type information
  (import "typechecker_main" "get_node_type_info" (func $get_node_type_info (param i32) (result i32)))
  (import "typechecker_main" "TYPE_I32" (global $TYPE_I32 i32))
  (import "typechecker_main" "TYPE_I64" (global $TYPE_I64 i32))
  (import "typechecker_main" "TYPE_F32" (global $TYPE_F32 i32))
  (import "typechecker_main" "TYPE_F64" (global $TYPE_F64 i32))
  (import "typechecker_main" "TYPE_BOOL" (global $TYPE_BOOL i32))
  (import "typechecker_main" "TYPE_STRING" (global $TYPE_STRING i32))

  ;; Code generation workspace memory layout
  (global $CODEGEN_WORKSPACE_START i32 (i32.const 16384))
  (global $CODEGEN_WORKSPACE_SIZE i32 (i32.const 8192))
  (global $codegen_workspace_pos (mut i32) (i32.const 0))

  ;; Generated code output buffer
  (global $OUTPUT_BUFFER_START i32 (i32.const 24576))
  (global $OUTPUT_BUFFER_SIZE i32 (i32.const 16384))
  (global $output_buffer_pos (mut i32) (i32.const 0))

  ;; Local variable management
  (global $LOCAL_VAR_TABLE_START i32 (i32.const 40960))
  (global $LOCAL_VAR_TABLE_SIZE i32 (i32.const 2048))
  (global $LOCAL_VAR_ENTRY_SIZE i32 (i32.const 12)) ;; name_ptr(4) + type(4) + index(4)
  (global $local_var_count (mut i32) (i32.const 0))

  ;; Stack depth tracking for expressions
  (global $stack_depth (mut i32) (i32.const 0))
  (global $max_stack_depth (mut i32) (i32.const 0))

  ;; Initialize code generation state
  (func $init_codegen (export "init_codegen")
    (global.set $codegen_workspace_pos (i32.const 0))
    (global.set $output_buffer_pos (i32.const 0))
    (global.set $local_var_count (i32.const 0))
    (global.set $stack_depth (i32.const 0))
    (global.set $max_stack_depth (i32.const 0))
  )

  ;; Allocate workspace memory for temporary data
  ;; @param size i32 - Number of bytes to allocate
  ;; @returns i32 - Pointer to allocated memory (0 if out of space)
  (func $allocate_workspace (export "allocate_workspace") (param $size i32) (result i32)
    (local $current_pos i32)
    (local $new_pos i32)
    (local $workspace_ptr i32)

    (local.set $current_pos (global.get $codegen_workspace_pos))
    (local.set $new_pos (i32.add (local.get $current_pos) (local.get $size)))

    ;; Check if allocation would exceed workspace
    (if (i32.gt_u (local.get $new_pos) (global.get $CODEGEN_WORKSPACE_SIZE))
      (then (return (i32.const 0))))

    ;; Calculate workspace pointer and update position
    (local.set $workspace_ptr (i32.add (global.get $CODEGEN_WORKSPACE_START) (local.get $current_pos)))
    (global.set $codegen_workspace_pos (local.get $new_pos))

    (local.get $workspace_ptr)
  )

  ;; Write string to output buffer
  ;; @param str_ptr i32 - Pointer to string data
  ;; @param str_len i32 - Length of string
  ;; @returns i32 - 1 if successful, 0 if buffer full
  (func $write_output (export "write_output") (param $str_ptr i32) (param $str_len i32) (result i32)
    (local $current_pos i32)
    (local $new_pos i32)
    (local $output_ptr i32)
    (local $i i32)

    (local.set $current_pos (global.get $output_buffer_pos))
    (local.set $new_pos (i32.add (local.get $current_pos) (local.get $str_len)))

    ;; Check if write would exceed buffer
    (if (i32.gt_u (local.get $new_pos) (global.get $OUTPUT_BUFFER_SIZE))
      (then (return (i32.const 0))))

    ;; Copy string to output buffer
    (local.set $output_ptr (i32.add (global.get $OUTPUT_BUFFER_START) (local.get $current_pos)))
    (local.set $i (i32.const 0))

    (loop $copy_loop
      (if (i32.lt_u (local.get $i) (local.get $str_len))
        (then
          (i32.store8
            (i32.add (local.get $output_ptr) (local.get $i))
            (i32.load8_u (i32.add (local.get $str_ptr) (local.get $i))))

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $copy_loop))))

    (global.set $output_buffer_pos (local.get $new_pos))
    (i32.const 1)
  )

  ;; Get current output buffer contents
  ;; @param result_ptr i32 - Pointer to store result (ptr, len)
  (func $get_output_buffer (export "get_output_buffer") (param $result_ptr i32)
    (i32.store (local.get $result_ptr) (global.get $OUTPUT_BUFFER_START))
    (i32.store offset=4 (local.get $result_ptr) (global.get $output_buffer_pos))
  )

  ;; Track stack depth for expression evaluation
  (func $push_stack (export "push_stack")
    (local $new_depth i32)
    (local.set $new_depth (i32.add (global.get $stack_depth) (i32.const 1)))
    (global.set $stack_depth (local.get $new_depth))

    ;; Update max depth if needed
    (if (i32.gt_u (local.get $new_depth) (global.get $max_stack_depth))
      (then (global.set $max_stack_depth (local.get $new_depth))))
  )

  (func $pop_stack (export "pop_stack")
    (if (i32.gt_u (global.get $stack_depth) (i32.const 0))
      (then (global.set $stack_depth (i32.sub (global.get $stack_depth) (i32.const 1)))))
  )

  ;; Get current and maximum stack depth
  (func $get_stack_depth (export "get_stack_depth") (result i32)
    (global.get $stack_depth)
  )

  (func $get_max_stack_depth (export "get_max_stack_depth") (result i32)
    (global.get $max_stack_depth)
  )

  ;; Register a local variable for the current function
  ;; @param name_ptr i32 - Pointer to variable name
  ;; @param name_len i32 - Length of variable name
  ;; @param var_type i32 - Type ID of the variable
  ;; @returns i32 - Local variable index (negative if table full)
  (func $register_local_var (export "register_local_var") (param $name_ptr i32) (param $name_len i32) (param $var_type i32) (result i32)
    (local $entry_ptr i32)
    (local $index i32)

    ;; Check if local variable table is full
    (if (i32.ge_u
          (global.get $local_var_count)
          (i32.div_u (global.get $LOCAL_VAR_TABLE_SIZE) (global.get $LOCAL_VAR_ENTRY_SIZE)))
      (then (return (i32.const -1))))

    ;; Calculate entry pointer
    (local.set $entry_ptr
      (i32.add
        (global.get $LOCAL_VAR_TABLE_START)
        (i32.mul (global.get $local_var_count) (global.get $LOCAL_VAR_ENTRY_SIZE))))

    ;; Store variable information
    (i32.store (local.get $entry_ptr) (local.get $name_ptr))
    (i32.store offset=4 (local.get $entry_ptr) (local.get $var_type))
    (i32.store offset=8 (local.get $entry_ptr) (global.get $local_var_count))

    ;; Get current index and increment count
    (local.set $index (global.get $local_var_count))
    (global.set $local_var_count (i32.add (global.get $local_var_count) (i32.const 1)))

    (local.get $index)
  )

  ;; Look up local variable index by name
  ;; @param name_ptr i32 - Pointer to variable name
  ;; @param name_len i32 - Length of variable name
  ;; @returns i32 - Local variable index (negative if not found)
  (func $lookup_local_var (export "lookup_local_var") (param $name_ptr i32) (param $name_len i32) (result i32)
    (local $i i32)
    (local $entry_ptr i32)
    (local $stored_name_ptr i32)

    (local.set $i (i32.const 0))
    (loop $search_loop
      (if (i32.lt_u (local.get $i) (global.get $local_var_count))
        (then
          (local.set $entry_ptr
            (i32.add
              (global.get $LOCAL_VAR_TABLE_START)
              (i32.mul (local.get $i) (global.get $LOCAL_VAR_ENTRY_SIZE))))

          (local.set $stored_name_ptr (i32.load (local.get $entry_ptr)))

          ;; For now, simple pointer comparison (could be enhanced with string comparison)
          (if (i32.eq (local.get $stored_name_ptr) (local.get $name_ptr))
            (then (return (i32.load offset=8 (local.get $entry_ptr)))))

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $search_loop))))

    ;; Not found
    (i32.const -1)
  )

  ;; Clear local variables (called at end of function)
  (func $clear_local_vars (export "clear_local_vars")
    (global.set $local_var_count (i32.const 0))
  )

  ;; Get WebAssembly type string for a type ID
  ;; @param type_id i32 - Type ID from type checker
  ;; @param result_ptr i32 - Pointer to store result string info (ptr, len)
  (func $get_wasm_type_string (export "get_wasm_type_string") (param $type_id i32) (param $result_ptr i32)
    (if (i32.eq (local.get $type_id) (global.get $TYPE_I32))
      (then
        (i32.store (local.get $result_ptr) (i32.const 45056)) ;; "i32" stored at this location
        (i32.store offset=4 (local.get $result_ptr) (i32.const 3))
        (return)))

    (if (i32.eq (local.get $type_id) (global.get $TYPE_I64))
      (then
        (i32.store (local.get $result_ptr) (i32.const 45060)) ;; "i64"
        (i32.store offset=4 (local.get $result_ptr) (i32.const 3))
        (return)))

    (if (i32.eq (local.get $type_id) (global.get $TYPE_F32))
      (then
        (i32.store (local.get $result_ptr) (i32.const 45064)) ;; "f32"
        (i32.store offset=4 (local.get $result_ptr) (i32.const 3))
        (return)))

    (if (i32.eq (local.get $type_id) (global.get $TYPE_F64))
      (then
        (i32.store (local.get $result_ptr) (i32.const 45068)) ;; "f64"
        (i32.store offset=4 (local.get $result_ptr) (i32.const 3))
        (return)))

    ;; Default to i32 for unknown types
    (i32.store (local.get $result_ptr) (i32.const 45056))
    (i32.store offset=4 (local.get $result_ptr) (i32.const 3))
  )

  ;; Initialize static type strings in memory
  (func $init_type_strings (export "init_type_strings")
    ;; Store "i32" at offset 45056
    (i32.store8 offset=45056 (i32.const 0) (i32.const 105)) ;; 'i'
    (i32.store8 offset=45057 (i32.const 0) (i32.const 51))  ;; '3'
    (i32.store8 offset=45058 (i32.const 0) (i32.const 50))  ;; '2'

    ;; Store "i64" at offset 45060
    (i32.store8 offset=45060 (i32.const 0) (i32.const 105)) ;; 'i'
    (i32.store8 offset=45061 (i32.const 0) (i32.const 54))  ;; '6'
    (i32.store8 offset=45062 (i32.const 0) (i32.const 52))  ;; '4'

    ;; Store "f32" at offset 45064
    (i32.store8 offset=45064 (i32.const 0) (i32.const 102)) ;; 'f'
    (i32.store8 offset=45065 (i32.const 0) (i32.const 51))  ;; '3'
    (i32.store8 offset=45066 (i32.const 0) (i32.const 50))  ;; '2'

    ;; Store "f64" at offset 45068
    (i32.store8 offset=45068 (i32.const 0) (i32.const 102)) ;; 'f'
    (i32.store8 offset=45069 (i32.const 0) (i32.const 54))  ;; '6'
    (i32.store8 offset=45070 (i32.const 0) (i32.const 52))  ;; '4'
  )
)
