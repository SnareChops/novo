;; Pattern Matching Parser Debug Test
;; Simple test to debug infinite loop issue

(module $pattern_matching_debug_test
  ;; Import AST memory for larger memory space
  (import "ast_memory" "memory" (memory 4))
  (import "novo_lexer" "scan_text" (func $scan_text (param i32 i32) (result i32)))

  ;; Import parser
  (import "parser_patterns" "parse_pattern_matching" (func $parse_pattern_matching (param i32) (result i32 i32)))

  ;; Global memory areas for test strings
  (global $TEST_STRING_AREA i32 (i32.const 4096))

  ;; Write a string to memory
  (func $write_string (param $dest i32) (param $src i32) (param $len i32)
    (local $i i32)
    (local.set $i (i32.const 0))
    (loop $copy_loop
      (if (i32.lt_u (local.get $i) (local.get $len))
        (then
          (i32.store8
            (i32.add (local.get $dest) (local.get $i))
            (i32.load8_u (i32.add (local.get $src) (local.get $i))))
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $copy_loop))))
  )

  ;; Test data: minimal match statement
  (data (i32.const 1000) "match x")

  ;; Test function
  (func $run_debug_test (export "run_debug_test") (result i32)
    (local $result i32)
    (local $node_ptr i32)
    (local $next_pos i32)

    ;; Copy test code to memory
    (call $write_string (global.get $TEST_STRING_AREA) (i32.const 1000) (i32.const 7))

    ;; Scan the text
    (local.set $result (call $scan_text (global.get $TEST_STRING_AREA) (i32.const 7)))
    (if (i32.eqz (local.get $result))
      (then
        ;; Scanning failed
        (return (i32.const 0))
      )
    )

    ;; Parse pattern matching - this might hang
    (local.set $result (call $parse_pattern_matching (i32.const 0)))
    (local.set $node_ptr (i32.shr_u (local.get $result) (i32.const 16)))
    (local.set $next_pos (i32.and (local.get $result) (i32.const 0xFFFF)))

    ;; Return success if we got here without hanging
    (return (i32.const 1))
  )

  ;; Start function for testing
  (func $_start (export "_start")
    (local $result i32)
    (local.set $result (call $run_debug_test))
    (if (local.get $result)
      (then)  ;; Success
      (else unreachable)  ;; Failure
    )
  )
)
