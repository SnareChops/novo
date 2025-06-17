;; Minimal test for control flow function signatures

(module $test_signatures
  (import "lexer_memory" "memory" (memory 1))

  ;; Simple test function that returns i32
  (func $test_simple (export "test_simple") (param $pos i32) (result i32)
    (i32.const 42)
  )
)
