;; Basic Parser Test
;; Simple test to verify parser modules compile and work together

(module $parser_basic_test
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import main parser
  (import "parser_main" "parse" (func $parse (param i32) (result i32 i32)))

  ;; Import AST functions for verification
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))

  ;; Simple test function
  (func $test_basic_parse (export "test_basic_parse") (result i32)
    (local $ast_node i32)
    (local $next_pos i32)

    ;; Try to parse starting at position 0
    (call $parse (i32.const 0))
    (local.set $next_pos) ;; Second return value
    (local.set $ast_node) ;; First return value

    ;; Return 1 if we got a valid AST node, 0 otherwise
    (if (result i32) (local.get $ast_node)
      (then (i32.const 1))
      (else (i32.const 0))
    )
  )
)
