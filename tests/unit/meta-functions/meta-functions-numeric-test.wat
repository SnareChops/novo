;; Meta Functions Numeric Test
;; Tests the numeric meta function implementations

(module $meta_functions_numeric_test
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import numeric meta functions
  (import "meta_functions_numeric" "get_numeric_type_size" (func $get_numeric_type_size (param i32) (result i32)))
  (import "meta_functions_numeric" "get_numeric_type_name" (func $get_numeric_type_name (param i32 i32) (result i32)))
  (import "meta_functions_numeric" "numeric_value_to_string" (func $numeric_value_to_string (param i64 i32 i32) (result i32)))
  (import "meta_functions_numeric" "is_numeric_conversion_valid" (func $is_numeric_conversion_valid (param i32 i32) (result i32)))

  ;; Import type constants
  (import "typechecker_main" "TYPE_I32" (global $TYPE_I32 i32))
  (import "typechecker_main" "TYPE_I64" (global $TYPE_I64 i32))
  (import "typechecker_main" "TYPE_F32" (global $TYPE_F32 i32))
  (import "typechecker_main" "TYPE_F64" (global $TYPE_F64 i32))
  (import "typechecker_main" "TYPE_U8" (global $TYPE_U8 i32))
  (import "typechecker_main" "TYPE_U16" (global $TYPE_U16 i32))
  (import "typechecker_main" "TYPE_U32" (global $TYPE_U32 i32))
  (import "typechecker_main" "TYPE_U64" (global $TYPE_U64 i32))

  ;; Test numeric type size calculations
  (func $test_numeric_type_sizes (result i32)
    (local $result i32)
    (local $total_passed i32)

    (local.set $total_passed (i32.const 0))

    ;; Test 1: u8 should be 1 byte
    (local.set $result (call $get_numeric_type_size (global.get $TYPE_U8)))
    (if (i32.eq (local.get $result) (i32.const 1))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    ;; Test 2: u16 should be 2 bytes
    (local.set $result (call $get_numeric_type_size (global.get $TYPE_U16)))
    (if (i32.eq (local.get $result) (i32.const 2))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    ;; Test 3: i32 should be 4 bytes
    (local.set $result (call $get_numeric_type_size (global.get $TYPE_I32)))
    (if (i32.eq (local.get $result) (i32.const 4))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    ;; Test 4: u32 should be 4 bytes
    (local.set $result (call $get_numeric_type_size (global.get $TYPE_U32)))
    (if (i32.eq (local.get $result) (i32.const 4))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    ;; Test 5: f32 should be 4 bytes
    (local.set $result (call $get_numeric_type_size (global.get $TYPE_F32)))
    (if (i32.eq (local.get $result) (i32.const 4))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    ;; Test 6: i64 should be 8 bytes
    (local.set $result (call $get_numeric_type_size (global.get $TYPE_I64)))
    (if (i32.eq (local.get $result) (i32.const 8))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    ;; Test 7: u64 should be 8 bytes
    (local.set $result (call $get_numeric_type_size (global.get $TYPE_U64)))
    (if (i32.eq (local.get $result) (i32.const 8))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    ;; Test 8: f64 should be 8 bytes
    (local.set $result (call $get_numeric_type_size (global.get $TYPE_F64)))
    (if (i32.eq (local.get $result) (i32.const 8))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    (local.get $total_passed)
  )

  ;; Test numeric type name generation
  (func $test_numeric_type_names (result i32)
    (local $result i32)
    (local $total_passed i32)

    (local.set $total_passed (i32.const 0))

    ;; Test 1: i32 type name
    (local.set $result (call $get_numeric_type_name (global.get $TYPE_I32) (i32.const 1024)))
    (if (i32.eq (local.get $result) (i32.const 3))
      (then
        ;; Check if the string is "i32"
        (if (i32.and
              (i32.eq (i32.load8_u (i32.const 1024)) (i32.const 105))      ;; 'i'
              (i32.and
                (i32.eq (i32.load8_u (i32.const 1025)) (i32.const 51))    ;; '3'
                (i32.eq (i32.load8_u (i32.const 1026)) (i32.const 50))))  ;; '2'
          (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))))

    ;; Test 2: u8 type name
    (local.set $result (call $get_numeric_type_name (global.get $TYPE_U8) (i32.const 1032)))
    (if (i32.eq (local.get $result) (i32.const 2))
      (then
        ;; Check if the string is "u8"
        (if (i32.and
              (i32.eq (i32.load8_u (i32.const 1032)) (i32.const 117))     ;; 'u'
              (i32.eq (i32.load8_u (i32.const 1033)) (i32.const 56)))     ;; '8'
          (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))))

    ;; Test 3: f64 type name
    (local.set $result (call $get_numeric_type_name (global.get $TYPE_F64) (i32.const 1040)))
    (if (i32.eq (local.get $result) (i32.const 3))
      (then
        ;; Check if the string is "f64"
        (if (i32.and
              (i32.eq (i32.load8_u (i32.const 1040)) (i32.const 102))     ;; 'f'
              (i32.and
                (i32.eq (i32.load8_u (i32.const 1041)) (i32.const 54))    ;; '6'
                (i32.eq (i32.load8_u (i32.const 1042)) (i32.const 52))))  ;; '4'
          (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))))

    (local.get $total_passed)
  )

  ;; Test numeric value to string conversion
  (func $test_numeric_value_to_string (result i32)
    (local $result i32)
    (local $total_passed i32)

    (local.set $total_passed (i32.const 0))

    ;; Test 1: Convert simple i32 value (single digit)
    (local.set $result (call $numeric_value_to_string (i64.const 5) (global.get $TYPE_I32) (i32.const 1050)))
    (if (i32.gt_u (local.get $result) (i32.const 0))
      (then
        ;; Check if first character is '5'
        (if (i32.eq (i32.load8_u (i32.const 1050)) (i32.const 53))  ;; '5'
          (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))))

    ;; Test 2: Convert zero value
    (local.set $result (call $numeric_value_to_string (i64.const 0) (global.get $TYPE_I32) (i32.const 1060)))
    (if (i32.gt_u (local.get $result) (i32.const 0))
      (then
        ;; Check if first character is '0'
        (if (i32.eq (i32.load8_u (i32.const 1060)) (i32.const 48))  ;; '0'
          (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))))

    ;; Test 3: Convert i64 value
    (local.set $result (call $numeric_value_to_string (i64.const 7) (global.get $TYPE_I64) (i32.const 1070)))
    (if (i32.gt_u (local.get $result) (i32.const 0))
      (then
        ;; Check if first character is '7'
        (if (i32.eq (i32.load8_u (i32.const 1070)) (i32.const 55))  ;; '7'
          (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))))

    (local.get $total_passed)
  )

  ;; Test numeric conversion validation
  (func $test_numeric_conversion_validation (result i32)
    (local $result i32)
    (local $total_passed i32)

    (local.set $total_passed (i32.const 0))

    ;; Test 1: i32 to u32 conversion should be valid
    (local.set $result (call $is_numeric_conversion_valid (global.get $TYPE_I32) (global.get $TYPE_U32)))
    (if (i32.eq (local.get $result) (i32.const 1))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    ;; Test 2: f32 to f64 conversion should be valid
    (local.set $result (call $is_numeric_conversion_valid (global.get $TYPE_F32) (global.get $TYPE_F64)))
    (if (i32.eq (local.get $result) (i32.const 1))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    ;; Test 3: u8 to i64 conversion should be valid
    (local.set $result (call $is_numeric_conversion_valid (global.get $TYPE_U8) (global.get $TYPE_I64)))
    (if (i32.eq (local.get $result) (i32.const 1))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    (local.get $total_passed)
  )

  ;; Main test function
  (func $run_tests (export "run_tests") (result i32)
    (local $size_tests_passed i32)
    (local $name_tests_passed i32)
    (local $string_tests_passed i32)
    (local $conversion_tests_passed i32)
    (local $total_passed i32)

    ;; Run size tests
    (local.set $size_tests_passed (call $test_numeric_type_sizes))

    ;; Run name tests
    (local.set $name_tests_passed (call $test_numeric_type_names))

    ;; Run string conversion tests
    (local.set $string_tests_passed (call $test_numeric_value_to_string))

    ;; Run conversion validation tests
    (local.set $conversion_tests_passed (call $test_numeric_conversion_validation))

    ;; Calculate total
    (local.set $total_passed (i32.add (local.get $size_tests_passed)
                                      (i32.add (local.get $name_tests_passed)
                                               (i32.add (local.get $string_tests_passed)
                                                        (local.get $conversion_tests_passed)))))

    ;; Return 1 if all tests passed (should be 17 total), 0 otherwise
    (i32.eq (local.get $total_passed) (i32.const 17))
  )
)
