;; Type Checker Infrastructure Basic Test
;; Tests core type checking functionality

(module $typechecker_basic_test
  ;; Import memory from parser main
  (import "parser_main" "memory" (memory 1))

  ;; Import type checker functions
  (import "typechecker_main" "get_node_type_info" (func $get_node_type_info (param i32) (result i32)))
  (import "typechecker_main" "set_node_type_info" (func $set_node_type_info (param i32 i32) (result i32)))
  (import "typechecker_main" "types_compatible" (func $types_compatible (param i32 i32) (result i32)))
  (import "typechecker_main" "infer_literal_type" (func $infer_literal_type (param i32) (result i32)))
  (import "typechecker_main" "add_symbol" (func $add_symbol (param i32 i32 i32) (result i32)))
  (import "typechecker_main" "lookup_symbol" (func $lookup_symbol (param i32 i32) (result i32)))
  (import "typechecker_main" "enter_scope" (func $enter_scope))
  (import "typechecker_main" "exit_scope" (func $exit_scope))
  (import "typechecker_main" "reset_type_checker" (func $reset_type_checker))

  ;; Import type constants from typechecker_main
  (import "typechecker_main" "TYPE_UNKNOWN" (global $TYPE_UNKNOWN i32))
  (import "typechecker_main" "TYPE_ERROR" (global $TYPE_ERROR i32))
  (import "typechecker_main" "TYPE_I32" (global $TYPE_I32 i32))
  (import "typechecker_main" "TYPE_I64" (global $TYPE_I64 i32))
  (import "typechecker_main" "TYPE_F32" (global $TYPE_F32 i32))
  (import "typechecker_main" "TYPE_F64" (global $TYPE_F64 i32))
  (import "typechecker_main" "TYPE_BOOL" (global $TYPE_BOOL i32))
  (import "typechecker_main" "TYPE_STRING" (global $TYPE_STRING i32))

  ;; Global test counters
  (global $test_count (mut i32) (i32.const 0))
  (global $pass_count (mut i32) (i32.const 0))

  ;; Helper function to run a test
  (func $run_test (param $test_name_start i32) (param $test_name_len i32) (param $test_func i32) (result i32)
    (local $result i32)

    ;; Increment test counter
    (global.set $test_count (i32.add (global.get $test_count) (i32.const 1)))

    ;; Run test function (using function table would be better, but this is simpler)
    (local.set $result (local.get $test_func))

    (if (local.get $result)
      (then
        ;; Test passed
        (global.set $pass_count (i32.add (global.get $pass_count) (i32.const 1)))
      )
    )

    (local.get $result)
  )

  ;; Test type compatibility
  (func $test_type_compatibility (result i32)
    (local $result i32)

    ;; Reset state
    (call $reset_type_checker)

    ;; Test same types are compatible
    (local.set $result (call $types_compatible (global.get $TYPE_I32) (global.get $TYPE_I32)))
    (if (i32.eqz (local.get $result)) (then (return (i32.const 0))))

    ;; Test different integer types are compatible
    (local.set $result (call $types_compatible (global.get $TYPE_I32) (global.get $TYPE_I64)))
    (if (i32.eqz (local.get $result)) (then (return (i32.const 0))))

    ;; Test different float types are compatible
    (local.set $result (call $types_compatible (global.get $TYPE_F32) (global.get $TYPE_F64)))
    (if (i32.eqz (local.get $result)) (then (return (i32.const 0))))

    ;; Test incompatible types
    (local.set $result (call $types_compatible (global.get $TYPE_I32) (global.get $TYPE_STRING)))
    (if (local.get $result) (then (return (i32.const 0))))

    ;; Test error type is not compatible
    (local.set $result (call $types_compatible (global.get $TYPE_ERROR) (global.get $TYPE_I32)))
    (if (local.get $result) (then (return (i32.const 0))))

    (i32.const 1)
  )

  ;; Test node type info storage and retrieval
  (func $test_node_type_info (result i32)
    (local $result i32)
    (local $node_ptr i32)
    (local $retrieved_type i32)

    ;; Reset state
    (call $reset_type_checker)

    ;; Test storing and retrieving type info
    (local.set $node_ptr (i32.const 1000))  ;; Dummy node pointer

    ;; Store type info
    (local.set $result (call $set_node_type_info (local.get $node_ptr) (global.get $TYPE_I32)))
    (if (i32.eqz (local.get $result)) (then (return (i32.const 0))))

    ;; Retrieve type info
    (local.set $retrieved_type (call $get_node_type_info (local.get $node_ptr)))
    (if (i32.ne (local.get $retrieved_type) (global.get $TYPE_I32)) (then (return (i32.const 0))))

    ;; Test unknown node returns TYPE_UNKNOWN
    (local.set $retrieved_type (call $get_node_type_info (i32.const 2000)))
    (if (i32.ne (local.get $retrieved_type) (global.get $TYPE_UNKNOWN)) (then (return (i32.const 0))))

    (i32.const 1)
  )

  ;; Test symbol table operations
  (func $test_symbol_table (result i32)
    (local $result i32)
    (local $retrieved_type i32)

    ;; Reset state
    (call $reset_type_checker)

    ;; Test adding and looking up symbols
    (local.set $result (call $add_symbol (i32.const 2000) (i32.const 4) (global.get $TYPE_I32)))  ;; "test"
    (if (i32.eqz (local.get $result)) (then (return (i32.const 0))))

    (local.set $retrieved_type (call $lookup_symbol (i32.const 2000) (i32.const 4)))
    (if (i32.ne (local.get $retrieved_type) (global.get $TYPE_I32)) (then (return (i32.const 0))))

    ;; Test unknown symbol returns TYPE_UNKNOWN
    (local.set $retrieved_type (call $lookup_symbol (i32.const 2100) (i32.const 5)))  ;; "other"
    (if (i32.ne (local.get $retrieved_type) (global.get $TYPE_UNKNOWN)) (then (return (i32.const 0))))

    (i32.const 1)
  )

  ;; Test scope management
  (func $test_scope_management (result i32)
    (local $result i32)
    (local $retrieved_type i32)

    ;; Reset state
    (call $reset_type_checker)

    ;; Add symbol in outer scope
    (local.set $result (call $add_symbol (i32.const 2000) (i32.const 4) (global.get $TYPE_I32)))  ;; "test"
    (if (i32.eqz (local.get $result)) (then (return (i32.const 0))))

    ;; Enter new scope
    (call $enter_scope)

    ;; Add symbol with same name in inner scope
    (local.set $result (call $add_symbol (i32.const 2000) (i32.const 4) (global.get $TYPE_STRING)))  ;; "test"
    (if (i32.eqz (local.get $result)) (then (return (i32.const 0))))

    ;; Should find inner scope symbol
    (local.set $retrieved_type (call $lookup_symbol (i32.const 2000) (i32.const 4)))
    (if (i32.ne (local.get $retrieved_type) (global.get $TYPE_STRING)) (then (return (i32.const 0))))

    ;; Exit scope
    (call $exit_scope)

    ;; Should now find outer scope symbol
    (local.set $retrieved_type (call $lookup_symbol (i32.const 2000) (i32.const 4)))
    (if (i32.ne (local.get $retrieved_type) (global.get $TYPE_I32)) (then (return (i32.const 0))))

    (i32.const 1)
  )

  ;; Test data
  (data (i32.const 2000) "test")
  (data (i32.const 2100) "other")

  ;; Test names
  (data (i32.const 3000) "type_compatibility")
  (data (i32.const 3100) "node_type_info")
  (data (i32.const 3200) "symbol_table")
  (data (i32.const 3300) "scope_management")

  ;; Main test function
  (func $run_tests (export "run_tests") (result i32)
    (local $success i32)
    (local $all_passed i32)
    (local.set $all_passed (i32.const 1))

    ;; Test 1: Type compatibility
    (local.set $success (call $test_type_compatibility))
    (if (i32.eqz (local.get $success))
      (then (local.set $all_passed (i32.const 0))))

    ;; Test 2: Node type info
    (local.set $success (call $test_node_type_info))
    (if (i32.eqz (local.get $success))
      (then (local.set $all_passed (i32.const 0))))

    ;; Test 3: Symbol table
    (local.set $success (call $test_symbol_table))
    (if (i32.eqz (local.get $success))
      (then (local.set $all_passed (i32.const 0))))

    ;; Test 4: Scope management
    (local.set $success (call $test_scope_management))
    (if (i32.eqz (local.get $success))
      (then (local.set $all_passed (i32.const 0))))

    ;; Return 1 if all tests passed, 0 otherwise
    (local.get $all_passed)  ;; Changed from: (i32.eq (global.get $pass_count) (i32.const 4))
  )

  ;; Start function for testing
  (func $_start (export "_start")
    (local $result i32)
    (local.set $result (call $run_tests))
    (if (local.get $result)
      (then)  ;; Success
      (else unreachable)  ;; Failure
    )
  )
)
