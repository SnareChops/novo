;; Super minimal test

(module $super_minimal
  (func $test (export "test") (result i32)
    (i32.const 42)
  )
)
