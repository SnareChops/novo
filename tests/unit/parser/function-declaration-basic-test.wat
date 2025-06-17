;; Function Declaration Parser Basic Test
;; Tests parsing of simple function declarations

(module $function_declaration_basic_test
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

  ;; Test data: simple function declaration "func hello {\n}\n"
  (data (i32.const 1000) "func hello {\n}\n")

  ;; Test data: function with parameters "func add a:u32 b:u32 -> u32 {\n}\n"
  (data (i32.const 1100) "func add a:u32 b:u32 -> u32 {\n}\n")

  ;; Test data: inline function "inline func square x:u32 -> u32 {\n}\n"
  (data (i32.const 1200) "inline func square x:u32 -> u32 {\n}\n")

  ;; Run all tests
  (func $run_tests (export "run_tests") (result i32)
    (local $result i32)

    ;; Test 1: Simple function declaration
    (local.set $result (call $test_simple_function))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 2: Function with parameters
    (local.set $result (call $test_function_with_params))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 3: Inline function
    (local.set $result (call $test_inline_function))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; All tests passed
    (return (i32.const 1))
  )

  ;; Test simple function declaration: func hello { }
  (func $test_simple_function (result i32)
    (local $ast_node i32)
    (local $next_pos i32)
    (local $node_type i32)

    ;; Set up test input in memory
    (call $store_test_input (i32.const 1000) (i32.const 14)) ;; "func hello {\n}\n"

    ;; Parse function declaration
    (local.set $ast_node (call $parse_function_declaration (i32.const 0)))
    (local.set $next_pos (i32.shr_u (local.get $ast_node) (i32.const 16)))
    (local.set $ast_node (i32.and (local.get $ast_node) (i32.const 0xFFFF)))

    ;; Check if parsing succeeded
    (if (i32.eqz (local.get $ast_node))
      (then
        (return (i32.const 0)) ;; Test failed
      )
    )

    ;; Check node type
    (local.set $node_type (call $get_node_type (local.get $ast_node)))
    (if (i32.ne (local.get $node_type) (global.get $DECL_FUNCTION))
      (then
        (return (i32.const 0)) ;; Test failed
      )
    )

    ;; Test passed
    (return (i32.const 1))
  )

  ;; Test function with parameters: func add a:u32 b:u32 -> u32 { }
  (func $test_function_with_params (result i32)
    (local $ast_node i32)
    (local $next_pos i32)
    (local $node_type i32)

    ;; Set up test input in memory
    (call $store_test_input (i32.const 1100) (i32.const 29)) ;; "func add a:u32 b:u32 -> u32 {\n}\n"

    ;; Parse function declaration
    (local.set $ast_node (call $parse_function_declaration (i32.const 0)))
    (local.set $next_pos (i32.shr_u (local.get $ast_node) (i32.const 16)))
    (local.set $ast_node (i32.and (local.get $ast_node) (i32.const 0xFFFF)))

    ;; Check if parsing succeeded
    (if (i32.eqz (local.get $ast_node))
      (then
        (return (i32.const 0)) ;; Test failed
      )
    )

    ;; Check node type
    (local.set $node_type (call $get_node_type (local.get $ast_node)))
    (if (i32.ne (local.get $node_type) (global.get $DECL_FUNCTION))
      (then
        (return (i32.const 0)) ;; Test failed
      )
    )

    ;; Test passed
    (return (i32.const 1))
  )

  ;; Test inline function: inline func square x:u32 -> u32 { }
  (func $test_inline_function (result i32)
    (local $ast_node i32)
    (local $next_pos i32)
    (local $node_type i32)

    ;; Set up test input in memory
    (call $store_test_input (i32.const 1200) (i32.const 35)) ;; "inline func square x:u32 -> u32 {\n}\n"

    ;; Parse function declaration
    (local.set $ast_node (call $parse_function_declaration (i32.const 0)))
    (local.set $next_pos (i32.shr_u (local.get $ast_node) (i32.const 16)))
    (local.set $ast_node (i32.and (local.get $ast_node) (i32.const 0xFFFF)))

    ;; Check if parsing succeeded
    (if (i32.eqz (local.get $ast_node))
      (then
        (return (i32.const 0)) ;; Test failed
      )
    )

    ;; Check node type
    (local.set $node_type (call $get_node_type (local.get $ast_node)))
    (if (i32.ne (local.get $node_type) (global.get $DECL_FUNCTION))
      (then
        (return (i32.const 0)) ;; Test failed
      )
    )

    ;; Test passed
    (return (i32.const 1))
  )
)
