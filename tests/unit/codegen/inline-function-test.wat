;; Novo Inline Function Codegen Test
;; Tests that inline functions are properly registered during code generation

(module $inline_function_test
  ;; Import memory for AST storage
  (import "lexer_memory" "memory" (memory 1))

  ;; Import AST functions
  (import "ast_main" "init_ast" (func $init_ast))
  (import "ast_main" "create_decl_function" (func $create_decl_function (param i32 i32 i32 i32 i32 i32) (result i32)))
  (import "ast_main" "get_function_inline_flag" (func $get_function_inline_flag (param i32) (result i32)))

  ;; Import codegen functions
  (import "codegen_main" "init_code_generation" (func $init_code_generation))
  (import "codegen_main" "register_inline_functions_from_ast" (func $register_inline_functions_from_ast (param i32) (result i32)))
  (import "codegen_inline" "get_inline_stats" (func $get_inline_stats (result i32)))
  (import "codegen_inline" "find_inline_function" (func $find_inline_function (param i32 i32) (result i32)))

  ;; Global for test results
  (global $test_passed (mut i32) (i32.const 0))

  ;; Test function
  (func $test_inline_registration (export "test_inline_registration") (result i32)
    (local $func_node i32)
    (local $registered_count i32)
    (local $found_func i32)

    ;; Initialize AST and codegen
    (call $init_ast)
    (call $init_code_generation)

    ;; Create a test inline function node
    ;; create_decl_function(name_ptr, name_len, params_ptr, params_len, return_type, inline_flag)
    ;; For this test, let's create a simple inline function called "square"
    (call $store_test_strings)
    (local.set $func_node (call $create_decl_function
      (i32.const 1000) (i32.const 6)  ;; "square" name
      (i32.const 0) (i32.const 0)     ;; no params for this test
      (i32.const 0)                   ;; no return type for this test
      (i32.const 1)))                 ;; inline flag = true

    ;; Verify the function is marked as inline
    (if (i32.eqz (call $get_function_inline_flag (local.get $func_node)))
      (then
        ;; Function not marked as inline, test failed
        (global.set $test_passed (i32.const 0))
        (return (i32.const 0))
      )
    )

    ;; Create a mock AST root with the function
    ;; For this test, we'll use the function node directly as a simple case
    (local.set $registered_count (call $register_inline_functions_from_ast (local.get $func_node)))

    ;; Check if exactly 1 function was registered
    (if (i32.ne (local.get $registered_count) (i32.const 1))
      (then
        ;; Wrong number of functions registered, test failed
        (global.set $test_passed (i32.const 0))
        (return (i32.const 0))
      )
    )

    ;; Check inline stats
    (if (i32.ne (call $get_inline_stats) (i32.const 1))
      (then
        ;; Inline stats don't match, test failed
        (global.set $test_passed (i32.const 0))
        (return (i32.const 0))
      )
    )

    ;; Try to find the function by name
    (local.set $found_func (call $find_inline_function (i32.const 1000) (i32.const 6))) ;; "square"
    (if (i32.eqz (local.get $found_func))
      (then
        ;; Function not found, test failed
        (global.set $test_passed (i32.const 0))
        (return (i32.const 0))
      )
    )

    ;; All tests passed
    (global.set $test_passed (i32.const 1))
    (i32.const 1)
  )

  ;; Helper function to store test strings in memory
  (func $store_test_strings
    ;; Store "square" at offset 1000
    (i32.store8 offset=1000 (i32.const 0) (i32.const 115)) ;; 's'
    (i32.store8 offset=1001 (i32.const 0) (i32.const 113)) ;; 'q'
    (i32.store8 offset=1002 (i32.const 0) (i32.const 117)) ;; 'u'
    (i32.store8 offset=1003 (i32.const 0) (i32.const 97))  ;; 'a'
    (i32.store8 offset=1004 (i32.const 0) (i32.const 114)) ;; 'r'
    (i32.store8 offset=1005 (i32.const 0) (i32.const 101)) ;; 'e'
  )

  ;; Get test result
  (func $get_test_result (export "get_test_result") (result i32)
    (global.get $test_passed)
  )
)
