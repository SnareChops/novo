;; Binary Code Generation Main Module
;; Main orchestration for binary WASM code generation (Phase 7.3 correction)

(module $codegen_binary_main
  ;; Import memory for data storage
  (import "lexer_memory" "memory" (memory 1))

  ;; Import binary encoder modules
  (import "binary_encoder" "init_binary_encoder" (func $init_binary_encoder))
  (import "binary_encoder" "generate_binary_wasm_module" (func $generate_binary_wasm_module (param i32 i32 i32) (result i32)))
  (import "binary_encoder" "generate_test_binary_module" (func $generate_test_binary_module (param i32 i32) (result i32)))
  (import "binary_encoder" "get_binary_output" (func $get_binary_output (param i32)))

  ;; Import AST for tree traversal
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "ast_node_core" "get_child_count" (func $get_child_count (param i32) (result i32)))
  (import "ast_node_core" "get_child" (func $get_child (param i32 i32) (result i32)))

  ;; Import AST node types
  (import "ast_node_types" "DECL_FUNCTION" (global $DECL_FUNCTION i32))
  (import "ast_node_types" "CTRL_MATCH" (global $CTRL_MATCH i32))
  (import "ast_node_types" "EXPR_BLOCK" (global $EXPR_BLOCK i32))

  ;; Import legacy WAT text generation (for future 'novo wat' command)
  (import "codegen_main" "generate_wasm_module" (func $generate_wat_text_module (param i32 i32 i32) (result i32)))
  (import "codegen_main" "generate_test_module" (func $generate_wat_test_module (param i32 i32) (result i32)))
  (import "codegen_core" "get_output_buffer" (func $get_wat_output_buffer (param i32)))

  ;; Code generation mode
  (global $CODEGEN_MODE_BINARY i32 (i32.const 0))
  (global $CODEGEN_MODE_WAT_TEXT i32 (i32.const 1))
  (global $current_mode (mut i32) (i32.const 0))  ;; Default to binary

  ;; Binary generation statistics
  (global $functions_generated (mut i32) (i32.const 0))
  (global $imports_generated (mut i32) (i32.const 0))
  (global $exports_generated (mut i32) (i32.const 0))

  ;; Initialize binary code generation system
  (func $init_binary_code_generation (export "init_binary_code_generation")
    (call $init_binary_encoder)
    (global.set $current_mode (global.get $CODEGEN_MODE_BINARY))
    (global.set $functions_generated (i32.const 0))
    (global.set $imports_generated (i32.const 0))
    (global.set $exports_generated (i32.const 0))
  )

  ;; Generate complete binary WASM module from AST (PRIMARY COMPILATION TARGET)
  ;; @param ast_root: i32 - Root AST node
  ;; @param module_name_ptr: i32 - Module name string
  ;; @param module_name_len: i32 - Module name length
  ;; @returns i32 - Number of bytes generated (0 if failed)
  (func $compile_to_binary_wasm (export "compile_to_binary_wasm")
        (param $ast_root i32) (param $module_name_ptr i32) (param $module_name_len i32) (result i32)
    (local $bytes_generated i32)

    ;; Initialize binary code generation
    (call $init_binary_code_generation)

    ;; Generate binary WASM module
    (local.set $bytes_generated
      (call $generate_binary_wasm_module
        (local.get $ast_root)
        (local.get $module_name_ptr)
        (local.get $module_name_len)))

    ;; Update statistics
    (if (i32.gt_u (local.get $bytes_generated) (i32.const 0))
      (then
        (global.set $functions_generated (i32.const 1))  ;; At least module generated
        (global.set $imports_generated (i32.const 1))    ;; Memory import
      )
    )

    (local.get $bytes_generated)
  )

  ;; Generate WAT text format from AST (FUTURE FEATURE: 'novo wat' command)
  ;; @param ast_root: i32 - Root AST node
  ;; @param module_name_ptr: i32 - Module name string
  ;; @param module_name_len: i32 - Module name length
  ;; @returns i32 - Success (1) or failure (0)
  (func $compile_to_wat_text (export "compile_to_wat_text")
        (param $ast_root i32) (param $module_name_ptr i32) (param $module_name_len i32) (result i32)
    (local $success i32)

    ;; Set mode to WAT text generation
    (global.set $current_mode (global.get $CODEGEN_MODE_WAT_TEXT))

    ;; Generate WAT text using legacy system
    (local.set $success
      (call $generate_wat_text_module
        (local.get $ast_root)
        (local.get $module_name_ptr)
        (local.get $module_name_len)))

    (local.get $success)
  )

  ;; Get binary output buffer for writing to file
  ;; @param result_ptr: i32 - Pointer to store result (ptr, len)
  (func $get_binary_wasm_output (export "get_binary_wasm_output") (param $result_ptr i32)
    (call $get_binary_output (local.get $result_ptr))
  )

  ;; Get WAT text output buffer (for future 'novo wat' command)
  ;; @param result_ptr: i32 - Pointer to store result (ptr, len)
  (func $get_wat_text_output (export "get_wat_text_output") (param $result_ptr i32)
    (call $get_wat_output_buffer (local.get $result_ptr))
  )

  ;; Generate minimal test binary module
  ;; @param module_name_ptr: i32 - Module name string
  ;; @param module_name_len: i32 - Module name length
  ;; @returns i32 - Number of bytes generated (0 if failed)
  (func $generate_test_binary (export "generate_test_binary")
        (param $module_name_ptr i32) (param $module_name_len i32) (result i32)
    (local $bytes_generated i32)

    ;; Initialize binary code generation
    (call $init_binary_code_generation)

    ;; Generate test binary module
    (local.set $bytes_generated
      (call $generate_test_binary_module
        (local.get $module_name_ptr)
        (local.get $module_name_len)))

    (local.get $bytes_generated)
  )

  ;; Generate minimal test WAT text module (legacy compatibility)
  ;; @param module_name_ptr: i32 - Module name string
  ;; @param module_name_len: i32 - Module name length
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_test_wat (export "generate_test_wat")
        (param $module_name_ptr i32) (param $module_name_len i32) (result i32)
    (local $success i32)

    ;; Set mode to WAT text generation
    (global.set $current_mode (global.get $CODEGEN_MODE_WAT_TEXT))

    ;; Generate test WAT text using legacy system
    (local.set $success
      (call $generate_wat_test_module
        (local.get $module_name_ptr)
        (local.get $module_name_len)))

    (local.get $success)
  )

  ;; Get current compilation mode
  ;; @returns i32 - Current mode (0=binary, 1=WAT text)
  (func $get_compilation_mode (export "get_compilation_mode") (result i32)
    (global.get $current_mode)
  )

  ;; Set compilation mode
  ;; @param mode: i32 - Mode to set (0=binary, 1=WAT text)
  (func $set_compilation_mode (export "set_compilation_mode") (param $mode i32)
    (global.set $current_mode (local.get $mode))
  )

  ;; Get compilation statistics
  ;; @param stats_ptr: i32 - Pointer to store stats (functions, imports, exports)
  (func $get_compilation_stats (export "get_compilation_stats") (param $stats_ptr i32)
    (i32.store offset=0 (local.get $stats_ptr) (global.get $functions_generated))
    (i32.store offset=4 (local.get $stats_ptr) (global.get $imports_generated))
    (i32.store offset=8 (local.get $stats_ptr) (global.get $exports_generated))
  )

  ;; Validate binary WASM output
  ;; @returns i32 - Validation result (1=valid, 0=invalid)
  (func $validate_binary_output (export "validate_binary_output") (result i32)
    (local $output_info_ptr i32)
    (local $output_ptr i32)
    (local $output_len i32)
    (local $magic_number i32)

    ;; Allocate space for output info
    (local.set $output_info_ptr (i32.const 48250))  ;; Temporary storage

    ;; Get binary output
    (call $get_binary_output (local.get $output_info_ptr))
    (local.set $output_ptr (i32.load (local.get $output_info_ptr)))
    (local.set $output_len (i32.load offset=4 (local.get $output_info_ptr)))

    ;; Check minimum size (8 bytes for header)
    (if (i32.lt_u (local.get $output_len) (i32.const 8))
      (then (return (i32.const 0))))

    ;; Check WASM magic number: 0x6d736100 ("\0asm")
    (local.set $magic_number
      (i32.or
        (i32.or
          (i32.or
            (i32.load8_u (local.get $output_ptr))
            (i32.shl (i32.load8_u (i32.add (local.get $output_ptr) (i32.const 1))) (i32.const 8)))
          (i32.shl (i32.load8_u (i32.add (local.get $output_ptr) (i32.const 2))) (i32.const 16)))
        (i32.shl (i32.load8_u (i32.add (local.get $output_ptr) (i32.const 3))) (i32.const 24))))

    ;; WASM magic: 0x6d736100
    (i32.eq (local.get $magic_number) (i32.const 0x6d736100))
  )
)
