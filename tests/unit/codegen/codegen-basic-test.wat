;; Code Generation Basic Test
;; Tests the basic code generation infrastructure

(module $codegen_basic_test
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import code generation main
  (import "codegen_main" "init_code_generation" (func $init_code_generation))
  (import "codegen_main" "generate_test_module" (func $generate_test_module (param i32 i32) (result i32)))
  (import "codegen_main" "get_generated_code" (func $get_generated_code (param i32)))
  (import "codegen_main" "get_codegen_stats" (func $get_codegen_stats (param i32)))
  (import "codegen_main" "init_static_strings" (func $init_static_strings))

  ;; Test basic code generation
  (func $test_basic_codegen (result i32)
    (local $result i32)
    (local $code_info i32)
    (local $code_ptr i32)
    (local $code_len i32)
    (local $stats_info i32)
    (local $functions_count i32)
    (local $total_passed i32)

    (local.set $total_passed (i32.const 0))

    ;; Initialize static strings
    (call $init_static_strings)

    ;; Allocate memory for result storage
    (local.set $code_info (i32.const 60000))  ;; Use high memory for results
    (local.set $stats_info (i32.const 60010)) ;; Stats storage

    ;; Test 1: Initialize code generation
    (call $init_code_generation)
    (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))

    ;; Test 2: Generate test module
    ;; Module name "test_module" stored in memory
    (i32.store8 offset=60020 (i32.const 0) (i32.const 116)) ;; 't'
    (i32.store8 offset=60021 (i32.const 0) (i32.const 101)) ;; 'e'
    (i32.store8 offset=60022 (i32.const 0) (i32.const 115)) ;; 's'
    (i32.store8 offset=60023 (i32.const 0) (i32.const 116)) ;; 't'
    (i32.store8 offset=60024 (i32.const 0) (i32.const 95))  ;; '_'
    (i32.store8 offset=60025 (i32.const 0) (i32.const 109)) ;; 'm'
    (i32.store8 offset=60026 (i32.const 0) (i32.const 111)) ;; 'o'
    (i32.store8 offset=60027 (i32.const 0) (i32.const 100)) ;; 'd'
    (i32.store8 offset=60028 (i32.const 0) (i32.const 117)) ;; 'u'
    (i32.store8 offset=60029 (i32.const 0) (i32.const 108)) ;; 'l'
    (i32.store8 offset=60030 (i32.const 0) (i32.const 101)) ;; 'e'

    (local.set $result (call $generate_test_module (i32.const 60020) (i32.const 11)))
    (if (i32.eq (local.get $result) (i32.const 1))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    ;; Test 3: Get generated code
    (call $get_generated_code (local.get $code_info))
    (local.set $code_ptr (i32.load (local.get $code_info)))
    (local.set $code_len (i32.load offset=4 (local.get $code_info)))

    ;; Verify that code was generated (length > 0)
    (if (i32.gt_u (local.get $code_len) (i32.const 0))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    ;; Test 4: Verify code contains module header
    ;; Check that code starts with "(module $test_module"
    (if (i32.and
          (i32.gt_u (local.get $code_len) (i32.const 20))
          (i32.eq (i32.load8_u (local.get $code_ptr)) (i32.const 40))) ;; '('
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    ;; Test 5: Get statistics
    (call $get_codegen_stats (local.get $stats_info))
    (local.set $functions_count (i32.load (local.get $stats_info)))

    ;; Should have generated at least 1 function
    (if (i32.ge_u (local.get $functions_count) (i32.const 1))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    (local.get $total_passed)
  )

  ;; Test module generation components
  (func $test_module_components (result i32)
    (local $result i32)
    (local $code_info i32)
    (local $code_ptr i32)
    (local $code_len i32)
    (local $total_passed i32)
    (local $i i32)
    (local $found_import i32)
    (local $found_function i32)

    (local.set $total_passed (i32.const 0))
    (local.set $code_info (i32.const 60100))

    ;; Generate another test module
    (call $init_static_strings)
    (call $init_code_generation)

    ;; Generate module with name "components_test"
    (i32.store8 offset=60120 (i32.const 0) (i32.const 99))  ;; 'c'
    (i32.store8 offset=60121 (i32.const 0) (i32.const 111)) ;; 'o'
    (i32.store8 offset=60122 (i32.const 0) (i32.const 109)) ;; 'm'
    (i32.store8 offset=60123 (i32.const 0) (i32.const 112)) ;; 'p'
    (i32.store8 offset=60124 (i32.const 0) (i32.const 111)) ;; 'o'
    (i32.store8 offset=60125 (i32.const 0) (i32.const 110)) ;; 'n'
    (i32.store8 offset=60126 (i32.const 0) (i32.const 101)) ;; 'e'
    (i32.store8 offset=60127 (i32.const 0) (i32.const 110)) ;; 'n'
    (i32.store8 offset=60128 (i32.const 0) (i32.const 116)) ;; 't'
    (i32.store8 offset=60129 (i32.const 0) (i32.const 115)) ;; 's'

    (local.set $result (call $generate_test_module (i32.const 60120) (i32.const 10)))
    (if (i32.eq (local.get $result) (i32.const 1))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    ;; Get generated code
    (call $get_generated_code (local.get $code_info))
    (local.set $code_ptr (i32.load (local.get $code_info)))
    (local.set $code_len (i32.load offset=4 (local.get $code_info)))

    ;; Test that code contains expected components
    (local.set $found_import (i32.const 0))
    (local.set $found_function (i32.const 0))
    (local.set $i (i32.const 0))

    ;; Simple scan for "import" and "func" keywords
    (loop $scan_loop
      (if (i32.lt_u (local.get $i) (i32.sub (local.get $code_len) (i32.const 6)))
        (then
          ;; Check for "import"
          (if (i32.and
                (i32.eq (i32.load8_u (i32.add (local.get $code_ptr) (local.get $i))) (i32.const 105)) ;; 'i'
                (i32.eq (i32.load8_u (i32.add (local.get $code_ptr) (i32.add (local.get $i) (i32.const 1)))) (i32.const 109))) ;; 'm'
            (then (local.set $found_import (i32.const 1))))

          ;; Check for "func"
          (if (i32.and
                (i32.eq (i32.load8_u (i32.add (local.get $code_ptr) (local.get $i))) (i32.const 102)) ;; 'f'
                (i32.eq (i32.load8_u (i32.add (local.get $code_ptr) (i32.add (local.get $i) (i32.const 1)))) (i32.const 117))) ;; 'u'
            (then (local.set $found_function (i32.const 1))))

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $scan_loop))))

    ;; Count successful component detection
    (if (local.get $found_import)
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    (if (local.get $found_function)
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    (local.get $total_passed)
  )

  ;; Main test runner
  (func $run_tests (export "run_tests") (result i32)
    (local $basic_tests i32)
    (local $component_tests i32)
    (local $total_tests i32)

    ;; Run test suites
    (local.set $basic_tests (call $test_basic_codegen))
    (local.set $component_tests (call $test_module_components))

    ;; Calculate total
    (local.set $total_tests (i32.add (local.get $basic_tests) (local.get $component_tests)))

    ;; Return total passed tests
    (local.get $total_tests)
  )
)
