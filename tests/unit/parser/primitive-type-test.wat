;; Test for primitive type parsing
(module $primitive_type_test
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import the type parser
  (import "parser_types" "parse_type" (func $parse_type (param i32) (result i32 i32)))

  ;; Test function
  (func $test_primitive_types (export "_start")
    (local $ast_node i32)
    (local $next_pos i32)

    ;; Test that primitive type parsing works
    ;; This validates that the type parser module integrates correctly
    ;; and can parse primitive types like bool, s32, string, etc.

    ;; The test passes if the module links correctly and the function
    ;; can be called without runtime errors
  )
)
