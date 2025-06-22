;; Novo Compiler Main Integration
;; Main entry point that orchestrates the complete compilation pipeline
;; Integrates lexer, parser, typechecker, and codegen (binary or WAT)

(module $compiler_main
  ;; Import memory for data storage
  (import "lexer_memory" "memory" (memory 1))

  ;; Import the complete pipeline components
  ;; Lexer
  (import "novo_lexer" "scan_text" (func $scan_text (param i32 i32) (result i32)))
  (import "novo_lexer" "next_token" (func $next_token (param i32) (result i32 i32)))

  ;; Parser
  (import "parser_main" "parse" (func $parse (param i32) (result i32 i32)))

  ;; Type checker
  (import "typechecker_main" "get_node_type_info" (func $get_node_type_info (param i32) (result i32)))
  (import "typechecker_main" "set_node_type_info" (func $set_node_type_info (param i32 i32) (result i32)))
  (import "typechecker_main" "reset_type_checker" (func $reset_type_checker))

  ;; AST
  (import "novo_ast" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "novo_ast" "init_memory_manager" (func $init_memory_manager))

  ;; Binary code generation (PRIMARY TARGET)
  (import "codegen_binary_main" "init_binary_code_generation" (func $init_binary_code_generation))
  (import "codegen_binary_main" "compile_to_binary_wasm" (func $compile_to_binary_wasm (param i32 i32 i32) (result i32)))
  (import "codegen_binary_main" "get_binary_wasm_output" (func $get_binary_wasm_output (param i32)))
  (import "codegen_binary_main" "get_compilation_mode" (func $get_compilation_mode (result i32)))
  (import "codegen_binary_main" "get_compilation_stats" (func $get_compilation_stats (param i32)))

  ;; WAT text generation (FUTURE FEATURE)
  (import "codegen_binary_main" "compile_to_wat_text" (func $compile_to_wat_text (param i32 i32 i32) (result i32)))
  (import "codegen_binary_main" "get_wat_text_output" (func $get_wat_text_output (param i32)))

  ;; Compilation mode constants
  (global $COMPILE_MODE_BINARY i32 (i32.const 0))  ;; Primary target: .wasm binary
  (global $COMPILE_MODE_WAT_TEXT i32 (i32.const 1)) ;; Future feature: .wat text
  (global $COMPILE_MODE_WIT_INTERFACE i32 (i32.const 2)) ;; Future: .wit interface

  ;; Compilation state
  (global $current_compile_mode (mut i32) (i32.const 0))  ;; Default to binary
  (global $compilation_successful (mut i32) (i32.const 0))
  (global $ast_root (mut i32) (i32.const 0))

  ;; Error handling
  (global $last_error_code (mut i32) (i32.const 0))
  (global $ERROR_NONE i32 (i32.const 0))
  (global $ERROR_LEXER_FAILED i32 (i32.const 1))
  (global $ERROR_PARSER_FAILED i32 (i32.const 2))
  (global $ERROR_TYPECHECKER_FAILED i32 (i32.const 3))
  (global $ERROR_CODEGEN_FAILED i32 (i32.const 4))
  (global $ERROR_INVALID_MODE i32 (i32.const 5))

  ;; Initialize the complete compiler system
  (func $init_compiler (export "init_compiler")
    ;; Initialize all subsystems
    (call $init_memory_manager)
    (call $init_binary_code_generation)

    ;; Reset state
    (global.set $current_compile_mode (global.get $COMPILE_MODE_BINARY))
    (global.set $compilation_successful (i32.const 0))
    (global.set $ast_root (i32.const 0))
    (global.set $last_error_code (global.get $ERROR_NONE))
  )

  ;; Main compilation entry point: novo compile
  ;; Compiles Novo source to binary WASM (.wasm files)
  ;; @param source_ptr: i32 - Source code string
  ;; @param source_len: i32 - Source code length
  ;; @param module_name_ptr: i32 - Module name string
  ;; @param module_name_len: i32 - Module name length
  ;; @returns i32 - Success (1) or failure (0)
  (func $novo_compile (export "novo_compile")
        (param $source_ptr i32) (param $source_len i32)
        (param $module_name_ptr i32) (param $module_name_len i32) (result i32)
    (local $success i32)

    ;; Set compilation mode to binary
    (global.set $current_compile_mode (global.get $COMPILE_MODE_BINARY))

    ;; Run complete compilation pipeline
    (local.set $success
      (call $compile_with_mode
        (local.get $source_ptr) (local.get $source_len)
        (local.get $module_name_ptr) (local.get $module_name_len)
        (global.get $COMPILE_MODE_BINARY)))

    (local.get $success)
  )

  ;; Future feature: novo wat
  ;; Compiles Novo source to WAT text format (.wat files) for debugging
  ;; @param source_ptr: i32 - Source code string
  ;; @param source_len: i32 - Source code length
  ;; @param module_name_ptr: i32 - Module name string
  ;; @param module_name_len: i32 - Module name length
  ;; @returns i32 - Success (1) or failure (0)
  (func $novo_wat (export "novo_wat")
        (param $source_ptr i32) (param $source_len i32)
        (param $module_name_ptr i32) (param $module_name_len i32) (result i32)
    (local $success i32)

    ;; Set compilation mode to WAT text
    (global.set $current_compile_mode (global.get $COMPILE_MODE_WAT_TEXT))

    ;; Run complete compilation pipeline
    (local.set $success
      (call $compile_with_mode
        (local.get $source_ptr) (local.get $source_len)
        (local.get $module_name_ptr) (local.get $module_name_len)
        (global.get $COMPILE_MODE_WAT_TEXT)))

    (local.get $success)
  )

  ;; Core compilation pipeline with mode selection
  ;; @param source_ptr: i32 - Source code string
  ;; @param source_len: i32 - Source code length
  ;; @param module_name_ptr: i32 - Module name string
  ;; @param module_name_len: i32 - Module name length
  ;; @param mode: i32 - Compilation mode (0=binary, 1=WAT)
  ;; @returns i32 - Success (1) or failure (0)
  (func $compile_with_mode
        (param $source_ptr i32) (param $source_len i32)
        (param $module_name_ptr i32) (param $module_name_len i32)
        (param $mode i32) (result i32)
    (local $lexer_success i32)
    (local $parser_result i32)
    (local $parser_pos i32)
    (local $typecheck_success i32)
    (local $codegen_success i32)

    ;; Initialize compiler
    (call $init_compiler)

    ;; Phase 1: Lexical Analysis
    (local.set $lexer_success
      (call $scan_text (local.get $source_ptr) (local.get $source_len)))

    (if (i32.eqz (local.get $lexer_success))
      (then
        (global.set $last_error_code (global.get $ERROR_LEXER_FAILED))
        (return (i32.const 0))))

    ;; Phase 2: Parsing
    (call $parse (i32.const 0))  ;; Start parsing from position 0
    (local.set $parser_pos)      ;; Second return value (final position)
    (local.set $parser_result)   ;; First return value (AST root)

    (if (i32.eqz (local.get $parser_result))
      (then
        (global.set $last_error_code (global.get $ERROR_PARSER_FAILED))
        (return (i32.const 0))))

    ;; Store AST root for later use
    (global.set $ast_root (local.get $parser_result))

    ;; Phase 3: Type Checking (simplified for now)
    (call $reset_type_checker)
    (local.set $typecheck_success
      (call $simplified_typecheck_program (local.get $parser_result)))

    (if (i32.eqz (local.get $typecheck_success))
      (then
        (global.set $last_error_code (global.get $ERROR_TYPECHECKER_FAILED))
        (return (i32.const 0))))

    ;; Phase 4: Code Generation (mode-dependent)
    (if (i32.eq (local.get $mode) (global.get $COMPILE_MODE_BINARY))
      (then
        ;; Binary WASM generation (primary target)
        (local.set $codegen_success
          (call $compile_to_binary_wasm
            (local.get $parser_result)
            (local.get $module_name_ptr)
            (local.get $module_name_len))))
      (else (if (i32.eq (local.get $mode) (global.get $COMPILE_MODE_WAT_TEXT))
        (then
          ;; WAT text generation (future feature)
          (local.set $codegen_success
            (call $compile_to_wat_text
              (local.get $parser_result)
              (local.get $module_name_ptr)
              (local.get $module_name_len))))
        (else
          ;; Invalid mode
          (global.set $last_error_code (global.get $ERROR_INVALID_MODE))
          (return (i32.const 0))))))

    (if (i32.eqz (local.get $codegen_success))
      (then
        (global.set $last_error_code (global.get $ERROR_CODEGEN_FAILED))
        (return (i32.const 0))))

    ;; Success
    (global.set $compilation_successful (i32.const 1))
    (i32.const 1)
  )

  ;; Get binary WASM output buffer (for novo compile)
  ;; @param result_ptr: i32 - Pointer to store result (ptr, len)
  (func $get_binary_output (export "get_binary_output") (param $result_ptr i32)
    (call $get_binary_wasm_output (local.get $result_ptr))
  )

  ;; Get WAT text output buffer (for novo wat - future feature)
  ;; @param result_ptr: i32 - Pointer to store result (ptr, len)
  (func $get_wat_output (export "get_wat_output") (param $result_ptr i32)
    (call $get_wat_text_output (local.get $result_ptr))
  )

  ;; Get compilation status and error information
  ;; @returns i32 - Last error code (0=success)
  (func $get_last_error (export "get_last_error") (result i32)
    (global.get $last_error_code)
  )

  ;; Get compilation success status
  ;; @returns i32 - Success (1) or failure (0)
  (func $is_compilation_successful (export "is_compilation_successful") (result i32)
    (global.get $compilation_successful)
  )

  ;; Get current compilation mode
  ;; @returns i32 - Current mode (0=binary, 1=WAT, 2=WIT)
  (func $get_current_mode (export "get_current_mode") (result i32)
    (global.get $current_compile_mode)
  )

  ;; Get AST root node (for inspection/debugging)
  ;; @returns i32 - AST root node pointer
  (func $get_ast_root (export "get_ast_root") (result i32)
    (global.get $ast_root)
  )

  ;; Get detailed compilation statistics
  ;; @param stats_ptr: i32 - Pointer to store stats (functions, imports, exports)
  (func $get_compiler_stats (export "get_compiler_stats") (param $stats_ptr i32)
    (call $get_compilation_stats (local.get $stats_ptr))
  )

  ;; Validate that binary output mode is active
  ;; @returns i32 - 1 if binary mode, 0 otherwise
  (func $is_binary_mode_active (export "is_binary_mode_active") (result i32)
    (i32.eq (global.get $current_compile_mode) (global.get $COMPILE_MODE_BINARY))
  )

  ;; Get error message for last error (simplified for now)
  ;; @param error_code: i32 - Error code
  ;; @returns i32 - Simplified error message code
  (func $get_error_message_code (export "get_error_message_code") (param $error_code i32) (result i32)
    ;; For now, just return the error code
    ;; Future enhancement: return pointer to error message strings
    (local.get $error_code)
  )

  ;; Reset compiler state for new compilation
  (func $reset_compiler_state (export "reset_compiler_state")
    (global.set $compilation_successful (i32.const 0))
    (global.set $ast_root (i32.const 0))
    (global.set $last_error_code (global.get $ERROR_NONE))
    (global.set $current_compile_mode (global.get $COMPILE_MODE_BINARY))
  )

  ;; Simplified type checking program (placeholder until full implementation)
  ;; @param ast_root: i32 - AST root node
  ;; @returns i32 - Success (1) or failure (0)
  (func $simplified_typecheck_program (param $ast_root i32) (result i32)
    ;; For now, just return success if we have a valid AST node
    ;; Future enhancement: implement proper type checking traversal
    (if (result i32) (local.get $ast_root)
      (then (i32.const 1))
      (else (i32.const 0)))
  )
)
