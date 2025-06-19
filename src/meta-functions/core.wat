;; Meta Functions Core Infrastructure
;; Implements the core meta function system for Novo

(module $meta_functions_core
  ;; Import memory for string storage and data management
  (import "lexer_memory" "memory" (memory 1))

  ;; Import AST for node handling
  (import "ast_node_types" "EXPR_META_CALL" (global $EXPR_META_CALL i32))
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))

  ;; Import type checker for type information
  (import "typechecker_main" "get_node_stored_type" (func $get_node_stored_type (param i32) (result i32)))
  (import "typechecker_main" "TYPE_I32" (global $TYPE_I32 i32))
  (import "typechecker_main" "TYPE_I64" (global $TYPE_I64 i32))
  (import "typechecker_main" "TYPE_F32" (global $TYPE_F32 i32))
  (import "typechecker_main" "TYPE_F64" (global $TYPE_F64 i32))
  (import "typechecker_main" "TYPE_BOOL" (global $TYPE_BOOL i32))
  (import "typechecker_main" "TYPE_STRING" (global $TYPE_STRING i32))
  (import "typechecker_main" "TYPE_U8" (global $TYPE_U8 i32))
  (import "typechecker_main" "TYPE_U16" (global $TYPE_U16 i32))
  (import "typechecker_main" "TYPE_U32" (global $TYPE_U32 i32))
  (import "typechecker_main" "TYPE_U64" (global $TYPE_U64 i32))

  ;; Meta function type constants
  (global $META_FUNC_TYPE i32 (i32.const 1))
  (global $META_FUNC_STRING i32 (i32.const 2))
  (global $META_FUNC_SIZE i32 (i32.const 3))
  (global $META_FUNC_CONVERT i32 (i32.const 4))
  (global $META_FUNC_LOAD i32 (i32.const 5))
  (global $META_FUNC_STORE i32 (i32.const 6))
  (global $META_FUNC_LOAD_OFFSET i32 (i32.const 7))
  (global $META_FUNC_STORE_OFFSET i32 (i32.const 8))
  (global $META_FUNC_NEW i32 (i32.const 9))
  (global $META_FUNC_DESTROY i32 (i32.const 10))

  ;; Export meta function type constants
  (export "META_FUNC_TYPE" (global $META_FUNC_TYPE))
  (export "META_FUNC_STRING" (global $META_FUNC_STRING))
  (export "META_FUNC_SIZE" (global $META_FUNC_SIZE))
  (export "META_FUNC_CONVERT" (global $META_FUNC_CONVERT))
  (export "META_FUNC_LOAD" (global $META_FUNC_LOAD))
  (export "META_FUNC_STORE" (global $META_FUNC_STORE))
  (export "META_FUNC_LOAD_OFFSET" (global $META_FUNC_LOAD_OFFSET))
  (export "META_FUNC_STORE_OFFSET" (global $META_FUNC_STORE_OFFSET))
  (export "META_FUNC_NEW" (global $META_FUNC_NEW))
  (export "META_FUNC_DESTROY" (global $META_FUNC_DESTROY))

  ;; Check if a string matches a meta function name
  ;; @param name_ptr: i32 - Pointer to the meta function name string
  ;; @param name_len: i32 - Length of the meta function name
  ;; @returns i32 - Meta function type constant or 0 if not found
  (func $identify_meta_function (export "identify_meta_function") (param $name_ptr i32) (param $name_len i32) (result i32)
    ;; Check for "type" meta function
    (if (call $string_equals (local.get $name_ptr) (local.get $name_len) (i32.const 512) (i32.const 4))
      (then (return (global.get $META_FUNC_TYPE))))

    ;; Check for "string" meta function
    (if (call $string_equals (local.get $name_ptr) (local.get $name_len) (i32.const 520) (i32.const 6))
      (then (return (global.get $META_FUNC_STRING))))

    ;; Check for "size" meta function
    (if (call $string_equals (local.get $name_ptr) (local.get $name_len) (i32.const 528) (i32.const 4))
      (then (return (global.get $META_FUNC_SIZE))))

    ;; Check for "load" meta function
    (if (call $string_equals (local.get $name_ptr) (local.get $name_len) (i32.const 536) (i32.const 4))
      (then (return (global.get $META_FUNC_LOAD))))

    ;; Check for "store" meta function
    (if (call $string_equals (local.get $name_ptr) (local.get $name_len) (i32.const 544) (i32.const 5))
      (then (return (global.get $META_FUNC_STORE))))

    ;; Check for "load_offset" meta function
    (if (call $string_equals (local.get $name_ptr) (local.get $name_len) (i32.const 552) (i32.const 11))
      (then (return (global.get $META_FUNC_LOAD_OFFSET))))

    ;; Check for "store_offset" meta function
    (if (call $string_equals (local.get $name_ptr) (local.get $name_len) (i32.const 568) (i32.const 12))
      (then (return (global.get $META_FUNC_STORE_OFFSET))))

    ;; Check for "new" meta function
    (if (call $string_equals (local.get $name_ptr) (local.get $name_len) (i32.const 584) (i32.const 3))
      (then (return (global.get $META_FUNC_NEW))))

    ;; Check for "destroy" meta function
    (if (call $string_equals (local.get $name_ptr) (local.get $name_len) (i32.const 592) (i32.const 7))
      (then (return (global.get $META_FUNC_DESTROY))))

    ;; Check for numeric type conversion functions
    (if (call $string_equals (local.get $name_ptr) (local.get $name_len) (i32.const 600) (i32.const 3))
      (then (return (global.get $META_FUNC_CONVERT))))  ;; "u32"

    (if (call $string_equals (local.get $name_ptr) (local.get $name_len) (i32.const 608) (i32.const 3))
      (then (return (global.get $META_FUNC_CONVERT))))  ;; "i32"

    (if (call $string_equals (local.get $name_ptr) (local.get $name_len) (i32.const 616) (i32.const 3))
      (then (return (global.get $META_FUNC_CONVERT))))  ;; "f32"

    ;; Not found
    (i32.const 0)
  )

  ;; Check if meta function is available for a specific type
  ;; @param meta_func_type: i32 - Meta function type constant
  ;; @param node_type: i32 - Type of the node (from type checker)
  ;; @returns i32 - 1 if available, 0 if not
  (func $is_meta_function_available (export "is_meta_function_available") (param $meta_func_type i32) (param $node_type i32) (result i32)
    (local $is_numeric i32)

    ;; Check if type is numeric
    (local.set $is_numeric (call $is_numeric_type (local.get $node_type)))

    ;; Universal meta functions (available on all types)
    (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_TYPE))
      (then (return (i32.const 1))))

    (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_STRING))
      (then (return (i32.const 1))))

    ;; Numeric-specific meta functions
    (if (local.get $is_numeric)
      (then
        (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_SIZE))
          (then (return (i32.const 1))))
        (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_CONVERT))
          (then (return (i32.const 1))))
        (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_LOAD))
          (then (return (i32.const 1))))
        (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_STORE))
          (then (return (i32.const 1))))
        (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_LOAD_OFFSET))
          (then (return (i32.const 1))))
        (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_STORE_OFFSET))
          (then (return (i32.const 1))))))

    ;; String-specific meta functions
    (if (i32.eq (local.get $node_type) (global.get $TYPE_STRING))
      (then
        (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_SIZE))
          (then (return (i32.const 1))))))

    ;; Resource-specific meta functions (placeholder - resources not fully implemented)
    ;; TODO: Implement resource type checking when resources are added

    ;; Not available
    (i32.const 0)
  )

  ;; Get the return type of a meta function
  ;; @param meta_func_type: i32 - Meta function type constant
  ;; @param node_type: i32 - Type of the target node
  ;; @returns i32 - Return type constant
  (func $get_meta_function_return_type (export "get_meta_function_return_type") (param $meta_func_type i32) (param $node_type i32) (result i32)
    ;; Universal meta functions
    (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_TYPE))
      (then (return (global.get $TYPE_STRING))))

    (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_STRING))
      (then (return (global.get $TYPE_STRING))))

    ;; Size meta function always returns u32
    (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_SIZE))
      (then (return (global.get $TYPE_U32))))

    ;; Load functions return the same type as the caller
    (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_LOAD))
      (then (return (local.get $node_type))))

    (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_LOAD_OFFSET))
      (then (return (local.get $node_type))))

    ;; Store functions return void (represented as 0)
    (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_STORE))
      (then (return (i32.const 0))))

    (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_STORE_OFFSET))
      (then (return (i32.const 0))))

    ;; Convert functions return the target type (would need parameter analysis)
    (if (i32.eq (local.get $meta_func_type) (global.get $META_FUNC_CONVERT))
      (then (return (local.get $node_type))))  ;; Simplified for now

    ;; Unknown meta function
    (i32.const 0)
  )

  ;; Helper function to check if a type is numeric
  ;; @param type_id: i32 - Type constant
  ;; @returns i32 - 1 if numeric, 0 if not
  (func $is_numeric_type (param $type_id i32) (result i32)
    (if (i32.eq (local.get $type_id) (global.get $TYPE_I32))
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_I64))
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_F32))
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_F64))
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U8))
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U16))
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U32))
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U64))
      (then (return (i32.const 1))))
    (i32.const 0)
  )

  ;; Helper function to compare strings
  ;; @param ptr1: i32 - Pointer to first string
  ;; @param len1: i32 - Length of first string
  ;; @param ptr2: i32 - Pointer to second string
  ;; @param len2: i32 - Length of second string
  ;; @returns i32 - 1 if equal, 0 if not
  (func $string_equals (param $ptr1 i32) (param $len1 i32) (param $ptr2 i32) (param $len2 i32) (result i32)
    (local $i i32)

    ;; Check length equality first
    (if (i32.ne (local.get $len1) (local.get $len2))
      (then (return (i32.const 0))))

    ;; Compare byte by byte
    (local.set $i (i32.const 0))
    (loop $compare_loop
      (if (i32.lt_u (local.get $i) (local.get $len1))
        (then
          (if (i32.ne
                (i32.load8_u (i32.add (local.get $ptr1) (local.get $i)))
                (i32.load8_u (i32.add (local.get $ptr2) (local.get $i))))
            (then (return (i32.const 0))))
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $compare_loop))))

    (i32.const 1)
  )

  ;; Initialize meta function name strings in memory
  (func $init_meta_function_names (export "init_meta_function_names")
    ;; Store meta function name strings at fixed memory locations
    ;; "type" at offset 512
    (i32.store8 (i32.const 512) (i32.const 116))  ;; 't'
    (i32.store8 (i32.const 513) (i32.const 121))  ;; 'y'
    (i32.store8 (i32.const 514) (i32.const 112))  ;; 'p'
    (i32.store8 (i32.const 515) (i32.const 101))  ;; 'e'

    ;; "string" at offset 520
    (i32.store8 (i32.const 520) (i32.const 115))  ;; 's'
    (i32.store8 (i32.const 521) (i32.const 116))  ;; 't'
    (i32.store8 (i32.const 522) (i32.const 114))  ;; 'r'
    (i32.store8 (i32.const 523) (i32.const 105))  ;; 'i'
    (i32.store8 (i32.const 524) (i32.const 110))  ;; 'n'
    (i32.store8 (i32.const 525) (i32.const 103))  ;; 'g'

    ;; "size" at offset 528
    (i32.store8 (i32.const 528) (i32.const 115))  ;; 's'
    (i32.store8 (i32.const 529) (i32.const 105))  ;; 'i'
    (i32.store8 (i32.const 530) (i32.const 122))  ;; 'z'
    (i32.store8 (i32.const 531) (i32.const 101))  ;; 'e'

    ;; Additional meta function names...
    ;; "load" at offset 536
    (i32.store8 (i32.const 536) (i32.const 108))  ;; 'l'
    (i32.store8 (i32.const 537) (i32.const 111))  ;; 'o'
    (i32.store8 (i32.const 538) (i32.const 97))   ;; 'a'
    (i32.store8 (i32.const 539) (i32.const 100))  ;; 'd'

    ;; "store" at offset 544
    (i32.store8 (i32.const 544) (i32.const 115))  ;; 's'
    (i32.store8 (i32.const 545) (i32.const 116))  ;; 't'
    (i32.store8 (i32.const 546) (i32.const 111))  ;; 'o'
    (i32.store8 (i32.const 547) (i32.const 114))  ;; 'r'
    (i32.store8 (i32.const 548) (i32.const 101))  ;; 'e'
  )
)
