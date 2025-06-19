;; Meta Functions Main Module
;; Main orchestration module for the meta function system

(module $meta_functions_main
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import all meta function modules
  (import "meta_functions_core" "identify_meta_function" (func $identify_meta_function (param i32 i32) (result i32)))
  (import "meta_functions_core" "is_meta_function_available" (func $is_meta_function_available (param i32 i32) (result i32)))
  (import "meta_functions_core" "get_meta_function_return_type" (func $get_meta_function_return_type (param i32 i32) (result i32)))
  (import "meta_functions_core" "init_meta_function_names" (func $init_meta_function_names))

  ;; Import numeric meta functions
  (import "meta_functions_numeric" "get_numeric_type_size" (func $get_numeric_type_size (param i32) (result i32)))
  (import "meta_functions_numeric" "get_numeric_type_name" (func $get_numeric_type_name (param i32 i32) (result i32)))
  (import "meta_functions_numeric" "numeric_value_to_string" (func $numeric_value_to_string (param i64 i32 i32) (result i32)))
  (import "meta_functions_numeric" "is_numeric_conversion_valid" (func $is_numeric_conversion_valid (param i32 i32) (result i32)))

  ;; Import memory access meta functions
  (import "meta_functions_memory" "load_memory_value" (func $load_memory_value (param i32 i32) (result i64)))
  (import "meta_functions_memory" "store_memory_value" (func $store_memory_value (param i32 i64 i32)))
  (import "meta_functions_memory" "load_memory_value_offset" (func $load_memory_value_offset (param i32 i32 i32 i32) (result i64)))
  (import "meta_functions_memory" "store_memory_value_offset" (func $store_memory_value_offset (param i32 i64 i32 i32 i32)))
  (import "meta_functions_memory" "get_default_alignment" (func $get_default_alignment (param i32) (result i32)))

  ;; Import record meta functions
  (import "meta_functions_record" "get_record_size" (func $get_record_size (param i32) (result i32)))
  (import "meta_functions_record" "record_to_string" (func $record_to_string (param i32 i32) (result i32)))
  (import "meta_functions_record" "get_record_type_name" (func $get_record_type_name (param i32 i32) (result i32)))

  ;; Import resource meta functions
  (import "meta_functions_resource" "resource_new" (func $resource_new (param i32 i32) (result i32)))
  (import "meta_functions_resource" "resource_destroy" (func $resource_destroy (param i32) (result i32)))
  (import "meta_functions_resource" "get_resource_size" (func $get_resource_size (param i32) (result i32)))
  (import "meta_functions_resource" "resource_to_string" (func $resource_to_string (param i32 i32) (result i32)))
  (import "meta_functions_resource" "init_resource_system" (func $init_resource_system))

  ;; Import meta function type constants
  (import "meta_functions_core" "META_FUNC_TYPE" (global $META_FUNC_TYPE i32))
  (import "meta_functions_core" "META_FUNC_STRING" (global $META_FUNC_STRING i32))
  (import "meta_functions_core" "META_FUNC_SIZE" (global $META_FUNC_SIZE i32))
  (import "meta_functions_core" "META_FUNC_CONVERT" (global $META_FUNC_CONVERT i32))
  (import "meta_functions_core" "META_FUNC_LOAD" (global $META_FUNC_LOAD i32))
  (import "meta_functions_core" "META_FUNC_STORE" (global $META_FUNC_STORE i32))
  (import "meta_functions_core" "META_FUNC_LOAD_OFFSET" (global $META_FUNC_LOAD_OFFSET i32))
  (import "meta_functions_core" "META_FUNC_STORE_OFFSET" (global $META_FUNC_STORE_OFFSET i32))
  (import "meta_functions_core" "META_FUNC_NEW" (global $META_FUNC_NEW i32))
  (import "meta_functions_core" "META_FUNC_DESTROY" (global $META_FUNC_DESTROY i32))

  ;; Import type constants
  (import "typechecker_main" "TYPE_STRING" (global $TYPE_STRING i32))
  (import "typechecker_main" "TYPE_U32" (global $TYPE_U32 i32))

  ;; Import AST node types
  (import "ast_node_types" "TYPE_RECORD" (global $TYPE_RECORD i32))
  (import "ast_node_types" "TYPE_RESOURCE" (global $TYPE_RESOURCE i32))

  ;; Import required AST and type checker functions
  (import "ast_node_core" "get_node_value" (func $get_node_value (param i32) (result i32)))
  (import "typechecker_main" "get_node_stored_type" (func $get_node_stored_type (param i32) (result i32)))

  ;; Initialize the meta function system
  (func $init_meta_functions (export "init_meta_functions")
    ;; Initialize meta function name strings
    (call $init_meta_function_names)

    ;; Initialize resource management system
    (call $init_resource_system)
  )

  ;; Process a meta function call
  ;; @param target_node: i32 - AST node for the target (left side of ::)
  ;; @param meta_func_name_ptr: i32 - Pointer to meta function name
  ;; @param meta_func_name_len: i32 - Length of meta function name
  ;; @param args_ptr: i32 - Pointer to arguments (optional)
  ;; @param result_ptr: i32 - Pointer to store result
  ;; @returns i32 - Result type or 0 on error
  (func $process_meta_function_call (export "process_meta_function_call")
    (param $target_node i32) (param $meta_func_name_ptr i32) (param $meta_func_name_len i32)
    (param $args_ptr i32) (param $result_ptr i32) (result i32)

    (local $meta_func_type i32)
    (local $target_type i32)
    (local $result_type i32)

    ;; Identify the meta function
    (local.set $meta_func_type (call $identify_meta_function (local.get $meta_func_name_ptr) (local.get $meta_func_name_len)))
    (if (i32.eqz (local.get $meta_func_type))
      (then (return (i32.const 0))))

    ;; Get the target type (would need proper type resolution in real implementation)
    (local.set $target_type (call $get_node_stored_type (local.get $target_node)))

    ;; Check if meta function is available for this type
    (if (i32.eqz (call $is_meta_function_available (local.get $meta_func_type) (local.get $target_type)))
      (then (return (i32.const 0))))

    ;; Get the return type
    (local.set $result_type (call $get_meta_function_return_type (local.get $meta_func_type) (local.get $target_type)))

    ;; Execute the meta function
    (call $execute_meta_function (local.get $meta_func_type) (local.get $target_node) (local.get $target_type) (local.get $args_ptr) (local.get $result_ptr))

    ;; Return the result type
    (local.get $result_type)
  )

  ;; Execute a specific meta function
  ;; @param meta_func_type: i32 - Meta function type constant
  ;; @param target_node: i32 - Target AST node
  ;; @param target_type: i32 - Target type
  ;; @param args_ptr: i32 - Arguments pointer
  ;; @param result_ptr: i32 - Result storage pointer
  (func $execute_meta_function (param $meta_func_type i32) (param $target_node i32) (param $target_type i32) (param $args_ptr i32) (param $result_ptr i32)
    ;; ::type() meta function
    (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_TYPE))
      (then
        (call $execute_type_meta_function (local.get $target_type) (local.get $result_ptr))
        (return)))

    ;; ::string() meta function
    (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_STRING))
      (then
        (call $execute_string_meta_function (local.get $target_node) (local.get $target_type) (local.get $result_ptr))
        (return)))

    ;; ::size() meta function
    (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_SIZE))
      (then
        (call $execute_size_meta_function (local.get $target_node) (local.get $target_type) (local.get $result_ptr))
        (return)))

    ;; Memory access meta functions
    (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_LOAD))
      (then
        (call $execute_load_meta_function (local.get $target_type) (local.get $args_ptr) (local.get $result_ptr))
        (return)))

    (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_STORE))
      (then
        (call $execute_store_meta_function (local.get $target_type) (local.get $args_ptr))
        (return)))

    ;; Resource meta functions
    (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_NEW))
      (then
        (call $execute_new_meta_function (local.get $target_type) (local.get $args_ptr) (local.get $result_ptr))
        (return)))

    (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_DESTROY))
      (then
        (call $execute_destroy_meta_function (local.get $target_node) (local.get $result_ptr))
        (return)))
  )

  ;; Execute ::type() meta function
  (func $execute_type_meta_function (param $target_type i32) (param $result_ptr i32)
    (local $len i32)

    ;; Get type name based on target type
    (local.set $len (call $get_numeric_type_name (local.get $target_type) (local.get $result_ptr)))
    (if (i32.gt_u (local.get $len) (i32.const 0))
      (then (return)))

    ;; Check for record type
    (if (i32.eq (local.get $target_type) (global.get $TYPE_RECORD))
      (then
        (call $get_record_type_name (i32.const 0) (local.get $result_ptr))
        (return)))

    ;; Check for string type
    (if (i32.eq (local.get $target_type) (global.get $TYPE_STRING))
      (then
        (i32.store8 (local.get $result_ptr) (i32.const 115))      ;; 's'
        (i32.store8 (i32.add (local.get $result_ptr) (i32.const 1)) (i32.const 116))  ;; 't'
        (i32.store8 (i32.add (local.get $result_ptr) (i32.const 2)) (i32.const 114))  ;; 'r'
        (i32.store8 (i32.add (local.get $result_ptr) (i32.const 3)) (i32.const 105))  ;; 'i'
        (i32.store8 (i32.add (local.get $result_ptr) (i32.const 4)) (i32.const 110))  ;; 'n'
        (i32.store8 (i32.add (local.get $result_ptr) (i32.const 5)) (i32.const 103))  ;; 'g'
        (return)))

    ;; Default: "unknown"
    (i32.store8 (local.get $result_ptr) (i32.const 117))         ;; 'u'
    (i32.store8 (i32.add (local.get $result_ptr) (i32.const 1)) (i32.const 110))  ;; 'n'
    (i32.store8 (i32.add (local.get $result_ptr) (i32.const 2)) (i32.const 107))  ;; 'k'
    (i32.store8 (i32.add (local.get $result_ptr) (i32.const 3)) (i32.const 110))  ;; 'n'
    (i32.store8 (i32.add (local.get $result_ptr) (i32.const 4)) (i32.const 111))  ;; 'o'
    (i32.store8 (i32.add (local.get $result_ptr) (i32.const 5)) (i32.const 119))  ;; 'w'
    (i32.store8 (i32.add (local.get $result_ptr) (i32.const 6)) (i32.const 110))  ;; 'n'
  )

  ;; Execute ::string() meta function
  (func $execute_string_meta_function (param $target_node i32) (param $target_type i32) (param $result_ptr i32)
    (local $size_result i32)

    ;; For numeric types, convert value to string
    (local.set $size_result (call $get_numeric_type_size (local.get $target_type)))
    (if (i32.gt_u (local.get $size_result) (i32.const 0))
      (then
        ;; This is a numeric type - would need to get the actual value
        ;; For now, just store a placeholder result
        (call $numeric_value_to_string (i64.const 42) (local.get $target_type) (local.get $result_ptr))
        (return)))

    ;; For record types
    (if (i32.eq (local.get $target_type) (global.get $TYPE_RECORD))
      (then
        (call $record_to_string (local.get $target_node) (local.get $result_ptr))
        (return)))

    ;; Default string representation
    (i32.store8 (local.get $result_ptr) (i32.const 88))         ;; 'X'
    (i32.store8 (i32.add (local.get $result_ptr) (i32.const 1)) (i32.const 88))  ;; 'X'
  )

  ;; Execute ::size() meta function
  (func $execute_size_meta_function (param $target_node i32) (param $target_type i32) (param $result_ptr i32)
    (local $size i32)

    ;; For numeric types
    (local.set $size (call $get_numeric_type_size (local.get $target_type)))
    (if (i32.gt_u (local.get $size) (i32.const 0))
      (then
        (i32.store (local.get $result_ptr) (local.get $size))
        (return)))

    ;; For record types
    (if (i32.eq (local.get $target_type) (global.get $TYPE_RECORD))
      (then
        (local.set $size (call $get_record_size (local.get $target_node)))
        (i32.store (local.get $result_ptr) (local.get $size))
        (return)))

    ;; For resource types
    (if (i32.eq (local.get $target_type) (global.get $TYPE_RESOURCE))
      (then
        (local.set $size (call $get_resource_size (local.get $target_type)))
        (i32.store (local.get $result_ptr) (local.get $size))
        (return)))

    ;; Default size
    (i32.store (local.get $result_ptr) (i32.const 0))
  )

  ;; Execute load meta function
  (func $execute_load_meta_function (param $target_type i32) (param $args_ptr i32) (param $result_ptr i32)
    (local $addr i32)
    (local $result i64)

    ;; Get address from arguments
    (local.set $addr (i32.load (local.get $args_ptr)))

    ;; Load value
    (local.set $result (call $load_memory_value (local.get $addr) (local.get $target_type)))

    ;; Store result
    (i64.store (local.get $result_ptr) (local.get $result))
  )

  ;; Execute store meta function
  (func $execute_store_meta_function (param $target_type i32) (param $args_ptr i32)
    (local $addr i32)
    (local $value i64)

    ;; Get address and value from arguments
    (local.set $addr (i32.load (local.get $args_ptr)))
    (local.set $value (i64.load (i32.add (local.get $args_ptr) (i32.const 8))))

    ;; Store value
    (call $store_memory_value (local.get $addr) (local.get $value) (local.get $target_type))
  )

  ;; Execute new meta function
  (func $execute_new_meta_function (param $target_type i32) (param $args_ptr i32) (param $result_ptr i32)
    (local $handle i32)

    ;; Create new resource
    (local.set $handle (call $resource_new (local.get $target_type) (local.get $args_ptr)))

    ;; Store result handle
    (i32.store (local.get $result_ptr) (local.get $handle))
  )

  ;; Execute destroy meta function
  (func $execute_destroy_meta_function (param $target_node i32) (param $result_ptr i32)
    (local $handle i32)
    (local $success i32)

    ;; Get resource handle from node (simplified)
    (local.set $handle (call $get_node_value (local.get $target_node)))

    ;; Destroy resource
    (local.set $success (call $resource_destroy (local.get $handle)))

    ;; Store success result
    (i32.store (local.get $result_ptr) (local.get $success))
  )
)
