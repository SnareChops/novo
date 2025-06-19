;; Meta Functions Core Test
;; Tests the core meta function infrastructure

(module $meta_functions_core_test
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import meta function core
  (import "meta_functions_core" "identify_meta_function" (func $identify_meta_function (param i32 i32) (result i32)))
  (import "meta_functions_core" "is_meta_function_available" (func $is_meta_function_available (param i32 i32) (result i32)))
  (import "meta_functions_core" "get_meta_function_return_type" (func $get_meta_function_return_type (param i32 i32) (result i32)))
  (import "meta_functions_core" "init_meta_function_names" (func $init_meta_function_names))

  ;; Import meta function constants
  (import "meta_functions_core" "META_FUNC_TYPE" (global $META_FUNC_TYPE i32))
  (import "meta_functions_core" "META_FUNC_STRING" (global $META_FUNC_STRING i32))
  (import "meta_functions_core" "META_FUNC_SIZE" (global $META_FUNC_SIZE i32))
  (import "meta_functions_core" "META_FUNC_LOAD" (global $META_FUNC_LOAD i32))

  ;; Import type constants
  (import "typechecker_main" "TYPE_I32" (global $TYPE_I32 i32))
  (import "typechecker_main" "TYPE_STRING" (global $TYPE_STRING i32))
  (import "typechecker_main" "TYPE_U32" (global $TYPE_U32 i32))

  ;; Test meta function identification
  (func $test_meta_function_identification (result i32)
    (local $result i32)
    (local $total_passed i32)

    (local.set $total_passed (i32.const 0))

    ;; Initialize meta function names
    (call $init_meta_function_names)

    ;; Test 1: Identify "type" meta function
    (local.set $result (call $identify_meta_function (i32.const 512) (i32.const 4)))
    (if (i32.eq (local.get $result) (global.get $META_FUNC_TYPE))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    ;; Test 2: Identify "string" meta function
    (local.set $result (call $identify_meta_function (i32.const 520) (i32.const 6)))
    (if (i32.eq (local.get $result) (global.get $META_FUNC_STRING))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    ;; Test 3: Identify "size" meta function
    (local.set $result (call $identify_meta_function (i32.const 528) (i32.const 4)))
    (if (i32.eq (local.get $result) (global.get $META_FUNC_SIZE))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    ;; Test 4: Identify "load" meta function
    (local.set $result (call $identify_meta_function (i32.const 536) (i32.const 4)))
    (if (i32.eq (local.get $result) (global.get $META_FUNC_LOAD))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    ;; Test 5: Unknown meta function should return 0
    (i32.store8 (i32.const 1000) (i32.const 120))  ;; 'x'
    (i32.store8 (i32.const 1001) (i32.const 121))  ;; 'y'
    (i32.store8 (i32.const 1002) (i32.const 122))  ;; 'z'
    (local.set $result (call $identify_meta_function (i32.const 1000) (i32.const 3)))
    (if (i32.eqz (local.get $result))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    (local.get $total_passed)
  )

  ;; Test meta function availability
  (func $test_meta_function_availability (result i32)
    (local $result i32)
    (local $total_passed i32)

    (local.set $total_passed (i32.const 0))

    ;; Test 1: Universal meta functions should be available on all types
    (local.set $result (call $is_meta_function_available (global.get $META_FUNC_TYPE) (global.get $TYPE_I32)))
    (if (i32.eq (local.get $result) (i32.const 1))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    (local.set $result (call $is_meta_function_available (global.get $META_FUNC_STRING) (global.get $TYPE_STRING)))
    (if (i32.eq (local.get $result) (i32.const 1))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    ;; Test 2: Numeric meta functions should be available on numeric types
    (local.set $result (call $is_meta_function_available (global.get $META_FUNC_SIZE) (global.get $TYPE_I32)))
    (if (i32.eq (local.get $result) (i32.const 1))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    (local.set $result (call $is_meta_function_available (global.get $META_FUNC_LOAD) (global.get $TYPE_U32)))
    (if (i32.eq (local.get $result) (i32.const 1))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    ;; Test 3: String type should support size meta function
    (local.set $result (call $is_meta_function_available (global.get $META_FUNC_SIZE) (global.get $TYPE_STRING)))
    (if (i32.eq (local.get $result) (i32.const 1))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    (local.get $total_passed)
  )

  ;; Test meta function return types
  (func $test_meta_function_return_types (result i32)
    (local $result i32)
    (local $total_passed i32)

    (local.set $total_passed (i32.const 0))

    ;; Test 1: type() meta function should return string
    (local.set $result (call $get_meta_function_return_type (global.get $META_FUNC_TYPE) (global.get $TYPE_I32)))
    (if (i32.eq (local.get $result) (global.get $TYPE_STRING))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    ;; Test 2: string() meta function should return string
    (local.set $result (call $get_meta_function_return_type (global.get $META_FUNC_STRING) (global.get $TYPE_I32)))
    (if (i32.eq (local.get $result) (global.get $TYPE_STRING))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    ;; Test 3: size() meta function should return u32
    (local.set $result (call $get_meta_function_return_type (global.get $META_FUNC_SIZE) (global.get $TYPE_I32)))
    (if (i32.eq (local.get $result) (global.get $TYPE_U32))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    ;; Test 4: load() meta function should return same type as caller
    (local.set $result (call $get_meta_function_return_type (global.get $META_FUNC_LOAD) (global.get $TYPE_I32)))
    (if (i32.eq (local.get $result) (global.get $TYPE_I32))
      (then (local.set $total_passed (i32.add (local.get $total_passed) (i32.const 1)))))

    (local.get $total_passed)
  )

  ;; Main test function
  (func $run_tests (export "run_tests") (result i32)
    (local $identification_passed i32)
    (local $availability_passed i32)
    (local $return_types_passed i32)
    (local $total_passed i32)

    ;; Run identification tests
    (local.set $identification_passed (call $test_meta_function_identification))

    ;; Run availability tests
    (local.set $availability_passed (call $test_meta_function_availability))

    ;; Run return type tests
    (local.set $return_types_passed (call $test_meta_function_return_types))

    ;; Calculate total
    (local.set $total_passed (i32.add (local.get $identification_passed)
                                      (i32.add (local.get $availability_passed)
                                               (local.get $return_types_passed))))

    ;; Return 1 if all tests passed (should be 14 total), 0 otherwise
    (i32.eq (local.get $total_passed) (i32.const 14))
  )
)
