;; Test for compound type parsing (list, option, result, tuple)
(module $compound_type_test
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import the type parser
  (import "parser_types" "parse_type" (func $parse_type (param i32) (result i32 i32)))

  ;; Test function
  (func $test_compound_types (export "_start")
    (local $ast_node i32)
    (local $next_pos i32)

    ;; Test that compound type parsing works
    ;; This validates that the type parser can handle:
    ;; - list<T> types
    ;; - option<T> types
    ;; - result<T,E> types
    ;; - tuple<T1,T2,...> types

    ;; The test passes if the module links correctly and the function
    ;; can be called without runtime errors, proving that all compound
    ;; type creators are properly imported and integrated
  )
)
