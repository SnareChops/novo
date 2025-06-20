;; Function Signature and Body Generation
;; Handles WebAssembly function declaration and implementation generation

(module $codegen_functions
  ;; Import memory for string storage
  (import "lexer_memory" "memory" (memory 1))

  ;; Import code generation core
  (import "codegen_core" "write_output" (func $write_output (param i32 i32) (result i32)))
  (import "codegen_core" "allocate_workspace" (func $allocate_workspace (param i32) (result i32)))
  (import "codegen_core" "get_wasm_type_string" (func $get_wasm_type_string (param i32 i32)))
  (import "codegen_core" "register_local_var" (func $register_local_var (param i32 i32 i32) (result i32)))
  (import "codegen_core" "clear_local_vars" (func $clear_local_vars))

  ;; Import AST for function traversal
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "ast_node_core" "get_child_count" (func $get_child_count (param i32) (result i32)))
  (import "ast_node_core" "get_child" (func $get_child (param i32 i32) (result i32)))

  ;; Import AST node types
  (import "ast_node_types" "DECL_FUNCTION" (global $DECL_FUNCTION i32))

  ;; Import type checker
  (import "typechecker_main" "get_node_type_info" (func $get_node_type_info (param i32) (result i32)))

  ;; Function generation state
  (global $current_function_node (mut i32) (i32.const 0))
  (global $current_function_locals (mut i32) (i32.const 0))

  ;; Generate function signature
  ;; @param func_node i32 - AST node for function declaration
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $generate_function_signature (export "generate_function_signature") (param $func_node i32) (result i32)
    (local $sig_start i32)
    (local $success i32)
    (local $child_count i32)
    (local $name_node i32)
    (local $param_count i32)
    (local $i i32)
    (local $param_node i32)
    (local $type_info i32)
    (local $type_str_info i32)
    (local $type_str_ptr i32)
    (local $type_str_len i32)

    ;; Store current function for body generation
    (global.set $current_function_node (local.get $func_node))

    ;; Clear local variables from previous function
    (call $clear_local_vars)

    ;; Allocate workspace for signature
    (local.set $sig_start (call $allocate_workspace (i32.const 128)))
    (if (i32.eqz (local.get $sig_start))
      (then (return (i32.const 0))))

    ;; Allocate space for type string info
    (local.set $type_str_info (call $allocate_workspace (i32.const 8)))
    (if (i32.eqz (local.get $type_str_info))
      (then (return (i32.const 0))))

    ;; Build "  (func $" string
    (i32.store8 (local.get $sig_start) (i32.const 32))       ;; ' '
    (i32.store8 offset=1 (local.get $sig_start) (i32.const 32))    ;; ' '
    (i32.store8 offset=2 (local.get $sig_start) (i32.const 40))    ;; '('
    (i32.store8 offset=3 (local.get $sig_start) (i32.const 102))   ;; 'f'
    (i32.store8 offset=4 (local.get $sig_start) (i32.const 117))   ;; 'u'
    (i32.store8 offset=5 (local.get $sig_start) (i32.const 110))   ;; 'n'
    (i32.store8 offset=6 (local.get $sig_start) (i32.const 99))    ;; 'c'
    (i32.store8 offset=7 (local.get $sig_start) (i32.const 32))    ;; ' '
    (i32.store8 offset=8 (local.get $sig_start) (i32.const 36))    ;; '$'

    ;; Write function declaration start
    (local.set $success (call $write_output (local.get $sig_start) (i32.const 9)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Get function name (first child)
    (local.set $child_count (call $get_child_count (local.get $func_node)))
    (if (i32.lt_u (local.get $child_count) (i32.const 1))
      (then (return (i32.const 0)))) ;; No name

    (local.set $name_node (call $get_child (local.get $func_node) (i32.const 0)))

    ;; For now, write a placeholder function name "test_func"
    ;; TODO: Extract actual function name from AST
    (i32.store8 (local.get $sig_start) (i32.const 116))      ;; 't'
    (i32.store8 offset=1 (local.get $sig_start) (i32.const 101))   ;; 'e'
    (i32.store8 offset=2 (local.get $sig_start) (i32.const 115))   ;; 's'
    (i32.store8 offset=3 (local.get $sig_start) (i32.const 116))   ;; 't'
    (i32.store8 offset=4 (local.get $sig_start) (i32.const 95))    ;; '_'
    (i32.store8 offset=5 (local.get $sig_start) (i32.const 102))   ;; 'f'
    (i32.store8 offset=6 (local.get $sig_start) (i32.const 117))   ;; 'u'
    (i32.store8 offset=7 (local.get $sig_start) (i32.const 110))   ;; 'n'
    (i32.store8 offset=8 (local.get $sig_start) (i32.const 99))    ;; 'c'

    (local.set $success (call $write_output (local.get $sig_start) (i32.const 9)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; For now, generate simple signature without parameters
    ;; TODO: Add parameter parsing and type generation

    ;; Write newline to complete signature line
    (i32.store8 (local.get $sig_start) (i32.const 10))       ;; '\n'
    (call $write_output (local.get $sig_start) (i32.const 1))
  )

  ;; Generate function body opening
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $generate_function_body_start (export "generate_function_body_start") (result i32)
    (local $body_start i32)
    (local $success i32)

    ;; Allocate workspace
    (local.set $body_start (call $allocate_workspace (i32.const 32)))
    (if (i32.eqz (local.get $body_start))
      (then (return (i32.const 0))))

    ;; For now, generate minimal function body
    ;; TODO: Implement actual body generation from AST

    ;; Write simple body with return constant
    ;; "    (i32.const 42)\n"
    (i32.store8 (local.get $body_start) (i32.const 32))       ;; ' '
    (i32.store8 offset=1 (local.get $body_start) (i32.const 32))    ;; ' '
    (i32.store8 offset=2 (local.get $body_start) (i32.const 32))    ;; ' '
    (i32.store8 offset=3 (local.get $body_start) (i32.const 32))    ;; ' '
    (i32.store8 offset=4 (local.get $body_start) (i32.const 40))    ;; '('
    (i32.store8 offset=5 (local.get $body_start) (i32.const 105))   ;; 'i'
    (i32.store8 offset=6 (local.get $body_start) (i32.const 51))    ;; '3'
    (i32.store8 offset=7 (local.get $body_start) (i32.const 50))    ;; '2'
    (i32.store8 offset=8 (local.get $body_start) (i32.const 46))    ;; '.'
    (i32.store8 offset=9 (local.get $body_start) (i32.const 99))    ;; 'c'
    (i32.store8 offset=10 (local.get $body_start) (i32.const 111))  ;; 'o'
    (i32.store8 offset=11 (local.get $body_start) (i32.const 110))  ;; 'n'
    (i32.store8 offset=12 (local.get $body_start) (i32.const 115))  ;; 's'
    (i32.store8 offset=13 (local.get $body_start) (i32.const 116))  ;; 't'
    (i32.store8 offset=14 (local.get $body_start) (i32.const 32))   ;; ' '
    (i32.store8 offset=15 (local.get $body_start) (i32.const 52))   ;; '4'
    (i32.store8 offset=16 (local.get $body_start) (i32.const 50))   ;; '2'
    (i32.store8 offset=17 (local.get $body_start) (i32.const 41))   ;; ')'
    (i32.store8 offset=18 (local.get $body_start) (i32.const 10))   ;; '\n'

    (call $write_output (local.get $body_start) (i32.const 19))
  )

  ;; Generate function body closing
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $generate_function_body_end (export "generate_function_body_end") (result i32)
    (local $body_end i32)

    ;; Allocate workspace
    (local.set $body_end (call $allocate_workspace (i32.const 8)))
    (if (i32.eqz (local.get $body_end))
      (then (return (i32.const 0))))

    ;; Write function closing "  )\n"
    (i32.store8 (local.get $body_end) (i32.const 32))         ;; ' '
    (i32.store8 offset=1 (local.get $body_end) (i32.const 32))      ;; ' '
    (i32.store8 offset=2 (local.get $body_end) (i32.const 41))      ;; ')'
    (i32.store8 offset=3 (local.get $body_end) (i32.const 10))      ;; '\n'

    (call $write_output (local.get $body_end) (i32.const 4))
  )

  ;; Generate complete function from AST node
  ;; @param func_node i32 - AST node for function declaration
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $generate_function (export "generate_function") (param $func_node i32) (result i32)
    (local $success i32)

    ;; Validate input
    (if (i32.eqz (local.get $func_node))
      (then (return (i32.const 0))))

    ;; Generate function signature
    (local.set $success (call $generate_function_signature (local.get $func_node)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Generate function body
    (local.set $success (call $generate_function_body_start))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Generate function closing
    (call $generate_function_body_end)
  )

  ;; Generate parameter declaration
  ;; @param param_name_ptr i32 - Parameter name
  ;; @param param_name_len i32 - Parameter name length
  ;; @param param_type i32 - Parameter type ID
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $generate_parameter (export "generate_parameter")
        (param $param_name_ptr i32) (param $param_name_len i32) (param $param_type i32) (result i32)
    (local $param_start i32)
    (local $success i32)
    (local $type_str_info i32)
    (local $type_str_ptr i32)
    (local $type_str_len i32)

    ;; Allocate workspace
    (local.set $param_start (call $allocate_workspace (i32.const 64)))
    (if (i32.eqz (local.get $param_start))
      (then (return (i32.const 0))))

    (local.set $type_str_info (call $allocate_workspace (i32.const 8)))
    (if (i32.eqz (local.get $type_str_info))
      (then (return (i32.const 0))))

    ;; Get WASM type string
    (call $get_wasm_type_string (local.get $param_type) (local.get $type_str_info))
    (local.set $type_str_ptr (i32.load (local.get $type_str_info)))
    (local.set $type_str_len (i32.load offset=4 (local.get $type_str_info)))

    ;; Build "(param $" string
    (i32.store8 (local.get $param_start) (i32.const 40))      ;; '('
    (i32.store8 offset=1 (local.get $param_start) (i32.const 112))   ;; 'p'
    (i32.store8 offset=2 (local.get $param_start) (i32.const 97))    ;; 'a'
    (i32.store8 offset=3 (local.get $param_start) (i32.const 114))   ;; 'r'
    (i32.store8 offset=4 (local.get $param_start) (i32.const 97))    ;; 'a'
    (i32.store8 offset=5 (local.get $param_start) (i32.const 109))   ;; 'm'
    (i32.store8 offset=6 (local.get $param_start) (i32.const 32))    ;; ' '
    (i32.store8 offset=7 (local.get $param_start) (i32.const 36))    ;; '$'

    ;; Write parameter declaration start
    (local.set $success (call $write_output (local.get $param_start) (i32.const 8)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write parameter name
    (local.set $success (call $write_output (local.get $param_name_ptr) (local.get $param_name_len)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write space
    (i32.store8 (local.get $param_start) (i32.const 32))      ;; ' '
    (local.set $success (call $write_output (local.get $param_start) (i32.const 1)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write parameter type
    (local.set $success (call $write_output (local.get $type_str_ptr) (local.get $type_str_len)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write closing ")"
    (i32.store8 (local.get $param_start) (i32.const 41))      ;; ')'
    (call $write_output (local.get $param_start) (i32.const 1))
  )

  ;; Generate return type declaration
  ;; @param return_type i32 - Return type ID
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $generate_return_type (export "generate_return_type") (param $return_type i32) (result i32)
    (local $return_start i32)
    (local $success i32)
    (local $type_str_info i32)
    (local $type_str_ptr i32)
    (local $type_str_len i32)

    ;; Allocate workspace
    (local.set $return_start (call $allocate_workspace (i32.const 32)))
    (if (i32.eqz (local.get $return_start))
      (then (return (i32.const 0))))

    (local.set $type_str_info (call $allocate_workspace (i32.const 8)))
    (if (i32.eqz (local.get $type_str_info))
      (then (return (i32.const 0))))

    ;; Get WASM type string
    (call $get_wasm_type_string (local.get $return_type) (local.get $type_str_info))
    (local.set $type_str_ptr (i32.load (local.get $type_str_info)))
    (local.set $type_str_len (i32.load offset=4 (local.get $type_str_info)))

    ;; Build "(result " string
    (i32.store8 (local.get $return_start) (i32.const 40))     ;; '('
    (i32.store8 offset=1 (local.get $return_start) (i32.const 114))  ;; 'r'
    (i32.store8 offset=2 (local.get $return_start) (i32.const 101))  ;; 'e'
    (i32.store8 offset=3 (local.get $return_start) (i32.const 115))  ;; 's'
    (i32.store8 offset=4 (local.get $return_start) (i32.const 117))  ;; 'u'
    (i32.store8 offset=5 (local.get $return_start) (i32.const 108))  ;; 'l'
    (i32.store8 offset=6 (local.get $return_start) (i32.const 116))  ;; 't'
    (i32.store8 offset=7 (local.get $return_start) (i32.const 32))   ;; ' '

    ;; Write result declaration start
    (local.set $success (call $write_output (local.get $return_start) (i32.const 8)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write return type
    (local.set $success (call $write_output (local.get $type_str_ptr) (local.get $type_str_len)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write closing ")"
    (i32.store8 (local.get $return_start) (i32.const 41))     ;; ')'
    (call $write_output (local.get $return_start) (i32.const 1))
  )
)
