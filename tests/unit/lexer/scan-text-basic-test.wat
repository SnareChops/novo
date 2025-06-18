;; Basic scan_text function test
;; Test the scan_text function in isolation

(module $scan_text_basic_test
  ;; Import lexer memory
  (import "lexer_memory" "memory" (memory 1))
  (import "novo_lexer" "scan_text" (func $scan_text (param i32 i32) (result i32)))

  ;; Test function
  (func $run_scan_text_test (export "run_scan_text_test") (result i32)
    (local $result i32)

    ;; Write a simple test string at position 1000 (input buffer area)
    (i32.store8 (i32.const 1000) (i32.const 105))  ;; 'i'
    (i32.store8 (i32.const 1001) (i32.const 102))  ;; 'f'

    ;; Try to scan just 2 characters
    (local.set $result (call $scan_text (i32.const 1000) (i32.const 2)))

    ;; Return the result (should be 1 for success, 0 for failure)
    (local.get $result)
  )

  ;; Start function
  (func $_start (export "_start")
    (local $result i32)
    (local.set $result (call $run_scan_text_test))
    (if (local.get $result)
      (then)  ;; Success
      (else unreachable)  ;; Failure
    )
  )
)
