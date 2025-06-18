;; Simplified Pattern Test
;; Minimal test to isolate the pattern matching memory issue

(module $simplified_pattern_test
  ;; Import lexer memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import only what we need for a basic test
  (import "novo_lexer" "scan_text" (func $scan_text (param i32 i32) (result i32)))

  ;; Test function that just calls lexer, no pattern parsing
  (func $run_simplified_test (export "run_simplified_test") (result i32)
    (local $result i32)

    ;; Test basic lexer functionality

    ;; Set up a simple test string at a safe location
    (i32.store8 (i32.const 100) (i32.const 109))  ;; 'm'
    (i32.store8 (i32.const 101) (i32.const 97))   ;; 'a'
    (i32.store8 (i32.const 102) (i32.const 116))  ;; 't'
    (i32.store8 (i32.const 103) (i32.const 99))   ;; 'c'
    (i32.store8 (i32.const 104) (i32.const 104))  ;; 'h'

    ;; Try to scan the text
    (local.set $result (call $scan_text (i32.const 100) (i32.const 5)))

    ;; Return the scan result
    (local.get $result)
  )

  ;; Start function
  (func $_start (export "_start")
    (local $result i32)
    (local.set $result (call $run_simplified_test))
    (if (local.get $result)
      (then)  ;; Success (non-zero result from scan_text)
      (else unreachable)  ;; Failure
    )
  )
)
