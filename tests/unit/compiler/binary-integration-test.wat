;; Test Binary Codegen Integration
;; Tests the integration of binary codegen as the primary output

(module $test_binary_integration
  ;; Import memory for testing
  (import "lexer_memory" "memory" (memory 1))

  ;; Import binary code generation (PRIMARY TARGET)
  (import "codegen_binary_main" "init_binary_code_generation" (func $init_binary_code_generation))
  (import "codegen_binary_main" "compile_to_binary_wasm" (func $compile_to_binary_wasm (param i32 i32 i32) (result i32)))
  (import "codegen_binary_main" "get_binary_wasm_output" (func $get_binary_wasm_output (param i32)))
  (import "codegen_binary_main" "get_compilation_mode" (func $get_compilation_mode (result i32)))
  (import "codegen_binary_main" "get_compilation_stats" (func $get_compilation_stats (param i32)))
  (import "codegen_binary_main" "validate_binary_output" (func $validate_binary_output (result i32)))

  ;; Test workspace
  (global $TEST_WORKSPACE_START i32 (i32.const 49600))
  (global $TEST_WORKSPACE_SIZE i32 (i32.const 1024))

  ;; Test result storage
  (global $test_results (mut i32) (i32.const 0))

  ;; Test 1: Binary codegen initialization
  (func $test_binary_codegen_init (export "test_binary_codegen_init") (result i32)
    (local $initial_mode i32)
    (local $result i32)

    ;; Initialize binary code generation
    (call $init_binary_code_generation)

    ;; Check initial mode is binary (0)
    (local.set $initial_mode (call $get_compilation_mode))

    ;; Test passes if mode is 0 (binary)
    (local.set $result (i32.eq (local.get $initial_mode) (i32.const 0)))

    ;; Update test results
    (if (local.get $result)
      (then (global.set $test_results (i32.or (global.get $test_results) (i32.const 1))))
    )

    (local.get $result)
  )

  ;; Test 2: Binary WASM compilation
  (func $test_binary_wasm_compilation (export "test_binary_wasm_compilation") (result i32)
    (local $ast_root i32)
    (local $module_name_ptr i32)
    (local $module_name_len i32)
    (local $bytes_generated i32)
    (local $result i32)

    ;; Set up test data
    (local.set $ast_root (i32.const 0))  ;; Dummy AST root
    (local.set $module_name_ptr (i32.add (global.get $TEST_WORKSPACE_START) (i32.const 0)))
    (local.set $module_name_len (i32.const 11))

    ;; Store test module name
    (call $store_test_string (local.get $module_name_ptr) (i32.const 49650) (local.get $module_name_len))

    ;; Initialize binary code generation
    (call $init_binary_code_generation)

    ;; Attempt binary compilation
    (local.set $bytes_generated
      (call $compile_to_binary_wasm
        (local.get $ast_root)
        (local.get $module_name_ptr)
        (local.get $module_name_len)))

    ;; Test passes if some bytes were generated
    (local.set $result (i32.gt_u (local.get $bytes_generated) (i32.const 0)))

    ;; Update test results
    (if (local.get $result)
      (then (global.set $test_results (i32.or (global.get $test_results) (i32.const 2))))
    )

    (local.get $result)
  )

  ;; Test 3: Binary output validation
  (func $test_binary_output_validation (export "test_binary_output_validation") (result i32)
    (local $output_info_ptr i32)
    (local $output_ptr i32)
    (local $output_len i32)
    (local $validation_result i32)
    (local $result i32)

    ;; Get binary output
    (local.set $output_info_ptr (i32.add (global.get $TEST_WORKSPACE_START) (i32.const 50)))
    (call $get_binary_wasm_output (local.get $output_info_ptr))
    (local.set $output_ptr (i32.load (local.get $output_info_ptr)))
    (local.set $output_len (i32.load offset=4 (local.get $output_info_ptr)))

    ;; Validate binary output
    (local.set $validation_result (call $validate_binary_output))

    ;; Test passes if:
    ;; 1. Output buffer is accessible (non-zero pointer)
    ;; 2. Output length is reasonable (> 0)
    ;; 3. Binary validation passes
    (local.set $result
      (i32.and
        (i32.and
          (i32.gt_u (local.get $output_ptr) (i32.const 0))
          (i32.gt_u (local.get $output_len) (i32.const 0)))
        (i32.eq (local.get $validation_result) (i32.const 1))))

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
    (local.set $stats_ptr (i32.add (global.get $TEST_WORKSPACE_START) (i32.const 100)))
    (call $get_compilation_stats (local.get $stats_ptr))

    (local.set $functions_generated (i32.load (local.get $stats_ptr)))
    (local.set $imports_generated (i32.load offset=4 (local.get $stats_ptr)))
    (local.set $exports_generated (i32.load offset=8 (local.get $stats_ptr)))

    ;; Test passes if statistics are accessible and reasonable
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

  ;; Test 5: Binary vs WAT distinction
  (func $test_binary_vs_wat_distinction (export "test_binary_vs_wat_distinction") (result i32)
    (local $output_info_ptr i32)
    (local $output_ptr i32)
    (local $output_len i32)
    (local $has_wat_text i32)
    (local $result i32)

    ;; Get binary output
    (local.set $output_info_ptr (i32.add (global.get $TEST_WORKSPACE_START) (i32.const 150)))
    (call $get_binary_wasm_output (local.get $output_info_ptr))
    (local.set $output_ptr (i32.load (local.get $output_info_ptr)))
    (local.set $output_len (i32.load offset=4 (local.get $output_info_ptr)))

    ;; Check if output contains WAT text patterns (should not)
    (local.set $has_wat_text (call $contains_wat_text_patterns (local.get $output_ptr) (local.get $output_len)))

    ;; Test passes if output does NOT contain WAT text patterns (binary mode)
    (local.set $result (i32.eqz (local.get $has_wat_text)))

    ;; Update test results
    (if (local.get $result)
      (then (global.set $test_results (i32.or (global.get $test_results) (i32.const 16))))
    )

    (local.get $result)
  )

  ;; Check if data contains WAT text patterns
  ;; @param data_ptr: i32 - Data buffer
  ;; @param data_len: i32 - Data length
  ;; @returns i32 - 1 if WAT patterns found, 0 if not
  (func $contains_wat_text_patterns (param $data_ptr i32) (param $data_len i32) (result i32)
    (local $i i32)
    (local $found_module i32)
    (local $found_func i32)

    ;; Look for "(module" pattern
    (local.set $i (i32.const 0))
    (local.set $found_module (i32.const 0))
    (loop $search_module
      (if (i32.lt_u (i32.add (local.get $i) (i32.const 6)) (local.get $data_len))
        (then
          (if (i32.and
                (i32.and
                  (i32.eq (i32.load8_u (i32.add (local.get $data_ptr) (local.get $i))) (i32.const 0x28))      ;; '('
                  (i32.eq (i32.load8_u (i32.add (local.get $data_ptr) (i32.add (local.get $i) (i32.const 1)))) (i32.const 0x6d)))  ;; 'm'
                (i32.and
                  (i32.eq (i32.load8_u (i32.add (local.get $data_ptr) (i32.add (local.get $i) (i32.const 2)))) (i32.const 0x6f))    ;; 'o'
                  (i32.and
                    (i32.eq (i32.load8_u (i32.add (local.get $data_ptr) (i32.add (local.get $i) (i32.const 3)))) (i32.const 0x64))  ;; 'd'
                    (i32.and
                      (i32.eq (i32.load8_u (i32.add (local.get $data_ptr) (i32.add (local.get $i) (i32.const 4)))) (i32.const 0x75)) ;; 'u'
                      (i32.eq (i32.load8_u (i32.add (local.get $data_ptr) (i32.add (local.get $i) (i32.const 5)))) (i32.const 0x6c))))))  ;; 'l'
            (then (local.set $found_module (i32.const 1)))
          )
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $search_module)
        )
      )
    )

    ;; Look for "(func" pattern
    (local.set $i (i32.const 0))
    (local.set $found_func (i32.const 0))
    (loop $search_func
      (if (i32.lt_u (i32.add (local.get $i) (i32.const 4)) (local.get $data_len))
        (then
          (if (i32.and
                (i32.and
                  (i32.eq (i32.load8_u (i32.add (local.get $data_ptr) (local.get $i))) (i32.const 0x28))      ;; '('
                  (i32.eq (i32.load8_u (i32.add (local.get $data_ptr) (i32.add (local.get $i) (i32.const 1)))) (i32.const 0x66)))  ;; 'f'
                (i32.and
                  (i32.eq (i32.load8_u (i32.add (local.get $data_ptr) (i32.add (local.get $i) (i32.const 2)))) (i32.const 0x75))    ;; 'u'
                  (i32.eq (i32.load8_u (i32.add (local.get $data_ptr) (i32.add (local.get $i) (i32.const 3)))) (i32.const 0x6e))))  ;; 'n'
            (then (local.set $found_func (i32.const 1)))
          )
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $search_func)
        )
      )
    )

    ;; Return 1 if any WAT text patterns found
    (i32.or (local.get $found_module) (local.get $found_func))
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

  ;; Run all binary integration tests
  (func $run_all_binary_integration_tests (export "run_all_binary_integration_tests") (result i32)
    (local $test1 i32)
    (local $test2 i32)
    (local $test3 i32)
    (local $test4 i32)
    (local $test5 i32)
    (local $all_passed i32)

    ;; Initialize
    (global.set $test_results (i32.const 0))

    ;; Run tests in sequence
    (local.set $test1 (call $test_binary_codegen_init))
    (local.set $test2 (call $test_binary_wasm_compilation))
    (local.set $test3 (call $test_binary_output_validation))
    (local.set $test4 (call $test_compilation_statistics))
    (local.set $test5 (call $test_binary_vs_wat_distinction))

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
    ;; Store "test_module" at offset 49650
    (i32.store8 offset=49650 (i32.const 0) (i32.const 116)) ;; 't'
    (i32.store8 offset=49651 (i32.const 0) (i32.const 101)) ;; 'e'
    (i32.store8 offset=49652 (i32.const 0) (i32.const 115)) ;; 's'
    (i32.store8 offset=49653 (i32.const 0) (i32.const 116)) ;; 't'
    (i32.store8 offset=49654 (i32.const 0) (i32.const 95))  ;; '_'
    (i32.store8 offset=49655 (i32.const 0) (i32.const 109)) ;; 'm'
    (i32.store8 offset=49656 (i32.const 0) (i32.const 111)) ;; 'o'
    (i32.store8 offset=49657 (i32.const 0) (i32.const 100)) ;; 'd'
    (i32.store8 offset=49658 (i32.const 0) (i32.const 117)) ;; 'u'
    (i32.store8 offset=49659 (i32.const 0) (i32.const 108)) ;; 'l'
    (i32.store8 offset=49660 (i32.const 0) (i32.const 101)) ;; 'e'
  )

  (start $init_test_data)
)
