;; WASM Module Structure Generation
;; Handles generation of WebAssembly module structure and metadata

(module $codegen_module
  ;; Import memory for string storage
  (import "lexer_memory" "memory" (memory 1))

  ;; Import code generation core
  (import "codegen_core" "write_output" (func $write_output (param i32 i32) (result i32)))
  (import "codegen_core" "allocate_workspace" (func $allocate_workspace (param i32) (result i32)))
  (import "codegen_core" "get_wasm_type_string" (func $get_wasm_type_string (param i32 i32)))

  ;; Module generation state
  (global $module_name_ptr (mut i32) (i32.const 0))
  (global $module_name_len (mut i32) (i32.const 0))
  (global $import_count (mut i32) (i32.const 0))
  (global $export_count (mut i32) (i32.const 0))
  (global $function_count (mut i32) (i32.const 0))

  ;; Generate module header
  ;; @param module_name_ptr i32 - Pointer to module name string
  ;; @param module_name_len i32 - Length of module name
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $generate_module_header (export "generate_module_header") (param $name_ptr i32) (param $name_len i32) (result i32)
    (local $header_start i32)
    (local $success i32)

    ;; Store module name for later use
    (global.set $module_name_ptr (local.get $name_ptr))
    (global.set $module_name_len (local.get $name_len))

    ;; Write module opening
    (local.set $header_start (call $allocate_workspace (i32.const 64)))
    (if (i32.eqz (local.get $header_start))
      (then (return (i32.const 0))))

    ;; Build "(module $" string
    (i32.store8 (local.get $header_start) (i32.const 40))       ;; '('
    (i32.store8 offset=1 (local.get $header_start) (i32.const 109))  ;; 'm'
    (i32.store8 offset=2 (local.get $header_start) (i32.const 111))  ;; 'o'
    (i32.store8 offset=3 (local.get $header_start) (i32.const 100))  ;; 'd'
    (i32.store8 offset=4 (local.get $header_start) (i32.const 117))  ;; 'u'
    (i32.store8 offset=5 (local.get $header_start) (i32.const 108))  ;; 'l'
    (i32.store8 offset=6 (local.get $header_start) (i32.const 101))  ;; 'e'
    (i32.store8 offset=7 (local.get $header_start) (i32.const 32))   ;; ' '
    (i32.store8 offset=8 (local.get $header_start) (i32.const 36))   ;; '$'

    ;; Write module header start
    (local.set $success (call $write_output (local.get $header_start) (i32.const 9)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write module name
    (local.set $success (call $write_output (local.get $name_ptr) (local.get $name_len)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write newline
    (i32.store8 (local.get $header_start) (i32.const 10)) ;; '\n'
    (call $write_output (local.get $header_start) (i32.const 1))
  )

  ;; Generate memory import
  ;; @param module_name_ptr i32 - Module to import from
  ;; @param module_name_len i32 - Length of module name
  ;; @param memory_name_ptr i32 - Memory name to import
  ;; @param memory_name_len i32 - Length of memory name
  ;; @param initial_pages i32 - Initial memory pages
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $generate_memory_import (export "generate_memory_import")
        (param $mod_name_ptr i32) (param $mod_name_len i32)
        (param $mem_name_ptr i32) (param $mem_name_len i32)
        (param $initial_pages i32) (result i32)
    (local $import_start i32)
    (local $success i32)

    ;; Allocate workspace for import string
    (local.set $import_start (call $allocate_workspace (i32.const 128)))
    (if (i32.eqz (local.get $import_start))
      (then (return (i32.const 0))))

    ;; Build "  (import \"" string
    (i32.store8 (local.get $import_start) (i32.const 32))      ;; ' '
    (i32.store8 offset=1 (local.get $import_start) (i32.const 32))   ;; ' '
    (i32.store8 offset=2 (local.get $import_start) (i32.const 40))   ;; '('
    (i32.store8 offset=3 (local.get $import_start) (i32.const 105))  ;; 'i'
    (i32.store8 offset=4 (local.get $import_start) (i32.const 109))  ;; 'm'
    (i32.store8 offset=5 (local.get $import_start) (i32.const 112))  ;; 'p'
    (i32.store8 offset=6 (local.get $import_start) (i32.const 111))  ;; 'o'
    (i32.store8 offset=7 (local.get $import_start) (i32.const 114))  ;; 'r'
    (i32.store8 offset=8 (local.get $import_start) (i32.const 116))  ;; 't'
    (i32.store8 offset=9 (local.get $import_start) (i32.const 32))   ;; ' '
    (i32.store8 offset=10 (local.get $import_start) (i32.const 34))  ;; '"'

    ;; Write import prefix
    (local.set $success (call $write_output (local.get $import_start) (i32.const 11)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write module name
    (local.set $success (call $write_output (local.get $mod_name_ptr) (local.get $mod_name_len)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Build "\" \"" string
    (i32.store8 (local.get $import_start) (i32.const 34))     ;; '"'
    (i32.store8 offset=1 (local.get $import_start) (i32.const 32))  ;; ' '
    (i32.store8 offset=2 (local.get $import_start) (i32.const 34))  ;; '"'

    ;; Write separator
    (local.set $success (call $write_output (local.get $import_start) (i32.const 3)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write memory name
    (local.set $success (call $write_output (local.get $mem_name_ptr) (local.get $mem_name_len)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Build "\" (memory " string
    (i32.store8 (local.get $import_start) (i32.const 34))     ;; '"'
    (i32.store8 offset=1 (local.get $import_start) (i32.const 32))  ;; ' '
    (i32.store8 offset=2 (local.get $import_start) (i32.const 40))  ;; '('
    (i32.store8 offset=3 (local.get $import_start) (i32.const 109)) ;; 'm'
    (i32.store8 offset=4 (local.get $import_start) (i32.const 101)) ;; 'e'
    (i32.store8 offset=5 (local.get $import_start) (i32.const 109)) ;; 'm'
    (i32.store8 offset=6 (local.get $import_start) (i32.const 111)) ;; 'o'
    (i32.store8 offset=7 (local.get $import_start) (i32.const 114)) ;; 'r'
    (i32.store8 offset=8 (local.get $import_start) (i32.const 121)) ;; 'y'
    (i32.store8 offset=9 (local.get $import_start) (i32.const 32))  ;; ' '

    ;; Write memory declaration start
    (local.set $success (call $write_output (local.get $import_start) (i32.const 10)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write initial pages (simplified - just write "1" for now)
    (i32.store8 (local.get $import_start) (i32.const 49))     ;; '1'
    (local.set $success (call $write_output (local.get $import_start) (i32.const 1)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write closing "))\n"
    (i32.store8 (local.get $import_start) (i32.const 41))     ;; ')'
    (i32.store8 offset=1 (local.get $import_start) (i32.const 41))  ;; ')'
    (i32.store8 offset=2 (local.get $import_start) (i32.const 10))  ;; '\n'

    (call $write_output (local.get $import_start) (i32.const 3))
  )

  ;; Generate function import
  ;; @param module_name_ptr i32 - Module to import from
  ;; @param module_name_len i32 - Length of module name
  ;; @param func_name_ptr i32 - Function name to import
  ;; @param func_name_len i32 - Length of function name
  ;; @param local_name_ptr i32 - Local function name
  ;; @param local_name_len i32 - Length of local name
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $generate_function_import (export "generate_function_import")
        (param $mod_name_ptr i32) (param $mod_name_len i32)
        (param $func_name_ptr i32) (param $func_name_len i32)
        (param $local_name_ptr i32) (param $local_name_len i32) (result i32)
    (local $import_start i32)
    (local $success i32)

    ;; Allocate workspace
    (local.set $import_start (call $allocate_workspace (i32.const 128)))
    (if (i32.eqz (local.get $import_start))
      (then (return (i32.const 0))))

    ;; Build "  (import \"" string (same as memory import)
    (i32.store8 (local.get $import_start) (i32.const 32))      ;; ' '
    (i32.store8 offset=1 (local.get $import_start) (i32.const 32))   ;; ' '
    (i32.store8 offset=2 (local.get $import_start) (i32.const 40))   ;; '('
    (i32.store8 offset=3 (local.get $import_start) (i32.const 105))  ;; 'i'
    (i32.store8 offset=4 (local.get $import_start) (i32.const 109))  ;; 'm'
    (i32.store8 offset=5 (local.get $import_start) (i32.const 112))  ;; 'p'
    (i32.store8 offset=6 (local.get $import_start) (i32.const 111))  ;; 'o'
    (i32.store8 offset=7 (local.get $import_start) (i32.const 114))  ;; 'r'
    (i32.store8 offset=8 (local.get $import_start) (i32.const 116))  ;; 't'
    (i32.store8 offset=9 (local.get $import_start) (i32.const 32))   ;; ' '
    (i32.store8 offset=10 (local.get $import_start) (i32.const 34))  ;; '"'

    ;; Write import prefix
    (local.set $success (call $write_output (local.get $import_start) (i32.const 11)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write module name, separator, function name (similar to memory import)
    (local.set $success (call $write_output (local.get $mod_name_ptr) (local.get $mod_name_len)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write separator
    (i32.store8 (local.get $import_start) (i32.const 34))     ;; '"'
    (i32.store8 offset=1 (local.get $import_start) (i32.const 32))  ;; ' '
    (i32.store8 offset=2 (local.get $import_start) (i32.const 34))  ;; '"'
    (local.set $success (call $write_output (local.get $import_start) (i32.const 3)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write function name
    (local.set $success (call $write_output (local.get $func_name_ptr) (local.get $func_name_len)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Build "\" (func $" string
    (i32.store8 (local.get $import_start) (i32.const 34))     ;; '"'
    (i32.store8 offset=1 (local.get $import_start) (i32.const 32))  ;; ' '
    (i32.store8 offset=2 (local.get $import_start) (i32.const 40))  ;; '('
    (i32.store8 offset=3 (local.get $import_start) (i32.const 102)) ;; 'f'
    (i32.store8 offset=4 (local.get $import_start) (i32.const 117)) ;; 'u'
    (i32.store8 offset=5 (local.get $import_start) (i32.const 110)) ;; 'n'
    (i32.store8 offset=6 (local.get $import_start) (i32.const 99))  ;; 'c'
    (i32.store8 offset=7 (local.get $import_start) (i32.const 32))  ;; ' '
    (i32.store8 offset=8 (local.get $import_start) (i32.const 36))  ;; '$'

    ;; Write function declaration start
    (local.set $success (call $write_output (local.get $import_start) (i32.const 9)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write local function name
    (local.set $success (call $write_output (local.get $local_name_ptr) (local.get $local_name_len)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; For now, write simplified signature - TODO: enhance with actual parameter/return types
    ;; Write "))\n"
    (i32.store8 (local.get $import_start) (i32.const 41))     ;; ')'
    (i32.store8 offset=1 (local.get $import_start) (i32.const 41))  ;; ')'
    (i32.store8 offset=2 (local.get $import_start) (i32.const 10))  ;; '\n'

    (call $write_output (local.get $import_start) (i32.const 3))
  )

  ;; Generate function export
  ;; @param func_name_ptr i32 - Function name to export
  ;; @param func_name_len i32 - Length of function name
  ;; @param export_name_ptr i32 - Export name
  ;; @param export_name_len i32 - Length of export name
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $generate_function_export (export "generate_function_export")
        (param $func_name_ptr i32) (param $func_name_len i32)
        (param $export_name_ptr i32) (param $export_name_len i32) (result i32)
    (local $export_start i32)
    (local $success i32)

    ;; Allocate workspace
    (local.set $export_start (call $allocate_workspace (i32.const 128)))
    (if (i32.eqz (local.get $export_start))
      (then (return (i32.const 0))))

    ;; Build "  (export \"" string
    (i32.store8 (local.get $export_start) (i32.const 32))      ;; ' '
    (i32.store8 offset=1 (local.get $export_start) (i32.const 32))   ;; ' '
    (i32.store8 offset=2 (local.get $export_start) (i32.const 40))   ;; '('
    (i32.store8 offset=3 (local.get $export_start) (i32.const 101))  ;; 'e'
    (i32.store8 offset=4 (local.get $export_start) (i32.const 120))  ;; 'x'
    (i32.store8 offset=5 (local.get $export_start) (i32.const 112))  ;; 'p'
    (i32.store8 offset=6 (local.get $export_start) (i32.const 111))  ;; 'o'
    (i32.store8 offset=7 (local.get $export_start) (i32.const 114))  ;; 'r'
    (i32.store8 offset=8 (local.get $export_start) (i32.const 116))  ;; 't'
    (i32.store8 offset=9 (local.get $export_start) (i32.const 32))   ;; ' '
    (i32.store8 offset=10 (local.get $export_start) (i32.const 34))  ;; '"'

    ;; Write export prefix
    (local.set $success (call $write_output (local.get $export_start) (i32.const 11)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write export name
    (local.set $success (call $write_output (local.get $export_name_ptr) (local.get $export_name_len)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Build "\" (func $" string
    (i32.store8 (local.get $export_start) (i32.const 34))     ;; '"'
    (i32.store8 offset=1 (local.get $export_start) (i32.const 32))  ;; ' '
    (i32.store8 offset=2 (local.get $export_start) (i32.const 40))  ;; '('
    (i32.store8 offset=3 (local.get $export_start) (i32.const 102)) ;; 'f'
    (i32.store8 offset=4 (local.get $export_start) (i32.const 117)) ;; 'u'
    (i32.store8 offset=5 (local.get $export_start) (i32.const 110)) ;; 'n'
    (i32.store8 offset=6 (local.get $export_start) (i32.const 99))  ;; 'c'
    (i32.store8 offset=7 (local.get $export_start) (i32.const 32))  ;; ' '
    (i32.store8 offset=8 (local.get $export_start) (i32.const 36))  ;; '$'

    ;; Write function reference start
    (local.set $success (call $write_output (local.get $export_start) (i32.const 9)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write function name
    (local.set $success (call $write_output (local.get $func_name_ptr) (local.get $func_name_len)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write closing "))\n"
    (i32.store8 (local.get $export_start) (i32.const 41))     ;; ')'
    (i32.store8 offset=1 (local.get $export_start) (i32.const 41))  ;; ')'
    (i32.store8 offset=2 (local.get $export_start) (i32.const 10))  ;; '\n'

    (call $write_output (local.get $export_start) (i32.const 3))
  )

  ;; Generate module footer
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $generate_module_footer (export "generate_module_footer") (result i32)
    (local $footer_start i32)

    (local.set $footer_start (call $allocate_workspace (i32.const 8)))
    (if (i32.eqz (local.get $footer_start))
      (then (return (i32.const 0))))

    ;; Write closing ")\n"
    (i32.store8 (local.get $footer_start) (i32.const 41))     ;; ')'
    (i32.store8 offset=1 (local.get $footer_start) (i32.const 10))  ;; '\n'

    (call $write_output (local.get $footer_start) (i32.const 2))
  )
)
