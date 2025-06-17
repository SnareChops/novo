;; Function Declaration Parser Extended Test
;; Tests more complex function declaration scenarios

(module $function_declaration_extended_test
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import parser function
  (import "parser_functions" "parse_function_declaration" (func $parse_function_declaration (param i32) (result i32 i32)))

  ;; Import AST utilities
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "ast_node_types" "DECL_FUNCTION" (global $DECL_FUNCTION i32))

  ;; Helper function to store string in memory at position 0
  (func $store_test_input (param $str_ptr i32) (param $str_len i32)
    (local $i i32)

    (local.set $i (i32.const 0))
    (loop $copy_loop
      (if (i32.lt_u (local.get $i) (local.get $str_len))
        (then
          (i32.store8
            (local.get $i)
            (i32.load8_u (i32.add (local.get $str_ptr) (local.get $i))))
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $copy_loop)
        )
      )
    )
  )

  ;; Test data
  (data (i32.const 1000) "func hello-world {\n}\n")
  (data (i32.const 1100) "func add x:u32 y:u32 -> u32 {\n}\n")
  (data (i32.const 1200) "func fibonacci n:u64 -> u64 {\n  if n <= 1 {\n    return n\n  }\n  return fibonacci(n-1) + fibonacci(n-2)\n}\n")
  (data (i32.const 1400) "inline func square x:f32 -> f32 {\n  return x * x\n}\n")
  (data (i32.const 1500) "func no-params {\n  log(\"hello\")\n}\n")

  ;; Run all tests
  (func $run_tests (export "run_tests") (result i32)
    (local $result i32)

    ;; Test 1: Function with kebab-case name
    (local.set $result (call $test_kebab_case_name))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 2: Function with parameters and return type
    (local.set $result (call $test_params_and_return))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 3: Complex function with nested braces
    (local.set $result (call $test_complex_function))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 4: Inline function
    (local.set $result (call $test_inline_function))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 5: Function with no parameters
    (local.set $result (call $test_no_params))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; All tests passed
    (return (i32.const 1))
  )

  ;; Test function with kebab-case name
  (func $test_kebab_case_name (result i32)
    (local $ast_node i32)
    (local $next_pos i32)
    (local $node_type i32)

    ;; Set up test input
    (call $store_test_input (i32.const 1000) (i32.const 22)) ;; "func hello-world {\n}\n"

    ;; Parse function declaration
    (local.set $ast_node (call $parse_function_declaration (i32.const 0)))
    (local.set $next_pos (i32.shr_u (local.get $ast_node) (i32.const 16)))
    (local.set $ast_node (i32.and (local.get $ast_node) (i32.const 0xFFFF)))

    ;; Check if parsing succeeded
    (if (i32.eqz (local.get $ast_node))
      (then (return (i32.const 0)))
    )

    ;; Check node type
    (local.set $node_type (call $get_node_type (local.get $ast_node)))
    (if (i32.ne (local.get $node_type) (global.get $DECL_FUNCTION))
      (then (return (i32.const 0)))
    )

    (return (i32.const 1))
  )

  ;; Test function with parameters and return type
  (func $test_params_and_return (result i32)
    (local $ast_node i32)
    (local $next_pos i32)
    (local $node_type i32)

    ;; Set up test input
    (call $store_test_input (i32.const 1100) (i32.const 28)) ;; "func add x:u32 y:u32 -> u32 {\n}\n"

    ;; Parse function declaration
    (local.set $ast_node (call $parse_function_declaration (i32.const 0)))
    (local.set $next_pos (i32.shr_u (local.get $ast_node) (i32.const 16)))
    (local.set $ast_node (i32.and (local.get $ast_node) (i32.const 0xFFFF)))

    ;; Check if parsing succeeded
    (if (i32.eqz (local.get $ast_node))
      (then (return (i32.const 0)))
    )

    ;; Check node type
    (local.set $node_type (call $get_node_type (local.get $ast_node)))
    (if (i32.ne (local.get $node_type) (global.get $DECL_FUNCTION))
      (then (return (i32.const 0)))
    )

    (return (i32.const 1))
  )

  ;; Test complex function with nested braces
  (func $test_complex_function (result i32)
    (local $ast_node i32)
    (local $next_pos i32)
    (local $node_type i32)

    ;; Set up test input - fibonacci function with nested blocks
    (call $store_test_input (i32.const 1200) (i32.const 114))

    ;; Parse function declaration
    (local.set $ast_node (call $parse_function_declaration (i32.const 0)))
    (local.set $next_pos (i32.shr_u (local.get $ast_node) (i32.const 16)))
    (local.set $ast_node (i32.and (local.get $ast_node) (i32.const 0xFFFF)))

    ;; Check if parsing succeeded
    (if (i32.eqz (local.get $ast_node))
      (then (return (i32.const 0)))
    )

    ;; Check node type
    (local.set $node_type (call $get_node_type (local.get $ast_node)))
    (if (i32.ne (local.get $node_type) (global.get $DECL_FUNCTION))
      (then (return (i32.const 0)))
    )

    (return (i32.const 1))
  )

  ;; Test inline function
  (func $test_inline_function (result i32)
    (local $ast_node i32)
    (local $next_pos i32)
    (local $node_type i32)

    ;; Set up test input
    (call $store_test_input (i32.const 1400) (i32.const 50)) ;; inline func square

    ;; Parse function declaration
    (local.set $ast_node (call $parse_function_declaration (i32.const 0)))
    (local.set $next_pos (i32.shr_u (local.get $ast_node) (i32.const 16)))
    (local.set $ast_node (i32.and (local.get $ast_node) (i32.const 0xFFFF)))

    ;; Check if parsing succeeded
    (if (i32.eqz (local.get $ast_node))
      (then (return (i32.const 0)))
    )

    ;; Check node type
    (local.set $node_type (call $get_node_type (local.get $ast_node)))
    (if (i32.ne (local.get $node_type) (global.get $DECL_FUNCTION))
      (then (return (i32.const 0)))
    )

    (return (i32.const 1))
  )

  ;; Test function with no parameters
  (func $test_no_params (result i32)
    (local $ast_node i32)
    (local $next_pos i32)
    (local $node_type i32)

    ;; Set up test input
    (call $store_test_input (i32.const 1500) (i32.const 31)) ;; func no-params

    ;; Parse function declaration
    (local.set $ast_node (call $parse_function_declaration (i32.const 0)))
    (local.set $next_pos (i32.shr_u (local.get $ast_node) (i32.const 16)))
    (local.set $ast_node (i32.and (local.get $ast_node) (i32.const 0xFFFF)))

    ;; Check if parsing succeeded
    (if (i32.eqz (local.get $ast_node))
      (then (return (i32.const 0)))
    )

    ;; Check node type
    (local.set $node_type (call $get_node_type (local.get $ast_node)))
    (if (i32.ne (local.get $node_type) (global.get $DECL_FUNCTION))
      (then (return (i32.const 0)))
    )

    (return (i32.const 1))
  )
)
