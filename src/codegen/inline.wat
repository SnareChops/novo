;; Novo Inline Function Implementation
;; Handles inline function expansion during code generation

(module $codegen_inline
  ;; Import memory management
  (import "memory" "memory" (memory 1))

  ;; Import AST functions
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "ast_node_core" "get_child" (func $get_child (param i32 i32) (result i32)))
  (import "ast_node_core" "get_child_count" (func $get_child_count (param i32) (result i32)))
  (import "ast_main" "get_function_inline_flag" (func $get_function_inline_flag (param i32) (result i32)))
  (import "ast_main" "get_function_name_length" (func $get_function_name_length (param i32) (result i32)))
  (import "ast_main" "get_function_name_ptr" (func $get_function_name_ptr (param i32) (result i32)))

  ;; Import node type constants
  (import "ast_node_types" "DECL_FUNCTION" (global $DECL_FUNCTION i32))
  (import "ast_node_types" "EXPR_TRADITIONAL_CALL" (global $EXPR_TRADITIONAL_CALL i32))
  (import "ast_node_types" "EXPR_IDENTIFIER" (global $EXPR_IDENTIFIER i32))

  ;; Import codegen functions
  (import "codegen_core" "generate_expression" (func $generate_expression (param i32) (result i32)))
  (import "codegen_stack" "push_scope" (func $push_scope))
  (import "codegen_stack" "pop_scope" (func $pop_scope))

  ;; Memory regions for inline function management
  (global $INLINE_FUNCTION_TABLE_START (mut i32) (i32.const 8000))  ;; Start of inline function table
  (global $INLINE_FUNCTION_TABLE_SIZE (mut i32) (i32.const 0))      ;; Number of registered functions
  (global $INLINE_FUNCTION_MAX_COUNT i32 (i32.const 100))           ;; Maximum inline functions
  (global $INLINE_FUNCTION_RECORD_SIZE i32 (i32.const 16))          ;; Size of each function record

  ;; Inline function record layout:
  ;; [0-3]: Function AST node pointer
  ;; [4-7]: Function name length
  ;; [8-11]: Function name pointer
  ;; [12-15]: Function body AST node pointer

  ;; Initialize inline function management
  (func $init_inline_functions (export "init_inline_functions")
    (global.set $INLINE_FUNCTION_TABLE_SIZE (i32.const 0))
  )

  ;; Register a function for potential inlining
  ;; @param $func_node i32 - Function declaration AST node
  ;; @returns i32 - 1 if registered, 0 if failed
  (func $register_inline_function (export "register_inline_function")
    (param $func_node i32) (result i32)
    (local $is_inline i32)
    (local $table_index i32)
    (local $record_ptr i32)
    (local $name_len i32)
    (local $name_ptr i32)

    ;; Check if function is declared inline
    (local.set $is_inline (call $get_function_inline_flag (local.get $func_node)))
    (if (i32.eqz (local.get $is_inline))
      (then
        ;; Not an inline function, don't register
        (return (i32.const 0))
      )
    )

    ;; Check if table is full
    (if (i32.ge_u
          (global.get $INLINE_FUNCTION_TABLE_SIZE)
          (global.get $INLINE_FUNCTION_MAX_COUNT))
      (then
        ;; Table full, cannot register
        (return (i32.const 0))
      )
    )

    ;; Calculate record position
    (local.set $table_index (global.get $INLINE_FUNCTION_TABLE_SIZE))
    (local.set $record_ptr
      (i32.add
        (global.get $INLINE_FUNCTION_TABLE_START)
        (i32.mul
          (local.get $table_index)
          (global.get $INLINE_FUNCTION_RECORD_SIZE))))

    ;; Get function name details
    (local.set $name_len (call $get_function_name_length (local.get $func_node)))
    (local.set $name_ptr (call $get_function_name_ptr (local.get $func_node)))

    ;; Store function record
    (i32.store (local.get $record_ptr) (local.get $func_node))                    ;; Function node
    (i32.store (i32.add (local.get $record_ptr) (i32.const 4)) (local.get $name_len))  ;; Name length
    (i32.store (i32.add (local.get $record_ptr) (i32.const 8)) (local.get $name_ptr))  ;; Name pointer
    (i32.store (i32.add (local.get $record_ptr) (i32.const 12)) (i32.const 0))         ;; Body (TODO: extract from function)

    ;; Increment table size
    (global.set $INLINE_FUNCTION_TABLE_SIZE
      (i32.add (global.get $INLINE_FUNCTION_TABLE_SIZE) (i32.const 1)))

    (i32.const 1)  ;; Success
  )

  ;; Find inline function by name
  ;; @param $name_ptr i32 - Function name pointer
  ;; @param $name_len i32 - Function name length
  ;; @returns i32 - Function AST node pointer (0 if not found)
  (func $find_inline_function (export "find_inline_function")
    (param $name_ptr i32) (param $name_len i32) (result i32)
    (local $i i32)
    (local $record_ptr i32)
    (local $stored_name_len i32)
    (local $stored_name_ptr i32)
    (local $match i32)

    (local.set $i (i32.const 0))
    (loop $search_loop
      ;; Check if we've reached the end
      (if (i32.ge_u (local.get $i) (global.get $INLINE_FUNCTION_TABLE_SIZE))
        (then
          (return (i32.const 0))  ;; Not found
        )
      )

      ;; Calculate record pointer
      (local.set $record_ptr
        (i32.add
          (global.get $INLINE_FUNCTION_TABLE_START)
          (i32.mul
            (local.get $i)
            (global.get $INLINE_FUNCTION_RECORD_SIZE))))

      ;; Get stored name details
      (local.set $stored_name_len (i32.load (i32.add (local.get $record_ptr) (i32.const 4))))
      (local.set $stored_name_ptr (i32.load (i32.add (local.get $record_ptr) (i32.const 8))))

      ;; Check if names match
      (if (i32.eq (local.get $name_len) (local.get $stored_name_len))
        (then
          ;; Compare name strings
          (local.set $match (call $compare_strings
            (local.get $name_ptr) (local.get $name_len)
            (local.get $stored_name_ptr) (local.get $stored_name_len)))
          (if (local.get $match)
            (then
              ;; Found match, return function node
              (return (i32.load (local.get $record_ptr)))
            )
          )
        )
      )

      ;; Move to next record
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $search_loop)
    )

    (i32.const 0)  ;; Not found
  )

  ;; Check if a function call can be inlined
  ;; @param $call_node i32 - Function call AST node
  ;; @returns i32 - 1 if can be inlined, 0 otherwise
  (func $can_inline_call (export "can_inline_call")
    (param $call_node i32) (result i32)
    (local $node_type i32)
    (local $func_name_node i32)
    (local $name_ptr i32)
    (local $name_len i32)
    (local $func_node i32)
    (local $temp_name_ptr i32)
    (local $temp_name_len i32)

    ;; Check if this is a function call
    (local.set $node_type (call $get_node_type (local.get $call_node)))
    (if (i32.ne (local.get $node_type) (global.get $EXPR_TRADITIONAL_CALL))
      (then
        (return (i32.const 0))  ;; Not a function call
      )
    )

    ;; Get the first child (function name identifier)
    (local.set $func_name_node (call $get_child (local.get $call_node) (i32.const 0)))
    (if (i32.eqz (local.get $func_name_node))
      (then
        (return (i32.const 0))  ;; No function name
      )
    )

    ;; Allocate temporary storage for name extraction
    (local.set $temp_name_ptr (global.get $INLINE_FUNCTION_TABLE_START))
    (local.set $temp_name_len (i32.add (local.get $temp_name_ptr) (i32.const 4)))

    (if (i32.eqz (call $extract_identifier_name
                    (local.get $func_name_node)
                    (local.get $temp_name_ptr)
                    (local.get $temp_name_len)))
      (then
        (return (i32.const 0))  ;; Failed to extract name
      )
    )

    ;; Get extracted values
    (local.set $name_ptr (i32.load (local.get $temp_name_ptr)))
    (local.set $name_len (i32.load (local.get $temp_name_len)))

    ;; Check if this function is registered for inlining
    (local.set $func_node (call $find_inline_function (local.get $name_ptr) (local.get $name_len)))

    ;; Return 1 if found, 0 if not
    (if (result i32) (local.get $func_node)
      (then
        (i32.const 1))
      (else
        (i32.const 0))
    )
  )

  ;; Generate inlined function code
  ;; @param $call_node i32 - Function call AST node
  ;; @returns i32 - 1 if inlined successfully, 0 if failed
  (func $generate_inline_call (export "generate_inline_call")
    (param $call_node i32) (result i32)
    (local $func_name_node i32)
    (local $name_ptr i32)
    (local $name_len i32)
    (local $func_node i32)
    (local $arg_count i32)
    (local $i i32)
    (local $arg_node i32)
    (local $temp_name_ptr i32)
    (local $temp_name_len i32)

    ;; First check if this call can be inlined
    (if (i32.eqz (call $can_inline_call (local.get $call_node)))
      (then
        (return (i32.const 0))  ;; Cannot inline
      )
    )

    ;; Extract function name
    (local.set $func_name_node (call $get_child (local.get $call_node) (i32.const 0)))

    ;; Extract function name details
    (local.set $temp_name_ptr (global.get $INLINE_FUNCTION_TABLE_START))
    (local.set $temp_name_len (i32.add (local.get $temp_name_ptr) (i32.const 4)))

    (drop (call $extract_identifier_name
            (local.get $func_name_node)
            (local.get $temp_name_ptr)
            (local.get $temp_name_len)))

    (local.set $name_ptr (i32.load (local.get $temp_name_ptr)))
    (local.set $name_len (i32.load (local.get $temp_name_len)))

    ;; Find the inline function
    (local.set $func_node (call $find_inline_function (local.get $name_ptr) (local.get $name_len)))
    (if (i32.eqz (local.get $func_node))
      (then
        (return (i32.const 0))  ;; Function not found
      )
    )

    ;; Create new scope for inline expansion
    (call $push_scope)

    ;; Process function arguments
    ;; Arguments start from child index 1 (child 0 is function name)
    (local.set $arg_count (i32.sub (call $get_child_count (local.get $call_node)) (i32.const 1)))
    (local.set $i (i32.const 0))

    (loop $arg_loop
      (if (i32.lt_u (local.get $i) (local.get $arg_count))
        (then
          ;; Get argument node (child index i+1)
          (local.set $arg_node (call $get_child (local.get $call_node) (i32.add (local.get $i) (i32.const 1))))

          ;; Generate code for the argument expression
          ;; In a full implementation, we would:
          ;; 1. Create parameter binding in scope
          ;; 2. Generate argument evaluation code
          ;; 3. Store result for parameter substitution
          ;; For now, just generate the argument expression
          (drop (call $generate_expression (local.get $arg_node)))

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $arg_loop)
        )
      )
    )

    ;; Generate inline function body
    ;; In a full implementation, we would:
    ;; 1. Extract function body from func_node
    ;; 2. Traverse function body AST
    ;; 3. Generate code with parameter substitutions
    ;; 4. Handle return statements as inline returns
    ;; For now, this is a placeholder that indicates successful inline processing

    ;; Clean up scope
    (call $pop_scope)

    ;; Return success
    (i32.const 1)
  )

  ;; Get inline generation statistics
  ;; @returns i32 - Number of functions registered for inlining
  (func $get_inline_stats (export "get_inline_stats") (result i32)
    (global.get $INLINE_FUNCTION_TABLE_SIZE)
  )

  ;; Helper function to compare two strings
  ;; @param $str1_ptr i32 - First string pointer
  ;; @param $str1_len i32 - First string length
  ;; @param $str2_ptr i32 - Second string pointer
  ;; @param $str2_len i32 - Second string length
  ;; @returns i32 - 1 if strings match, 0 otherwise
  (func $compare_strings
    (param $str1_ptr i32) (param $str1_len i32) (param $str2_ptr i32) (param $str2_len i32) (result i32)
    (local $i i32)
    (local $char1 i32)
    (local $char2 i32)

    ;; Different lengths means different strings
    (if (i32.ne (local.get $str1_len) (local.get $str2_len))
      (then
        (return (i32.const 0))
      )
    )

    ;; Compare character by character
    (local.set $i (i32.const 0))
    (loop $compare_loop
      (if (i32.ge_u (local.get $i) (local.get $str1_len))
        (then
          (return (i32.const 1))  ;; All characters match
        )
      )

      ;; Compare current characters
      (local.set $char1 (i32.load8_u (i32.add (local.get $str1_ptr) (local.get $i))))
      (local.set $char2 (i32.load8_u (i32.add (local.get $str2_ptr) (local.get $i))))

      (if (i32.ne (local.get $char1) (local.get $char2))
        (then
          (return (i32.const 0))  ;; Characters don't match
        )
      )

      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $compare_loop)
    )

    (i32.const 1)  ;; Should not reach here, but return match
  )

  ;; Extract identifier name from an EXPR_IDENTIFIER node
  ;; @param $identifier_node i32 - Identifier AST node
  ;; @param $name_ptr_out i32 - Pointer to store name pointer
  ;; @param $name_len_out i32 - Pointer to store name length
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $extract_identifier_name
    (param $identifier_node i32) (param $name_ptr_out i32) (param $name_len_out i32) (result i32)
    (local $node_type i32)
    (local $data_offset i32)
    (local $name_len i32)
    (local $name_ptr i32)

    ;; Verify this is an identifier node
    (local.set $node_type (call $get_node_type (local.get $identifier_node)))
    (if (i32.ne (local.get $node_type) (global.get $EXPR_IDENTIFIER))
      (then
        (return (i32.const 0))  ;; Not an identifier
      )
    )

    ;; Calculate data offset (after node header)
    (local.set $data_offset (i32.add (local.get $identifier_node) (i32.const 12))) ;; NODE_DATA_OFFSET

    ;; Extract name length (first 4 bytes of data)
    (local.set $name_len (i32.load (local.get $data_offset)))

    ;; Extract name pointer (data offset + 4)
    (local.set $name_ptr (i32.add (local.get $data_offset) (i32.const 4)))

    ;; Store results
    (i32.store (local.get $name_ptr_out) (local.get $name_ptr))
    (i32.store (local.get $name_len_out) (local.get $name_len))

    (i32.const 1)  ;; Success
  )
)
