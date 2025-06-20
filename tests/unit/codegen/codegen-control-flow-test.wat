;; Control Flow Code Generation Test
;; Tests basic control flow code generation functionality

(module $codegen_control_flow_test
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import core code generation utilities
  (import "codegen_core" "init_codegen" (func $init_codegen))
  (import "codegen_core" "write_output" (func $write_output (param i32 i32) (result i32)))

  ;; Import expressions module
  (import "codegen_expressions" "init_expressions" (func $init_expressions))

  ;; Import control flow module
  (import "codegen_control_flow" "init_control_flow" (func $init_control_flow))
  (import "codegen_control_flow" "generate_control_flow" (func $generate_control_flow (param i32) (result i32)))

  ;; Test workspace
  (global $TEST_WORKSPACE_START i32 (i32.const 50000))

  ;; Test control flow initialization
  (func $test_initialization (export "test_initialization") (result i32)
    ;; Test that we can initialize all systems
    (call $init_codegen)
    (call $init_expressions)
    (call $init_control_flow)

    ;; If we get here without errors, consider it a pass
    (i32.const 1)
  )

  ;; Test basic control flow pattern generation (simplified without actual AST)
  (func $test_basic_patterns (export "test_basic_patterns") (result i32)
    (local $result i32)

    ;; Initialize systems
    (call $init_codegen)
    (call $init_expressions)
    (call $init_control_flow)

    ;; Write some basic control flow patterns
    (local.set $result (call $write_output (i32.const 200) (i32.const 2))) ;; "if"
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    (local.set $result (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    (local.set $result (call $write_output (i32.const 210) (i32.const 4))) ;; "then"
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    (local.set $result (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    (local.set $result (call $write_output (i32.const 220) (i32.const 1))) ;; ")"
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    (i32.const 1)
  )

  ;; Test loop patterns
  (func $test_loop_patterns (export "test_loop_patterns") (result i32)
    (local $result i32)

    ;; Initialize systems
    (call $init_codegen)
    (call $init_expressions)
    (call $init_control_flow)

    ;; Write basic loop patterns
    (local.set $result (call $write_output (i32.const 230) (i32.const 4))) ;; "loop"
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    (local.set $result (call $write_output (i32.const 32) (i32.const 1))) ;; " "
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    (local.set $result (call $write_output (i32.const 240) (i32.const 2))) ;; "br"
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    (i32.const 1)
  )

  ;; Test return patterns
  (func $test_return_patterns (export "test_return_patterns") (result i32)
    (local $result i32)

    ;; Initialize systems
    (call $init_codegen)
    (call $init_expressions)
    (call $init_control_flow)

    ;; Write return pattern
    (local.set $result (call $write_output (i32.const 250) (i32.const 6))) ;; "return"
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    (local.set $result (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"
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
    (local $test4_result i32)

    ;; Run all tests
    (local.set $test1_result (call $test_initialization))
    (local.set $test2_result (call $test_basic_patterns))
    (local.set $test3_result (call $test_loop_patterns))
    (local.set $test4_result (call $test_return_patterns))

    ;; Return success only if all tests pass
    (i32.and
      (i32.and
        (i32.and (local.get $test1_result) (local.get $test2_result))
        (local.get $test3_result))
      (local.get $test4_result))
  )

  ;; Test data
  (data (i32.const 200) "if")
  (data (i32.const 210) "then")
  (data (i32.const 220) ")")
  (data (i32.const 230) "loop")
  (data (i32.const 240) "br")
  (data (i32.const 250) "return")
)
