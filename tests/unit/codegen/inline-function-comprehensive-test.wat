;; Novo Inline Function Comprehensive Test
;; Tests enhanced inline function functionality including call detection and generation

(module $inline_function_comprehensive_test
  ;; Import memory for AST storage
  (import "memory" "memory" (memory 1))

  ;; Import AST functions
  (import "ast_main" "init_ast" (func $init_ast))
  (import "ast_main" "create_decl_function" (func $create_decl_function (param i32 i32 i32 i32 i32 i32) (result i32)))
  (import "ast_main" "create_expr_identifier" (func $create_expr_identifier (param i32 i32) (result i32)))
  (import "ast_main" "create_expr_traditional_call" (func $create_expr_traditional_call (param i32 i32) (result i32)))

  ;; Import codegen functions
  (import "codegen_main" "init_code_generation" (func $init_code_generation))
  (import "codegen_main" "register_inline_functions_from_ast" (func $register_inline_functions_from_ast (param i32) (result i32)))
  (import "codegen_inline" "can_inline_call" (func $can_inline_call (param i32) (result i32)))
  (import "codegen_inline" "generate_inline_call" (func $generate_inline_call (param i32) (result i32)))
  (import "codegen_inline" "find_inline_function" (func $find_inline_function (param i32 i32) (result i32)))

  ;; Global for test results
  (global $test_passed (mut i32) (i32.const 0))

  ;; Test function
  (func $test_inline_call_processing (export "test_inline_call_processing") (result i32)
    (local $func_node i32)
    (local $identifier_node i32)
    (local $call_node i32)
    (local $can_inline i32)
    (local $generate_result i32)
    (local $found_func i32)

    ;; Initialize AST and codegen
    (call $init_ast)
    (call $init_code_generation)

    ;; Store test strings in memory
    (call $store_test_strings)

    ;; Create a test inline function node called "add"
    (local.set $func_node (call $create_decl_function
      (i32.const 1000) (i32.const 3)  ;; "add" name
      (i32.const 0) (i32.const 0)     ;; no params for this test
      (i32.const 0)                   ;; no return type for this test
      (i32.const 1)))                 ;; inline flag = true

    ;; Register the inline function
    (drop (call $register_inline_functions_from_ast (local.get $func_node)))

    ;; Verify the function was registered
    (local.set $found_func (call $find_inline_function (i32.const 1000) (i32.const 3))) ;; "add"
    (if (i32.eqz (local.get $found_func))
      (then
        ;; Function not registered, test failed
        (global.set $test_passed (i32.const 0))
        (return (i32.const 0))
      )
    )

    ;; Create an identifier node for the function name
    (local.set $identifier_node (call $create_expr_identifier (i32.const 1000) (i32.const 3))) ;; "add"

    ;; Create a function call node
    (local.set $call_node (call $create_expr_traditional_call (local.get $identifier_node) (i32.const 0)))

    ;; Test can_inline_call
    (local.set $can_inline (call $can_inline_call (local.get $call_node)))
    (if (i32.eqz (local.get $can_inline))
      (then
        ;; Function should be inlinable, test failed
        (global.set $test_passed (i32.const 0))
        (return (i32.const 0))
      )
    )

    ;; Test generate_inline_call
    (local.set $generate_result (call $generate_inline_call (local.get $call_node)))
    (if (i32.eqz (local.get $generate_result))
      (then
        ;; Inline generation should succeed, test failed
        (global.set $test_passed (i32.const 0))
        (return (i32.const 0))
      )
    )

    ;; All tests passed
    (global.set $test_passed (i32.const 1))
    (i32.const 1)
  )

  ;; Test non-inline function call
  (func $test_non_inline_call (export "test_non_inline_call") (result i32)
    (local $func_node i32)
    (local $identifier_node i32)
    (local $call_node i32)
    (local $can_inline i32)

    ;; Create a non-inline function node called "sub"
    (local.set $func_node (call $create_decl_function
      (i32.const 1010) (i32.const 3)  ;; "sub" name
      (i32.const 0) (i32.const 0)     ;; no params for this test
      (i32.const 0)                   ;; no return type for this test
      (i32.const 0)))                 ;; inline flag = false

    ;; Register the function (should not be registered as inline)
    (drop (call $register_inline_functions_from_ast (local.get $func_node)))

    ;; Create an identifier node for the function name
    (local.set $identifier_node (call $create_expr_identifier (i32.const 1010) (i32.const 3))) ;; "sub"

    ;; Create a function call node
    (local.set $call_node (call $create_expr_traditional_call (local.get $identifier_node) (i32.const 0)))

    ;; Test can_inline_call - should return 0 (cannot inline)
    (local.set $can_inline (call $can_inline_call (local.get $call_node)))
    (if (local.get $can_inline)
      (then
        ;; Function should NOT be inlinable, test failed
        (return (i32.const 0))
      )
    )

    ;; Test passed
    (i32.const 1)
  )

  ;; Helper function to store test strings in memory
  (func $store_test_strings
    ;; Store "add" at offset 1000
    (i32.store8 offset=1000 (i32.const 0) (i32.const 97))  ;; 'a'
    (i32.store8 offset=1001 (i32.const 0) (i32.const 100)) ;; 'd'
    (i32.store8 offset=1002 (i32.const 0) (i32.const 100)) ;; 'd'

    ;; Store "sub" at offset 1010
    (i32.store8 offset=1010 (i32.const 0) (i32.const 115)) ;; 's'
    (i32.store8 offset=1011 (i32.const 0) (i32.const 117)) ;; 'u'
    (i32.store8 offset=1012 (i32.const 0) (i32.const 98))  ;; 'b'
  )

  ;; Get test result
  (func $get_test_result (export "get_test_result") (result i32)
    (global.get $test_passed)
  )
)
