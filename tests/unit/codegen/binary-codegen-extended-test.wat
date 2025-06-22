;; Extended Binary Codegen Test
;; Tests binary WASM generation infrastructure

(module $binary_codegen_extended_test
  ;; Import memory for test operations
  (import "lexer_memory" "memory" (memory 1))

  ;; Import binary codegen system
  (import "codegen_binary_main" "init_binary_code_generation" (func $init_binary_code_generation))
  (import "codegen_binary_main" "generate_test_binary" (func $generate_test_binary (param i32 i32) (result i32)))
  (import "codegen_binary_main" "get_binary_wasm_output" (func $get_binary_wasm_output (param i32)))

  ;; Test workspace
  (global $TEST_WORKSPACE i32 (i32.const 50000))
  (global $RESULT_BUFFER i32 (i32.const 50100))

  ;; Test: Binary codegen mode is active
  (func $test_binary_mode_active (export "test_binary_mode_active") (result i32)
    (call $init_binary_code_generation)
    ;; Should complete without error
    (i32.const 1)
  )

  ;; Test: Advanced binary generation with larger module
  (func $test_advanced_binary_generation (export "test_advanced_binary_generation") (result i32)
    (local $bytes_generated i32)
    (local $output_ptr i32)
    (local $output_len i32)
    (local $module_name_ptr i32)
    (local $section_id i32)

    ;; Prepare module name "advanced_module"
    (local.set $module_name_ptr (global.get $TEST_WORKSPACE))
    (i32.store8 (local.get $module_name_ptr) (i32.const 97))   ;; 'a'
    (i32.store8 offset=1 (local.get $module_name_ptr) (i32.const 100))  ;; 'd'
    (i32.store8 offset=2 (local.get $module_name_ptr) (i32.const 118))  ;; 'v'
    (i32.store8 offset=3 (local.get $module_name_ptr) (i32.const 97))   ;; 'a'
    (i32.store8 offset=4 (local.get $module_name_ptr) (i32.const 110))  ;; 'n'
    (i32.store8 offset=5 (local.get $module_name_ptr) (i32.const 99))   ;; 'c'
    (i32.store8 offset=6 (local.get $module_name_ptr) (i32.const 101))  ;; 'e'
    (i32.store8 offset=7 (local.get $module_name_ptr) (i32.const 100))  ;; 'd'

    ;; Initialize binary code generation
    (call $init_binary_code_generation)

    ;; Generate test binary module with longer name
    (local.set $bytes_generated
      (call $generate_test_binary
        (local.get $module_name_ptr)
        (i32.const 8)))

    ;; Should generate bytes for a valid binary module
    (if (i32.lt_u (local.get $bytes_generated) (i32.const 10))
      (then (return (i32.const 0))))  ;; Fail: too few bytes

    ;; Get output buffer and verify structure
    (call $get_binary_wasm_output (global.get $RESULT_BUFFER))
    (local.set $output_ptr (i32.load (global.get $RESULT_BUFFER)))
    (local.set $output_len (i32.load offset=4 (global.get $RESULT_BUFFER)))

    ;; Verify length matches
    (if (i32.ne (local.get $output_len) (local.get $bytes_generated))
      (then (return (i32.const 0))))  ;; Fail: length mismatch

    ;; Verify WASM magic number and version
    (if (i32.ne (i32.load (local.get $output_ptr)) (i32.const 0x6d736100))
      (then (return (i32.const 0))))  ;; Fail: invalid magic
    (if (i32.ne (i32.load offset=4 (local.get $output_ptr)) (i32.const 0x00000001))
      (then (return (i32.const 0))))  ;; Fail: invalid version

    ;; Check that we have some sections (at least type section)
    (local.set $output_ptr (i32.add (local.get $output_ptr) (i32.const 8)))  ;; Skip header
    (local.set $output_len (i32.sub (local.get $output_len) (i32.const 8)))

    ;; Look for a section (any section ID > 0)
    (if (i32.le_u (local.get $output_len) (i32.const 0))
      (then (return (i32.const 0))))  ;; Fail: no sections

    ;; Check first byte is a valid section ID (1-11)
    (local.set $section_id (i32.load8_u (local.get $output_ptr)))
    (if (i32.or
          (i32.lt_u (local.get $section_id) (i32.const 1))
          (i32.gt_u (local.get $section_id) (i32.const 11)))
      (then (return (i32.const 0))))  ;; Fail: invalid section ID

    (i32.const 1)  ;; Success
  )

  ;; Test: Binary output is distinct from WAT text
  (func $test_binary_not_wat_text (export "test_binary_not_wat_text") (result i32)
    (local $bytes_generated i32)
    (local $output_ptr i32)
    (local $output_len i32)
    (local $module_name_ptr i32)
    (local $i i32)
    (local $char i32)

    ;; Prepare module name "binary_test"
    (local.set $module_name_ptr (global.get $TEST_WORKSPACE))
    (i32.store8 (local.get $module_name_ptr) (i32.const 98))   ;; 'b'
    (i32.store8 offset=1 (local.get $module_name_ptr) (i32.const 105))  ;; 'i'
    (i32.store8 offset=2 (local.get $module_name_ptr) (i32.const 110))  ;; 'n'

    ;; Generate binary module
    (local.set $bytes_generated
      (call $generate_test_binary
        (local.get $module_name_ptr)
        (i32.const 3)))

    ;; Get output buffer
    (call $get_binary_wasm_output (global.get $RESULT_BUFFER))
    (local.set $output_ptr (i32.load (global.get $RESULT_BUFFER)))
    (local.set $output_len (i32.load offset=4 (global.get $RESULT_BUFFER)))

    ;; Verify this is NOT WAT text by checking for absence of common WAT patterns
    ;; Skip header (first 8 bytes) and scan for ASCII text patterns
    (local.set $output_ptr (i32.add (local.get $output_ptr) (i32.const 8)))
    (local.set $output_len (i32.sub (local.get $output_len) (i32.const 8)))
    (local.set $i (i32.const 0))

    ;; Scan through output looking for WAT text indicators
    (loop $scan_for_text
      (if (i32.lt_u (local.get $i) (local.get $output_len))
        (then
          (local.set $char (i32.load8_u (i32.add (local.get $output_ptr) (local.get $i))))

          ;; Check for ASCII patterns that would indicate WAT text
          ;; Look for '(' character (40) which starts WAT expressions
          (if (i32.eq (local.get $char) (i32.const 40))
            (then
              ;; Found '(' - check if followed by common WAT keywords
              (if (i32.lt_u (i32.add (local.get $i) (i32.const 4)) (local.get $output_len))
                (then
                  ;; Check for "(module", "(func", "(param", etc.
                  (if (call $check_wat_keyword (i32.add (local.get $output_ptr) (local.get $i)))
                    (then (return (i32.const 0))))  ;; Fail: found WAT text
                )
              )
            )
          )

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $scan_for_text)
        )
      )
    )

    (i32.const 1)  ;; Success: no WAT text found
  )

  ;; Check if pointer contains a WAT keyword after '('
  (func $check_wat_keyword (param $ptr i32) (result i32)
    ;; Check for "module" (109, 111, 100, 117, 108, 101)
    (if (i32.and
          (i32.eq (i32.load8_u offset=1 (local.get $ptr)) (i32.const 109))  ;; 'm'
          (i32.eq (i32.load8_u offset=2 (local.get $ptr)) (i32.const 111))) ;; 'o'
      (then (return (i32.const 1))))

    ;; Check for "func" (102, 117, 110, 99)
    (if (i32.and
          (i32.eq (i32.load8_u offset=1 (local.get $ptr)) (i32.const 102))  ;; 'f'
          (i32.eq (i32.load8_u offset=2 (local.get $ptr)) (i32.const 117))) ;; 'u'
      (then (return (i32.const 1))))

    (i32.const 0)  ;; Not a WAT keyword
  )
)
