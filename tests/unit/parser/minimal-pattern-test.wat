;; Minimal Pattern Test
;; Test just token scanning without parsing

(module $minimal_pattern_test
  ;; Import memory and required functions
  (import "lexer_memory" "memory" (memory 1))
  (import "novo_lexer" "scan_text" (func $scan_text (param i32 i32) (result i32)))

  ;; Global memory areas - use variable data area
  (global $TEST_STRING_AREA i32 (i32.const 35000))

  ;; Test data: just "match"
  (data (i32.const 1000) "match")

  ;; Test function
  (func $run_minimal_test (export "run_minimal_test") (result i32)
    (local $result i32)

    ;; Copy "match" to memory with null terminator
    (i32.store8 (global.get $TEST_STRING_AREA) (i32.const 109))  ;; 'm'
    (i32.store8 (i32.add (global.get $TEST_STRING_AREA) (i32.const 1)) (i32.const 97))   ;; 'a'
    (i32.store8 (i32.add (global.get $TEST_STRING_AREA) (i32.const 2)) (i32.const 116))  ;; 't'
    (i32.store8 (i32.add (global.get $TEST_STRING_AREA) (i32.const 3)) (i32.const 99))   ;; 'c'
    (i32.store8 (i32.add (global.get $TEST_STRING_AREA) (i32.const 4)) (i32.const 104))  ;; 'h'
    (i32.store8 (i32.add (global.get $TEST_STRING_AREA) (i32.const 5)) (i32.const 0))    ;; null terminator

    ;; Try to scan the text - this should work without hanging
    (local.set $result (call $scan_text (global.get $TEST_STRING_AREA) (i32.const 5)))

    ;; Return the scan result (should be > 0 for success)
    (local.get $result)
  )

  ;; Start function
  (func $_start (export "_start")
    (local $result i32)
    (local.set $result (call $run_minimal_test))
    (if (local.get $result)
      (then)  ;; Success
      (else unreachable)  ;; Failure
    )
  )
)
