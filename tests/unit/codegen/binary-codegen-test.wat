;; Test Binary WASM Code Generation
;; Tests the corrected binary output format (Phase 7.3)

(module $test_binary_codegen
  ;; Import memory for testing
  (import "lexer_memory" "memory" (memory 1))

  ;; Import binary code generation
  (import "codegen_binary_main" "init_binary_code_generation" (func $init_binary_code_generation))
  (import "codegen_binary_main" "generate_test_binary" (func $generate_test_binary (param i32 i32) (result i32)))
  (import "codegen_binary_main" "get_binary_wasm_output" (func $get_binary_wasm_output (param i32)))
  (import "codegen_binary_main" "validate_binary_output" (func $validate_binary_output (result i32)))
  (import "codegen_binary_main" "get_compilation_mode" (func $get_compilation_mode (result i32)))
  (import "codegen_binary_main" "get_compilation_stats" (func $get_compilation_stats (param i32)))

  ;; Test workspace
  (global $TEST_WORKSPACE_START i32 (i32.const 48200))
  (global $TEST_WORKSPACE_SIZE i32 (i32.const 1024))

  ;; Test result storage
  (global $test_results (mut i32) (i32.const 0))

  ;; Test 1: Basic binary module generation
  (func $test_basic_binary_generation (export "test_basic_binary_generation") (result i32)
    (local $module_name_ptr i32)
    (local $module_name_len i32)
    (local $bytes_generated i32)
    (local $result i32)

    ;; Initialize test module name
    (local.set $module_name_ptr (global.get $TEST_WORKSPACE_START))
    (local.set $module_name_len (i32.const 11))

    ;; Store "test_module" at workspace start
    (call $store_test_string (local.get $module_name_ptr) (i32.const 49224) (local.get $module_name_len))

    ;; Generate test binary
    (local.set $bytes_generated
      (call $generate_test_binary (local.get $module_name_ptr) (local.get $module_name_len)))

    ;; Test should generate at least 8 bytes (WASM header)
    (local.set $result (i32.gt_u (local.get $bytes_generated) (i32.const 7)))

    ;; Update test results
    (if (local.get $result)
      (then (global.set $test_results (i32.or (global.get $test_results) (i32.const 1))))
    )

    (local.get $result)
  )

  ;; Test 2: Binary output validation
  (func $test_binary_output_validation (export "test_binary_output_validation") (result i32)
    (local $output_info_ptr i32)
    (local $output_ptr i32)
    (local $output_len i32)
    (local $magic_valid i32)
    (local $validation_result i32)
    (local $result i32)

    ;; Get binary output
    (local.set $output_info_ptr (i32.add (global.get $TEST_WORKSPACE_START) (i32.const 64)))
    (call $get_binary_wasm_output (local.get $output_info_ptr))

    (local.set $output_ptr (i32.load (local.get $output_info_ptr)))
    (local.set $output_len (i32.load offset=4 (local.get $output_info_ptr)))

    ;; Validate output has correct WASM magic number
    (local.set $validation_result (call $validate_binary_output))

    ;; Manual check: first 4 bytes should be [0x00, 0x61, 0x73, 0x6d] ("\0asm")
    (local.set $magic_valid
      (i32.and
        (i32.and
          (i32.eq (i32.load8_u (local.get $output_ptr)) (i32.const 0x00))
          (i32.eq (i32.load8_u (i32.add (local.get $output_ptr) (i32.const 1))) (i32.const 0x61)))
        (i32.and
          (i32.eq (i32.load8_u (i32.add (local.get $output_ptr) (i32.const 2))) (i32.const 0x73))
          (i32.eq (i32.load8_u (i32.add (local.get $output_ptr) (i32.const 3))) (i32.const 0x6d)))))

    ;; Test passes if both validation methods agree and are positive
    (local.set $result (i32.and (local.get $validation_result) (local.get $magic_valid)))

    ;; Update test results
    (if (local.get $result)
      (then (global.set $test_results (i32.or (global.get $test_results) (i32.const 2))))
    )

    (local.get $result)
  )

  ;; Test 3: WASM version check
  (func $test_wasm_version_check (export "test_wasm_version_check") (result i32)
    (local $output_info_ptr i32)
    (local $output_ptr i32)
    (local $version_valid i32)
    (local $result i32)

    ;; Get binary output
    (local.set $output_info_ptr (i32.add (global.get $TEST_WORKSPACE_START) (i32.const 64)))
    (call $get_binary_wasm_output (local.get $output_info_ptr))

    (local.set $output_ptr (i32.load (local.get $output_info_ptr)))

    ;; Check WASM version: bytes 4-7 should be [0x01, 0x00, 0x00, 0x00] (version 1)
    (local.set $version_valid
      (i32.and
        (i32.and
          (i32.eq (i32.load8_u (i32.add (local.get $output_ptr) (i32.const 4))) (i32.const 0x01))
          (i32.eq (i32.load8_u (i32.add (local.get $output_ptr) (i32.const 5))) (i32.const 0x00)))
        (i32.and
          (i32.eq (i32.load8_u (i32.add (local.get $output_ptr) (i32.const 6))) (i32.const 0x00))
          (i32.eq (i32.load8_u (i32.add (local.get $output_ptr) (i32.const 7))) (i32.const 0x00)))))

    (local.set $result (local.get $version_valid))

    ;; Update test results
    (if (local.get $result)
      (then (global.set $test_results (i32.or (global.get $test_results) (i32.const 4))))
    )

    (local.get $result)
  )

  ;; Test 4: Compilation mode check
  (func $test_compilation_mode (export "test_compilation_mode") (result i32)
    (local $mode i32)
    (local $result i32)

    ;; Get current compilation mode (should be 0 for binary)
    (local.set $mode (call $get_compilation_mode))

    ;; Mode should be 0 (binary) after binary generation
    (local.set $result (i32.eq (local.get $mode) (i32.const 0)))

    ;; Update test results
    (if (local.get $result)
      (then (global.set $test_results (i32.or (global.get $test_results) (i32.const 8))))
    )

    (local.get $result)
  )

  ;; Test 5: Binary vs WAT text distinction
  (func $test_binary_vs_wat_distinction (export "test_binary_vs_wat_distinction") (result i32)
    (local $output_info_ptr i32)
    (local $output_ptr i32)
    (local $output_len i32)
    (local $is_binary i32)
    (local $contains_wat_text i32)
    (local $result i32)

    ;; Get binary output
    (local.set $output_info_ptr (i32.add (global.get $TEST_WORKSPACE_START) (i32.const 64)))
    (call $get_binary_wasm_output (local.get $output_info_ptr))

    (local.set $output_ptr (i32.load (local.get $output_info_ptr)))
    (local.set $output_len (i32.load offset=4 (local.get $output_info_ptr)))

    ;; Check that output starts with WASM magic (binary format)
    (local.set $is_binary
      (i32.eq (i32.load8_u (local.get $output_ptr)) (i32.const 0x00)))

    ;; Check that output does NOT contain WAT text like "(module"
    ;; Binary output should not contain readable ASCII text patterns
    (local.set $contains_wat_text (call $check_for_wat_text (local.get $output_ptr) (local.get $output_len)))

    ;; Test passes if it's binary format and doesn't contain WAT text
    (local.set $result (i32.and (local.get $is_binary) (i32.eqz (local.get $contains_wat_text))))

    ;; Update test results
    (if (local.get $result)
      (then (global.set $test_results (i32.or (global.get $test_results) (i32.const 16))))
    )

    (local.get $result)
  )

  ;; Check if binary data contains WAT text patterns
  ;; @param data_ptr: i32 - Pointer to data
  ;; @param data_len: i32 - Length of data
  ;; @returns i32 - 1 if WAT text found, 0 otherwise
  (func $check_for_wat_text (param $data_ptr i32) (param $data_len i32) (result i32)
    (local $i i32)
    (local $found_module i32)
    (local $found_i32_const i32)

    ;; Look for "(module" pattern (0x28, 0x6d, 0x6f, 0x64, 0x75, 0x6c, 0x65)
    (local.set $i (i32.const 0))
    (loop $search_module
      (if (i32.lt_u (i32.add (local.get $i) (i32.const 6)) (local.get $data_len))
        (then
          (if (i32.and
                (i32.and
                  (i32.eq (i32.load8_u (i32.add (local.get $data_ptr) (local.get $i))) (i32.const 0x28))      ;; '('
                  (i32.eq (i32.load8_u (i32.add (local.get $data_ptr) (i32.add (local.get $i) (i32.const 1)))) (i32.const 0x6d)))  ;; 'm'
                (i32.and
                  (i32.eq (i32.load8_u (i32.add (local.get $data_ptr) (i32.add (local.get $i) (i32.const 2)))) (i32.const 0x6f))    ;; 'o'
                  (i32.eq (i32.load8_u (i32.add (local.get $data_ptr) (i32.add (local.get $i) (i32.const 3)))) (i32.const 0x64))))  ;; 'd'
            (then (local.set $found_module (i32.const 1)))
          )
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $search_module)
        )
      )
    )

    ;; Look for "i32.const" pattern as well
    (local.set $i (i32.const 0))
    (loop $search_i32const
      (if (i32.lt_u (i32.add (local.get $i) (i32.const 8)) (local.get $data_len))
        (then
          (if (i32.and
                (i32.and
                  (i32.eq (i32.load8_u (i32.add (local.get $data_ptr) (local.get $i))) (i32.const 0x69))      ;; 'i'
                  (i32.eq (i32.load8_u (i32.add (local.get $data_ptr) (i32.add (local.get $i) (i32.const 1)))) (i32.const 0x33)))  ;; '3'
                (i32.and
                  (i32.eq (i32.load8_u (i32.add (local.get $data_ptr) (i32.add (local.get $i) (i32.const 2)))) (i32.const 0x32))    ;; '2'
                  (i32.eq (i32.load8_u (i32.add (local.get $data_ptr) (i32.add (local.get $i) (i32.const 3)))) (i32.const 0x2e))))  ;; '.'
            (then (local.set $found_i32_const (i32.const 1)))
          )
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $search_i32const)
        )
      )
    )

    ;; Return 1 if any WAT text patterns found
    (i32.or (local.get $found_module) (local.get $found_i32_const))
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

  ;; Run all binary codegen tests
  (func $run_all_binary_tests (export "run_all_binary_tests") (result i32)
    (local $test1 i32)
    (local $test2 i32)
    (local $test3 i32)
    (local $test4 i32)
    (local $test5 i32)
    (local $all_passed i32)

    ;; Initialize
    (global.set $test_results (i32.const 0))
    (call $init_binary_code_generation)

    ;; Run tests in sequence
    (local.set $test1 (call $test_basic_binary_generation))
    (local.set $test2 (call $test_binary_output_validation))
    (local.set $test3 (call $test_wasm_version_check))
    (local.set $test4 (call $test_compilation_mode))
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
    ;; Store "test_module" at offset 49224
    (i32.store8 offset=49224 (i32.const 0) (i32.const 116))  ;; 't'
    (i32.store8 offset=49225 (i32.const 0) (i32.const 101))  ;; 'e'
    (i32.store8 offset=49226 (i32.const 0) (i32.const 115))  ;; 's'
    (i32.store8 offset=49227 (i32.const 0) (i32.const 116))  ;; 't'
    (i32.store8 offset=49228 (i32.const 0) (i32.const 95))   ;; '_'
    (i32.store8 offset=49229 (i32.const 0) (i32.const 109))  ;; 'm'
    (i32.store8 offset=49230 (i32.const 0) (i32.const 111))  ;; 'o'
    (i32.store8 offset=49231 (i32.const 0) (i32.const 100))  ;; 'd'
    (i32.store8 offset=49232 (i32.const 0) (i32.const 117))  ;; 'u'
    (i32.store8 offset=49233 (i32.const 0) (i32.const 108))  ;; 'l'
    (i32.store8 offset=49234 (i32.const 0) (i32.const 101))  ;; 'e'
  )

  (start $init_test_data)
)
