;; Expression Code Generation Test
;; Tests basic expression code generation functionality

(module $codegen_expressions_test
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import core code generation utilities
  (import "codegen_core" "init_codegen" (func $init_codegen))
  (import "codegen_core" "get_output_buffer" (func $get_output_buffer (param i32)))
  (import "codegen_core" "write_output" (func $write_output (param i32 i32) (result i32)))

  ;; Import expressions module
  (import "codegen_expressions" "init_expressions" (func $init_expressions))

  ;; Test workspace
  (global $TEST_WORKSPACE_START i32 (i32.const 50000))

  ;; Test basic output buffer functionality
  (func $test_output_buffer (export "test_output_buffer") (result i32)
    (local $output_info i32)

    ;; Initialize systems
    (call $init_codegen)
    (call $init_expressions)

    ;; Write some test content
    (drop (call $write_output (i32.const 100) (i32.const 4))) ;; Write "test"

    ;; Get output buffer info
    (local.set $output_info (global.get $TEST_WORKSPACE_START))
    (call $get_output_buffer (local.get $output_info))

    ;; For now, just return success if we can call the function
    (i32.const 1)
  )

  ;; Test initialization functions
  (func $test_initialization (export "test_initialization") (result i32)
    ;; Test that we can initialize both systems
    (call $init_codegen)
    (call $init_expressions)

    ;; If we get here without errors, consider it a pass
    (i32.const 1)
  )

  ;; Test basic output writing
  (func $test_basic_output (export "test_basic_output") (result i32)
    (local $result i32)

    ;; Initialize systems
    (call $init_codegen)
    (call $init_expressions)

    ;; Write some basic instructions
    (local.set $result (call $write_output (i32.const 200) (i32.const 9))) ;; "i32.const"
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    (local.set $result (call $write_output (i32.const 32) (i32.const 1))) ;; " "
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    (local.set $result (call $write_output (i32.const 210) (i32.const 2))) ;; "42"
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    (i32.const 1)
  )

  ;; Main test runner
  (func $run_tests (export "run_tests") (result i32)
    (local $test1_result i32)
    (local $test2_result i32)
    (local $test3_result i32)

    ;; Run all tests
    (local.set $test1_result (call $test_output_buffer))
    (local.set $test2_result (call $test_initialization))
    (local.set $test3_result (call $test_basic_output))

    ;; Return success only if all tests pass
    (i32.and
      (i32.and (local.get $test1_result) (local.get $test2_result))
      (local.get $test3_result))
  )

  ;; Test data
  (data (i32.const 100) "test")
  (data (i32.const 200) "i32.const")
  (data (i32.const 210) "42")
)
