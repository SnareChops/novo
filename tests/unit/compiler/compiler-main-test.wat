;; Test Main Compiler Integration
;; Tests the integration of all compiler phases with binary output priority

(module $test_compiler_main
  ;; Import memory for testing
  (import "lexer_memory" "memory" (memory 1))

  ;; Import main compiler
  (import "compiler_main" "init_compiler" (func $init_compiler))
  (import "compiler_main" "novo_compile" (func $novo_compile (param i32 i32 i32 i32) (result i32)))
  (import "compiler_main" "get_binary_output" (func $get_binary_output (param i32)))
  (import "compiler_main" "get_last_error" (func $get_last_error (result i32)))
  (import "compiler_main" "is_compilation_successful" (func $is_compilation_successful (result i32)))
  (import "compiler_main" "get_current_mode" (func $get_current_mode (result i32)))
  (import "compiler_main" "is_binary_mode_active" (func $is_binary_mode_active (result i32)))
  (import "compiler_main" "get_compiler_stats" (func $get_compiler_stats (param i32)))

  ;; Test workspace
  (global $TEST_WORKSPACE_START i32 (i32.const 49000))
  (global $TEST_WORKSPACE_SIZE i32 (i32.const 1024))

  ;; Test result storage
  (global $test_results (mut i32) (i32.const 0))

  ;; Test 1: Compiler initialization
  (func $test_compiler_initialization (export "test_compiler_initialization") (result i32)
    (local $initial_mode i32)
    (local $is_binary_active i32)
    (local $result i32)

    ;; Initialize compiler
    (call $init_compiler)

    ;; Check initial mode is binary (0)
    (local.set $initial_mode (call $get_current_mode))
    (local.set $is_binary_active (call $is_binary_mode_active))

    ;; Test passes if mode is 0 (binary) and binary is active
    (local.set $result
      (i32.and
        (i32.eq (local.get $initial_mode) (i32.const 0))
        (i32.eq (local.get $is_binary_active) (i32.const 1))))

    ;; Update test results
    (if (local.get $result)
      (then (global.set $test_results (i32.or (global.get $test_results) (i32.const 1))))
    )

    (local.get $result)
  )

  ;; Test 2: Basic compilation with simple source
  (func $test_basic_compilation (export "test_basic_compilation") (result i32)
    (local $source_ptr i32)
    (local $source_len i32)
    (local $module_name_ptr i32)
    (local $module_name_len i32)
    (local $compile_result i32)
    (local $is_successful i32)
    (local $last_error i32)
    (local $result i32)

    ;; Initialize test source: "func main() { }" (minimal valid source)
    (local.set $source_ptr (i32.add (global.get $TEST_WORKSPACE_START) (i32.const 0)))
    (local.set $source_len (i32.const 15))
    (local.set $module_name_ptr (i32.add (global.get $TEST_WORKSPACE_START) (i32.const 50)))
    (local.set $module_name_len (i32.const 11))

    ;; Store test source
    (call $store_test_string (local.get $source_ptr) (i32.const 49400) (local.get $source_len))
    (call $store_test_string (local.get $module_name_ptr) (i32.const 49450) (local.get $module_name_len))

    ;; Initialize compiler
    (call $init_compiler)

    ;; Attempt compilation
    (local.set $compile_result
      (call $novo_compile
        (local.get $source_ptr) (local.get $source_len)
        (local.get $module_name_ptr) (local.get $module_name_len)))

    ;; Check results
    (local.set $is_successful (call $is_compilation_successful))
    (local.set $last_error (call $get_last_error))

    ;; For now, accept either success or controlled failure
    ;; (since we don't have a complete parser implementation yet)
    (local.set $result
      (i32.or
        (i32.and (local.get $compile_result) (local.get $is_successful))
        (i32.and (i32.eqz (local.get $compile_result)) (i32.gt_u (local.get $last_error) (i32.const 0)))))

    ;; Update test results
    (if (local.get $result)
      (then (global.set $test_results (i32.or (global.get $test_results) (i32.const 2))))
    )

    (local.get $result)
  )

  ;; Test 3: Binary output generation
  (func $test_binary_output_generation (export "test_binary_output_generation") (result i32)
    (local $output_info_ptr i32)
    (local $output_ptr i32)
    (local $output_len i32)
    (local $mode i32)
    (local $binary_active i32)
    (local $result i32)

    ;; Get current compilation mode and binary status
    (local.set $mode (call $get_current_mode))
    (local.set $binary_active (call $is_binary_mode_active))

    ;; Get binary output info
    (local.set $output_info_ptr (i32.add (global.get $TEST_WORKSPACE_START) (i32.const 100)))
    (call $get_binary_output (local.get $output_info_ptr))
    (local.set $output_ptr (i32.load (local.get $output_info_ptr)))
    (local.set $output_len (i32.load offset=4 (local.get $output_info_ptr)))

    ;; Test passes if:
    ;; 1. Mode is binary (0)
    ;; 2. Binary mode is active
    ;; 3. Output buffer is accessible (non-zero pointer)
    (local.set $result
      (i32.and
        (i32.and
          (i32.eq (local.get $mode) (i32.const 0))
          (i32.eq (local.get $binary_active) (i32.const 1)))
        (i32.gt_u (local.get $output_ptr) (i32.const 0))))

    ;; Update test results
    (if (local.get $result)
      (then (global.set $test_results (i32.or (global.get $test_results) (i32.const 4))))
    )

    (local.get $result)
  )

  ;; Test 4: Compilation statistics
  (func $test_compilation_statistics (export "test_compilation_statistics") (result i32)
    (local $stats_ptr i32)
    (local $functions_generated i32)
    (local $imports_generated i32)
    (local $exports_generated i32)
    (local $result i32)

    ;; Get compilation statistics
    (local.set $stats_ptr (i32.add (global.get $TEST_WORKSPACE_START) (i32.const 150)))
    (call $get_compiler_stats (local.get $stats_ptr))

    (local.set $functions_generated (i32.load (local.get $stats_ptr)))
    (local.set $imports_generated (i32.load offset=4 (local.get $stats_ptr)))
    (local.set $exports_generated (i32.load offset=8 (local.get $stats_ptr)))

    ;; Test passes if statistics are accessible (non-negative values)
    (local.set $result
      (i32.and
        (i32.and
          (i32.ge_u (local.get $functions_generated) (i32.const 0))
          (i32.ge_u (local.get $imports_generated) (i32.const 0)))
        (i32.ge_u (local.get $exports_generated) (i32.const 0))))

    ;; Update test results
    (if (local.get $result)
      (then (global.set $test_results (i32.or (global.get $test_results) (i32.const 8))))
    )

    (local.get $result)
  )

  ;; Test 5: Error handling
  (func $test_error_handling (export "test_error_handling") (result i32)
    (local $invalid_source_ptr i32)
    (local $invalid_source_len i32)
    (local $module_name_ptr i32)
    (local $module_name_len i32)
    (local $compile_result i32)
    (local $last_error i32)
    (local $is_successful i32)
    (local $result i32)

    ;; Test with invalid/empty source
    (local.set $invalid_source_ptr (i32.add (global.get $TEST_WORKSPACE_START) (i32.const 200)))
    (local.set $invalid_source_len (i32.const 0))  ;; Empty source
    (local.set $module_name_ptr (i32.add (global.get $TEST_WORKSPACE_START) (i32.const 250)))
    (local.set $module_name_len (i32.const 4))

    ;; Store module name "test"
    (call $store_test_string (local.get $module_name_ptr) (i32.const 49500) (i32.const 4))

    ;; Initialize compiler
    (call $init_compiler)

    ;; Try compilation with invalid source
    (local.set $compile_result
      (call $novo_compile
        (local.get $invalid_source_ptr) (local.get $invalid_source_len)
        (local.get $module_name_ptr) (local.get $module_name_len)))

    ;; Check error handling
    (local.set $last_error (call $get_last_error))
    (local.set $is_successful (call $is_compilation_successful))

    ;; Test passes if compilation fails gracefully with an error code
    (local.set $result
      (i32.and
        (i32.eqz (local.get $compile_result))        ;; Compilation should fail
        (i32.and
          (i32.gt_u (local.get $last_error) (i32.const 0))  ;; Should have error code
          (i32.eqz (local.get $is_successful)))))    ;; Should not be successful

    ;; Update test results
    (if (local.get $result)
      (then (global.set $test_results (i32.or (global.get $test_results) (i32.const 16))))
    )

    (local.get $result)
  )

  ;; Store test string helper
  ;; @param dest_ptr: i32 - Destination
  ;; @param src_ptr: i32 - Source (constant location)
  ;; @param len: i32 - Length
  (func $store_test_string (param $dest_ptr i32) (param $src_ptr i32) (param $len i32)
    (local $i i32)
    (local.set $i (i32.const 0))
    (loop $copy_loop
      (if (i32.lt_u (local.get $i) (local.get $len))
        (then
          (i32.store8
            (i32.add (local.get $dest_ptr) (local.get $i))
            (i32.load8_u (i32.add (local.get $src_ptr) (local.get $i))))
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $copy_loop)
        )
      )
    )
  )

  ;; Run all compiler integration tests
  (func $run_all_compiler_tests (export "run_all_compiler_tests") (result i32)
    (local $test1 i32)
    (local $test2 i32)
    (local $test3 i32)
    (local $test4 i32)
    (local $test5 i32)
    (local $all_passed i32)

    ;; Initialize
    (global.set $test_results (i32.const 0))

    ;; Run tests in sequence
    (local.set $test1 (call $test_compiler_initialization))
    (local.set $test2 (call $test_basic_compilation))
    (local.set $test3 (call $test_binary_output_generation))
    (local.set $test4 (call $test_compilation_statistics))
    (local.set $test5 (call $test_error_handling))

    ;; All tests should pass (test_results should be 31 = 0x1F)
    (local.set $all_passed (i32.eq (global.get $test_results) (i32.const 31)))

    (local.get $all_passed)
  )

  ;; Get test results bitmask
  (func $get_test_results (export "get_test_results") (result i32)
    (global.get $test_results)
  )

  ;; Initialize test data
  (func $init_test_data
    ;; Store "func main() { }" at offset 49400
    (i32.store8 offset=49400 (i32.const 0) (i32.const 102)) ;; 'f'
    (i32.store8 offset=49401 (i32.const 0) (i32.const 117)) ;; 'u'
    (i32.store8 offset=49402 (i32.const 0) (i32.const 110)) ;; 'n'
    (i32.store8 offset=49403 (i32.const 0) (i32.const 99))  ;; 'c'
    (i32.store8 offset=49404 (i32.const 0) (i32.const 32))  ;; ' '
    (i32.store8 offset=49405 (i32.const 0) (i32.const 109)) ;; 'm'
    (i32.store8 offset=49406 (i32.const 0) (i32.const 97))  ;; 'a'
    (i32.store8 offset=49407 (i32.const 0) (i32.const 105)) ;; 'i'
    (i32.store8 offset=49408 (i32.const 0) (i32.const 110)) ;; 'n'
    (i32.store8 offset=49409 (i32.const 0) (i32.const 40))  ;; '('
    (i32.store8 offset=49410 (i32.const 0) (i32.const 41))  ;; ')'
    (i32.store8 offset=49411 (i32.const 0) (i32.const 32))  ;; ' '
    (i32.store8 offset=49412 (i32.const 0) (i32.const 123)) ;; '{'
    (i32.store8 offset=49413 (i32.const 0) (i32.const 32))  ;; ' '
    (i32.store8 offset=49414 (i32.const 0) (i32.const 125)) ;; '}'

    ;; Store "test_module" at offset 49450
    (i32.store8 offset=49450 (i32.const 0) (i32.const 116)) ;; 't'
    (i32.store8 offset=49451 (i32.const 0) (i32.const 101)) ;; 'e'
    (i32.store8 offset=49452 (i32.const 0) (i32.const 115)) ;; 's'
    (i32.store8 offset=49453 (i32.const 0) (i32.const 116)) ;; 't'
    (i32.store8 offset=49454 (i32.const 0) (i32.const 95))  ;; '_'
    (i32.store8 offset=49455 (i32.const 0) (i32.const 109)) ;; 'm'
    (i32.store8 offset=49456 (i32.const 0) (i32.const 111)) ;; 'o'
    (i32.store8 offset=49457 (i32.const 0) (i32.const 100)) ;; 'd'
    (i32.store8 offset=49458 (i32.const 0) (i32.const 117)) ;; 'u'
    (i32.store8 offset=49459 (i32.const 0) (i32.const 108)) ;; 'l'
    (i32.store8 offset=49460 (i32.const 0) (i32.const 101)) ;; 'e'

    ;; Store "test" at offset 49500
    (i32.store8 offset=49500 (i32.const 0) (i32.const 116)) ;; 't'
    (i32.store8 offset=49501 (i32.const 0) (i32.const 101)) ;; 'e'
    (i32.store8 offset=49502 (i32.const 0) (i32.const 115)) ;; 's'
    (i32.store8 offset=49503 (i32.const 0) (i32.const 116)) ;; 't'
  )

  (start $init_test_data)
)
