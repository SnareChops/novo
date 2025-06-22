;; WebAssembly Binary Format Encoder
;; Main coordination module for binary WASM generation

(module $binary_encoder
  ;; Import memory for binary data storage
  (import "lexer_memory" "memory" (memory 1))

  ;; Import binary generation modules
  (import "leb128_encoder" "encode_uleb128_u32" (func $encode_uleb128_u32 (param i32 i32) (result i32)))
  (import "leb128_encoder" "write_string_with_length" (func $write_string_with_length (param i32 i32 i32) (result i32)))

  (import "section_generator" "init_section_generator" (func $init_section_generator))
  (import "section_generator" "write_wasm_header" (func $write_wasm_header (param i32) (result i32)))
  (import "section_generator" "generate_type_section" (func $generate_type_section (param i32 i32 i32) (result i32)))
  (import "section_generator" "generate_import_section" (func $generate_import_section (param i32 i32 i32 i32 i32 i32 i32) (result i32)))
  (import "section_generator" "generate_function_section" (func $generate_function_section (param i32 i32 i32) (result i32)))
  (import "section_generator" "generate_export_section" (func $generate_export_section (param i32 i32 i32 i32 i32) (result i32)))
  (import "section_generator" "generate_code_section" (func $generate_code_section (param i32 i32 i32) (result i32)))

  (import "instruction_encoder" "init_instruction_encoder" (func $init_instruction_encoder))
  (import "instruction_encoder" "encode_i32_const" (func $encode_i32_const (param i32 i32) (result i32)))
  (import "instruction_encoder" "encode_local_get" (func $encode_local_get (param i32 i32) (result i32)))
  (import "instruction_encoder" "encode_binary_op" (func $encode_binary_op (param i32 i32 i32) (result i32)))
  (import "instruction_encoder" "encode_call" (func $encode_call (param i32 i32) (result i32)))
  (import "instruction_encoder" "encode_control_flow" (func $encode_control_flow (param i32 i32 i32) (result i32)))

  ;; Import AST for tree traversal
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "ast_node_core" "get_child_count" (func $get_child_count (param i32) (result i32)))
  (import "ast_node_core" "get_child" (func $get_child (param i32 i32) (result i32)))
  (import "ast_node_core" "get_node_value" (func $get_node_value (param i32) (result i32)))

  ;; Import AST node types
  (import "ast_node_types" "EXPR_INTEGER_LITERAL" (global $EXPR_INTEGER_LITERAL i32))
  (import "ast_node_types" "EXPR_ADD" (global $EXPR_ADD i32))
  (import "ast_node_types" "EXPR_SUB" (global $EXPR_SUB i32))
  (import "ast_node_types" "EXPR_MUL" (global $EXPR_MUL i32))
  (import "ast_node_types" "EXPR_DIV" (global $EXPR_DIV i32))
  (import "ast_node_types" "DECL_FUNCTION" (global $DECL_FUNCTION i32))
  (import "ast_node_types" "CTRL_RETURN" (global $CTRL_RETURN i32))

  ;; Binary output workspace
  (global $BINARY_OUTPUT_START i32 (i32.const 25600))  ;; 25KB offset
  (global $BINARY_OUTPUT_SIZE i32 (i32.const 16384))   ;; 16KB for binary output
  (global $binary_output_pos (mut i32) (i32.const 0))

  ;; Function metadata workspace
  (global $FUNCTION_METADATA_START i32 (i32.const 41984))  ;; 41KB offset
  (global $FUNCTION_METADATA_SIZE i32 (i32.const 4096))
  (global $function_count (mut i32) (i32.const 0))

  ;; String storage workspace
  (global $STRING_STORAGE_START i32 (i32.const 46080))  ;; 45KB offset
  (global $STRING_STORAGE_SIZE i32 (i32.const 1024))

  ;; Initialize binary encoder
  (func $init_binary_encoder (export "init_binary_encoder")
    (call $init_section_generator)
    (call $init_instruction_encoder)
    (global.set $binary_output_pos (i32.const 0))
    (global.set $function_count (i32.const 0))
  )

  ;; Generate complete binary WASM module from AST
  ;; @param ast_root: i32 - Root AST node
  ;; @param module_name_ptr: i32 - Module name string
  ;; @param module_name_len: i32 - Module name length
  ;; @returns i32 - Number of bytes generated (0 if failed)
  (func $generate_binary_wasm_module (export "generate_binary_wasm_module")
        (param $ast_root i32) (param $module_name_ptr i32) (param $module_name_len i32) (result i32)
    (local $output_ptr i32)
    (local $bytes_written i32)
    (local $total_bytes i32)
    (local $success i32)

    ;; Initialize
    (call $init_binary_encoder)
    (local.set $output_ptr (global.get $BINARY_OUTPUT_START))
    (local.set $total_bytes (i32.const 0))

    ;; Step 1: Write WASM header
    (local.set $bytes_written (call $write_wasm_header (local.get $output_ptr)))
    (local.set $total_bytes (i32.add (local.get $total_bytes) (local.get $bytes_written)))
    (local.set $output_ptr (i32.add (local.get $output_ptr) (local.get $bytes_written)))

    ;; Step 2: Generate type section (simple: one function type () -> ())
    (local.set $bytes_written
      (call $generate_type_section
        (i32.const 0)  ;; No function types for now
        (i32.const 1)  ;; One type
        (local.get $output_ptr)))
    (local.set $total_bytes (i32.add (local.get $total_bytes) (local.get $bytes_written)))
    (local.set $output_ptr (i32.add (local.get $output_ptr) (local.get $bytes_written)))

    ;; Step 3: Generate import section (import memory)
    ;; Store "lexer_memory" and "memory" strings
    (call $store_string (global.get $STRING_STORAGE_START) (local.get $module_name_ptr) (local.get $module_name_len))
    (call $store_string (i32.add (global.get $STRING_STORAGE_START) (i32.const 32)) (i32.const 48128) (i32.const 6)) ;; "memory"

    (local.set $bytes_written
      (call $generate_import_section
        (global.get $STRING_STORAGE_START) (local.get $module_name_len)  ;; Module name
        (i32.add (global.get $STRING_STORAGE_START) (i32.const 32)) (i32.const 6)  ;; "memory"
        (i32.const 2)  ;; Memory import
        (i32.const 1)  ;; 1 page
        (local.get $output_ptr)))
    (local.set $total_bytes (i32.add (local.get $total_bytes) (local.get $bytes_written)))
    (local.set $output_ptr (i32.add (local.get $output_ptr) (local.get $bytes_written)))

    ;; Step 4: Analyze AST and count functions
    (local.set $success (call $analyze_ast_functions (local.get $ast_root)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Step 5: Generate function section (if we have functions)
    (if (i32.gt_u (global.get $function_count) (i32.const 0))
      (then
        (local.set $bytes_written
          (call $generate_function_section
            (global.get $function_count)
            (global.get $FUNCTION_METADATA_START)  ;; Type indices
            (local.get $output_ptr)))
        (local.set $total_bytes (i32.add (local.get $total_bytes) (local.get $bytes_written)))
        (local.set $output_ptr (i32.add (local.get $output_ptr) (local.get $bytes_written)))
      )
    )

    ;; Step 6: Generate export section (export first function as "main" if exists)
    (if (i32.gt_u (global.get $function_count) (i32.const 0))
      (then
        ;; Store "main" string
        (call $store_string (i32.add (global.get $STRING_STORAGE_START) (i32.const 64)) (i32.const 48135) (i32.const 4)) ;; "main"

        (local.set $bytes_written
          (call $generate_export_section
            (i32.add (global.get $STRING_STORAGE_START) (i32.const 64)) (i32.const 4)  ;; "main"
            (i32.const 0)  ;; Function export
            (i32.const 0)  ;; Function index 0
            (local.get $output_ptr)))
        (local.set $total_bytes (i32.add (local.get $total_bytes) (local.get $bytes_written)))
        (local.set $output_ptr (i32.add (local.get $output_ptr) (local.get $bytes_written)))
      )
    )

    ;; Step 7: Generate code section with actual function bodies
    (if (i32.gt_u (global.get $function_count) (i32.const 0))
      (then
        (local.set $bytes_written
          (call $generate_code_section_with_bodies
            (local.get $ast_root)
            (global.get $function_count)
            (local.get $output_ptr)))
        (local.set $total_bytes (i32.add (local.get $total_bytes) (local.get $bytes_written)))
        (local.set $output_ptr (i32.add (local.get $output_ptr) (local.get $bytes_written)))
      )
    )

    ;; Update global position
    (global.set $binary_output_pos (local.get $total_bytes))
    (local.get $total_bytes)
  )

  ;; Analyze AST to count and catalog functions
  ;; @param ast_root: i32 - Root AST node
  ;; @returns i32 - Success (1) or failure (0)
  (func $analyze_ast_functions (param $ast_root i32) (result i32)
    (local $child_count i32)
    (local $i i32)
    (local $child_node i32)
    (local $node_type i32)

    (global.set $function_count (i32.const 0))
    (local.set $child_count (call $get_child_count (local.get $ast_root)))
    (local.set $i (i32.const 0))

    (loop $analyze_loop
      (if (i32.lt_u (local.get $i) (local.get $child_count))
        (then
          (local.set $child_node (call $get_child (local.get $ast_root) (local.get $i)))
          (local.set $node_type (call $get_node_type (local.get $child_node)))

          ;; Check if this is a function declaration
          (if (i32.eq (local.get $node_type) (global.get $DECL_FUNCTION))
            (then
              ;; Store function metadata (type index = 0 for now)
              (i32.store
                (i32.add (global.get $FUNCTION_METADATA_START)
                  (i32.mul (global.get $function_count) (i32.const 4)))
                (i32.const 0))  ;; Type index 0
              (global.set $function_count (i32.add (global.get $function_count) (i32.const 1)))
            )
          )

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $analyze_loop)
        )
      )
    )

    (i32.const 1)  ;; Success
  )

  ;; Store string in storage area
  ;; @param dest_ptr: i32 - Destination pointer
  ;; @param src_ptr: i32 - Source string pointer
  ;; @param len: i32 - String length
  (func $store_string (param $dest_ptr i32) (param $src_ptr i32) (param $len i32)
    (local $i i32)
    (local.set $i (i32.const 0))
    (loop $copy_loop
      (if (i32.lt_u (local.get $i) (local.get $len))
        (then
          (i32.store8
            (i32.add (local.get $dest_ptr) (local.get $i))
            (i32.load8_u (i32.add (local.get $src_ptr) (local.get $i))))
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $copy_loop)
        )
      )
    )
  )

  ;; Get binary output buffer
  ;; @param result_ptr: i32 - Pointer to store result (ptr, len)
  (func $get_binary_output (export "get_binary_output") (param $result_ptr i32)
    (i32.store (local.get $result_ptr) (global.get $BINARY_OUTPUT_START))
    (i32.store offset=4 (local.get $result_ptr) (global.get $binary_output_pos))
  )

  ;; Generate minimal test binary module
  ;; @param module_name_ptr: i32 - Module name string
  ;; @param module_name_len: i32 - Module name length
  ;; @returns i32 - Total bytes written (0 if failed)
  (func $generate_test_binary_module (export "generate_test_binary_module")
        (param $module_name_ptr i32) (param $module_name_len i32) (result i32)
    (local $output_ptr i32)
    (local $bytes_written i32)
    (local $total_bytes i32)

    ;; Initialize
    (call $init_binary_encoder)
    (local.set $output_ptr (global.get $BINARY_OUTPUT_START))
    (local.set $total_bytes (i32.const 0))

    ;; Write WASM header
    (local.set $bytes_written (call $write_wasm_header (local.get $output_ptr)))
    (local.set $total_bytes (i32.add (local.get $total_bytes) (local.get $bytes_written)))
    (local.set $output_ptr (i32.add (local.get $output_ptr) (local.get $bytes_written)))

    ;; Generate minimal type section
    (local.set $bytes_written
      (call $generate_type_section
        (i32.const 0)  ;; No function types
        (i32.const 1)  ;; One type
        (local.get $output_ptr)))
    (local.set $total_bytes (i32.add (local.get $total_bytes) (local.get $bytes_written)))

    ;; Update global position
    (global.set $binary_output_pos (local.get $total_bytes))
    (local.get $total_bytes)
  )

  ;; Generate code section with actual function bodies from AST (simplified version for now)
  ;; @param ast_root: i32 - Root AST node
  ;; @param function_count: i32 - Number of functions to generate
  ;; @param output_ptr: i32 - Output buffer pointer
  ;; @returns i32 - Number of bytes written
  (func $generate_code_section_with_bodies
        (param $ast_root i32) (param $function_count i32) (param $output_ptr i32) (result i32)
    (local $bytes_written i32)

    ;; For now, generate a basic code section using the existing code section generator
    ;; TODO: Expand this to parse AST and generate actual instruction sequences
    (local.set $bytes_written
      (call $generate_code_section
        (local.get $function_count)
        (i32.const 0)  ;; Function bodies (simplified for now)
        (local.get $output_ptr)))

    (local.get $bytes_written)
  )

  ;; Initialize string constants
  (func $init_string_constants
    ;; Store "memory" at offset 48128
    (i32.store8 offset=48128 (i32.const 0) (i32.const 109))  ;; 'm'
    (i32.store8 offset=48129 (i32.const 0) (i32.const 101))  ;; 'e'
    (i32.store8 offset=48130 (i32.const 0) (i32.const 109))  ;; 'm'
    (i32.store8 offset=48131 (i32.const 0) (i32.const 111))  ;; 'o'
    (i32.store8 offset=48132 (i32.const 0) (i32.const 114))  ;; 'r'
    (i32.store8 offset=48133 (i32.const 0) (i32.const 121))  ;; 'y'

    ;; Store "main" at offset 48135
    (i32.store8 offset=48135 (i32.const 0) (i32.const 109))  ;; 'm'
    (i32.store8 offset=48136 (i32.const 0) (i32.const 97))   ;; 'a'
    (i32.store8 offset=48137 (i32.const 0) (i32.const 105))  ;; 'i'
    (i32.store8 offset=48138 (i32.const 0) (i32.const 110))  ;; 'n'
  )

  ;; Initialize data (called at module instantiation)
  (start $init_string_constants)
)
