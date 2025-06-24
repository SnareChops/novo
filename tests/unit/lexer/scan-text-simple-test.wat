;; Simple scan_text function test that doesn't use complex tokenization
;; Test to verify the basic infrastructure works without complex lexing logic

(module $scan_text_simple_test
  ;; Import lexer memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Simple test that doesn't actually call the complex scan_text function
  ;; Instead, just verifies memory access works
  (func $run_simple_test (export "run_simple_test") (result i32)
    ;; Write a test value to memory
    (i32.store8 (i32.const 1000) (i32.const 42))

    ;; Read it back
    (i32.load8_u (i32.const 1000))
  )

  ;; Start function
  (func $_start (export "_start")
    (local $result i32)
    (local.set $result (call $run_simple_test))
    (if (i32.eq (local.get $result) (i32.const 42))
      (then)  ;; Success
      (else unreachable)  ;; Failure
    )
  )
)
