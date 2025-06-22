;; Code Generation Main Module
;; Main orchestration for the code generation system
;;
;; NOTE: This module now generates WAT text format for debugging/inspection.
;; For primary binary WASM output (.wasm files), use the binary codegen backend
;; through compiler_main.wat which routes to codegen/binary_main.wat
;;
;; Phase 7.3: Binary WASM is now the primary compilation target.
;; WAT text output is available as a future feature for 'novo wat' command.

(module $codegen_main
  ;; Import memory for string storage
  (import "lexer_memory" "memory" (memory 1))

  ;; Import all code generation modules
  (import "codegen_core" "init_codegen" (func $init_codegen))
  (import "codegen_core" "get_output_buffer" (func $get_output_buffer (param i32)))
  (import "codegen_core" "init_type_strings" (func $init_type_strings))

  (import "codegen_module" "generate_module_header" (func $generate_module_header (param i32 i32) (result i32)))
  (import "codegen_module" "generate_memory_import" (func $generate_memory_import (param i32 i32 i32 i32 i32) (result i32)))
  (import "codegen_module" "generate_function_import" (func $generate_function_import (param i32 i32 i32 i32 i32 i32) (result i32)))
  (import "codegen_module" "generate_function_export" (func $generate_function_export (param i32 i32 i32 i32) (result i32)))
  (import "codegen_module" "generate_module_footer" (func $generate_module_footer (result i32)))

  (import "codegen_functions" "generate_function" (func $generate_function (param i32) (result i32)))
  (import "codegen_functions" "generate_function_signature" (func $generate_function_signature (param i32) (result i32)))

  (import "codegen_stack" "reset_stack_tracking" (func $reset_stack_tracking))
  (import "codegen_stack" "generate_stack_validation" (func $generate_stack_validation (result i32)))
  (import "codegen_stack" "validate_stack_balance" (func $validate_stack_balance (result i32)))

  (import "codegen_expressions" "generate_expression" (func $generate_expression (param i32) (result i32)))
  (import "codegen_control_flow" "generate_control_flow" (func $generate_control_flow (param i32) (result i32)))
  (import "codegen_patterns" "generate_pattern_matching" (func $generate_pattern_matching (param i32) (result i32)))
  (import "codegen_patterns" "check_exhaustiveness" (func $check_exhaustiveness (param i32) (result i32)))
  (import "codegen_error_handling" "has_error_propagation_pattern" (func $has_error_propagation_pattern (param i32) (result i32)))
  (import "codegen_error_handling" "generate_error_propagation_match" (func $generate_error_propagation_match (param i32) (result i32)))
  (import "codegen_error_handling" "validate_error_propagation" (func $validate_error_propagation (param i32) (result i32)))

  ;; Import AST for tree traversal
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "ast_node_core" "get_child_count" (func $get_child_count (param i32) (result i32)))
  (import "ast_node_core" "get_child" (func $get_child (param i32 i32) (result i32)))

  ;; Import AST node types
  (import "ast_node_types" "DECL_FUNCTION" (global $DECL_FUNCTION i32))
  (import "ast_node_types" "CTRL_MATCH" (global $CTRL_MATCH i32))
  (import "ast_node_types" "EXPR_BLOCK" (global $EXPR_BLOCK i32))

  ;; Code generation statistics
  (global $functions_generated (mut i32) (i32.const 0))
  (global $imports_generated (mut i32) (i32.const 0))
  (global $exports_generated (mut i32) (i32.const 0))

  ;; Initialize code generation system
  (func $init_code_generation (export "init_code_generation")
    (call $init_codegen)
    (call $init_type_strings)
    (call $reset_stack_tracking)
    (global.set $functions_generated (i32.const 0))
    (global.set $imports_generated (i32.const 0))
    (global.set $exports_generated (i32.const 0))
  )

  ;; Generate complete WASM module from AST (LEGACY: WAT text output)
  ;; NOTE: This function now generates WAT text format for debugging purposes.
  ;; For primary binary WASM output, use the binary codegen backend through compiler_main.
  ;; @param ast_root i32 - Root AST node
  ;; @param module_name_ptr i32 - Module name string
  ;; @param module_name_len i32 - Module name length
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $generate_wasm_module (export "generate_wasm_module")
        (param $ast_root i32) (param $module_name_ptr i32) (param $module_name_len i32) (result i32)
    (local $success i32)
    (local $child_count i32)
    (local $i i32)
    (local $child_node i32)
    (local $node_type i32)

    ;; Initialize code generation
    (call $init_code_generation)

    ;; Generate module header
    (local.set $success (call $generate_module_header (local.get $module_name_ptr) (local.get $module_name_len)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Generate basic memory import (for now, hardcoded)
    (local.set $success (call $generate_memory_import
      ;; Import from "lexer_memory" module, "memory" name, 1 page
      (i32.const 50000) (i32.const 12)  ;; "lexer_memory" at memory location 50000
      (i32.const 50013) (i32.const 6)   ;; "memory" at memory location 50013
      (i32.const 1)))

    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Traverse AST and generate functions
    (local.set $child_count (call $get_child_count (local.get $ast_root)))
    (local.set $i (i32.const 0))

    (loop $traverse_loop
      (if (i32.lt_u (local.get $i) (local.get $child_count))
        (then
          (local.set $child_node (call $get_child (local.get $ast_root) (local.get $i)))
          (local.set $node_type (call $get_node_type (local.get $child_node)))

          ;; Check if this is a function declaration
          (if (i32.eq (local.get $node_type) (global.get $DECL_FUNCTION))
            (then
              ;; Generate function
              (local.set $success (call $generate_function (local.get $child_node)))
              (if (i32.eqz (local.get $success))
                (then (return (i32.const 0))))

              ;; Increment function count
              (global.set $functions_generated (i32.add (global.get $functions_generated) (i32.const 1)))
            )
            (else
              ;; Check if this is a pattern matching construct
              (if (i32.eq (local.get $node_type) (global.get $CTRL_MATCH))
                (then
                  ;; Check exhaustiveness first
                  (if (i32.eqz (call $check_exhaustiveness (local.get $child_node)))
                    (then
                      ;; Non-exhaustive match - could be an error or warning
                      ;; For now, continue but this should ideally be handled
                    ))

                  ;; Check if this match contains error propagation patterns
                  (if (call $has_error_propagation_pattern (local.get $child_node))
                    (then
                      ;; Validate error propagation is correct
                      (if (call $validate_error_propagation (local.get $child_node))
                        (then
                          ;; Generate error propagation code
                          (local.set $success (call $generate_error_propagation_match (local.get $child_node)))
                        )
                        (else
                          ;; Invalid error propagation - should report error
                          (local.set $success (i32.const 0))
                        ))
                    )
                    (else
                      ;; Generate regular pattern matching code
                      (local.set $success (call $generate_pattern_matching (local.get $child_node)))
                    ))

                  (if (i32.eqz (local.get $success))
                    (then (return (i32.const 0))))
                )
                (else
                  ;; Check for other expression/control flow constructs
                  (if (i32.eq (local.get $node_type) (global.get $EXPR_BLOCK))
                    (then
                      ;; Generate block expression
                      (local.set $success (call $generate_control_flow (local.get $child_node)))
                      (if (i32.eqz (local.get $success))
                        (then (return (i32.const 0))))
                    ))
                ))))

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $traverse_loop))))

    ;; Generate stack validation comment
    (local.set $success (call $generate_stack_validation))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Generate module footer
    (local.set $success (call $generate_module_footer))
    (local.get $success)
  )

  ;; Generate minimal test module
  ;; @param module_name_ptr i32 - Module name string
  ;; @param module_name_len i32 - Module name length
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $generate_test_module (export "generate_test_module")
        (param $module_name_ptr i32) (param $module_name_len i32) (result i32)
    (local $success i32)

    ;; Initialize code generation
    (call $init_code_generation)

    ;; Generate module header
    (local.set $success (call $generate_module_header (local.get $module_name_ptr) (local.get $module_name_len)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Generate basic memory import
    (local.set $success (call $generate_memory_import
      (i32.const 50000) (i32.const 12)  ;; "lexer_memory"
      (i32.const 50013) (i32.const 6)   ;; "memory"
      (i32.const 1)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Generate a simple test function (AST node 0 = placeholder)
    (local.set $success (call $generate_function (i32.const 0)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Generate function export
    (local.set $success (call $generate_function_export
      (i32.const 50020) (i32.const 9)   ;; "test_func"
      (i32.const 50020) (i32.const 9))) ;; Export with same name
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Generate stack validation and module footer
    (local.set $success (call $generate_stack_validation))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    (call $generate_module_footer)
  )

  ;; Get generated code output
  ;; @param result_ptr i32 - Pointer to store result (ptr, len)
  (func $get_generated_code (export "get_generated_code") (param $result_ptr i32)
    (call $get_output_buffer (local.get $result_ptr))
  )

  ;; Get code generation statistics
  ;; @param stats_ptr i32 - Pointer to store stats (functions, imports, exports)
  (func $get_codegen_stats (export "get_codegen_stats") (param $stats_ptr i32)
    (i32.store (local.get $stats_ptr) (global.get $functions_generated))
    (i32.store offset=4 (local.get $stats_ptr) (global.get $imports_generated))
    (i32.store offset=8 (local.get $stats_ptr) (global.get $exports_generated))
  )

  ;; Initialize static strings in memory
  (func $init_static_strings (export "init_static_strings")
    (local $i i32)

    ;; Store "lexer_memory" at offset 50000
    (i32.store8 offset=50000 (i32.const 0) (i32.const 108)) ;; 'l'
    (i32.store8 offset=50001 (i32.const 0) (i32.const 101)) ;; 'e'
    (i32.store8 offset=50002 (i32.const 0) (i32.const 120)) ;; 'x'
    (i32.store8 offset=50003 (i32.const 0) (i32.const 101)) ;; 'e'
    (i32.store8 offset=50004 (i32.const 0) (i32.const 114)) ;; 'r'
    (i32.store8 offset=50005 (i32.const 0) (i32.const 95))  ;; '_'
    (i32.store8 offset=50006 (i32.const 0) (i32.const 109)) ;; 'm'
    (i32.store8 offset=50007 (i32.const 0) (i32.const 101)) ;; 'e'
    (i32.store8 offset=50008 (i32.const 0) (i32.const 109)) ;; 'm'
    (i32.store8 offset=50009 (i32.const 0) (i32.const 111)) ;; 'o'
    (i32.store8 offset=50010 (i32.const 0) (i32.const 114)) ;; 'r'
    (i32.store8 offset=50011 (i32.const 0) (i32.const 121)) ;; 'y'

    ;; Store "memory" at offset 50013
    (i32.store8 offset=50013 (i32.const 0) (i32.const 109)) ;; 'm'
    (i32.store8 offset=50014 (i32.const 0) (i32.const 101)) ;; 'e'
    (i32.store8 offset=50015 (i32.const 0) (i32.const 109)) ;; 'm'
    (i32.store8 offset=50016 (i32.const 0) (i32.const 111)) ;; 'o'
    (i32.store8 offset=50017 (i32.const 0) (i32.const 114)) ;; 'r'
    (i32.store8 offset=50018 (i32.const 0) (i32.const 121)) ;; 'y'

    ;; Store "test_func" at offset 50020
    (i32.store8 offset=50020 (i32.const 0) (i32.const 116)) ;; 't'
    (i32.store8 offset=50021 (i32.const 0) (i32.const 101)) ;; 'e'
    (i32.store8 offset=50022 (i32.const 0) (i32.const 115)) ;; 's'
    (i32.store8 offset=50023 (i32.const 0) (i32.const 116)) ;; 't'
    (i32.store8 offset=50024 (i32.const 0) (i32.const 95))  ;; '_'
    (i32.store8 offset=50025 (i32.const 0) (i32.const 102)) ;; 'f'
    (i32.store8 offset=50026 (i32.const 0) (i32.const 117)) ;; 'u'
    (i32.store8 offset=50027 (i32.const 0) (i32.const 110)) ;; 'n'
    (i32.store8 offset=50028 (i32.const 0) (i32.const 99))  ;; 'c'
  )
)
