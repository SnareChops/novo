;; Expression Type Checking Test
;; Tests type checking and inference for expressions

(module $expression_type_checking_test
  ;; Import memory from parser main
  (import "parser_main" "memory" (memory 1))

  ;; Import type checker functions
  (import "typechecker_main" "get_node_type_info" (func $get_node_type_info (param i32) (result i32)))
  (import "typechecker_main" "set_node_type_info" (func $set_node_type_info (param i32 i32) (result i32)))
  (import "typechecker_main" "types_compatible" (func $types_compatible (param i32 i32) (result i32)))
  (import "typechecker_main" "infer_literal_type" (func $infer_literal_type (param i32) (result i32)))
  (import "typechecker_main" "add_symbol" (func $add_symbol (param i32 i32 i32) (result i32)))
  (import "typechecker_main" "lookup_symbol" (func $lookup_symbol (param i32 i32) (result i32)))
  (import "typechecker_main" "reset_type_checker" (func $reset_type_checker))

  ;; Import expression type checker functions
  (import "typechecker_expressions" "check_binary_arithmetic" (func $check_binary_arithmetic (param i32 i32 i32) (result i32)))
  (import "typechecker_expressions" "typecheck_expression" (func $typecheck_expression (param i32) (result i32)))
  (import "typechecker_expressions" "refine_literal_type" (func $refine_literal_type (param i32 i32) (result i32)))

  ;; Import AST functions for creating test nodes
  (import "ast_node_creators" "create_expr_integer_literal" (func $create_integer_literal (param i64) (result i32)))
  (import "ast_node_creators" "create_expr_float_literal" (func $create_float_literal (param f64) (result i32)))
  (import "ast_node_creators" "create_expr_string_literal" (func $create_string_literal (param i32 i32) (result i32)))
  (import "ast_node_creators" "create_expr_bool_literal" (func $create_bool_literal (param i32) (result i32)))
  (import "ast_node_creators" "create_expr_add" (func $create_binary_expr (param i32 i32) (result i32)))
  (import "ast_node_creators" "create_expr_mul" (func $create_mul_expr (param i32 i32) (result i32)))
  (import "ast_node_creators" "create_expr_identifier" (func $create_identifier_expr (param i32 i32) (result i32)))

  ;; Import AST node type constants
  (import "ast_node_types" "EXPR_ADD" (global $EXPR_ADD i32))
  (import "ast_node_types" "EXPR_SUB" (global $EXPR_SUB i32))
  (import "ast_node_types" "EXPR_MUL" (global $EXPR_MUL i32))
  (import "ast_node_types" "EXPR_DIV" (global $EXPR_DIV i32))
  (import "ast_node_types" "EXPR_MOD" (global $EXPR_MOD i32))

  ;; Global test counters
  (global $test_count (mut i32) (i32.const 0))
  (global $pass_count (mut i32) (i32.const 0))

  ;; Type constants (should match typechecker_main)
  (global $TYPE_UNKNOWN i32 (i32.const 0))
  (global $TYPE_ERROR i32 (i32.const 1))
  (global $TYPE_I32 i32 (i32.const 2))
  (global $TYPE_I64 i32 (i32.const 3))
  (global $TYPE_F32 i32 (i32.const 4))
  (global $TYPE_F64 i32 (i32.const 5))
  (global $TYPE_BOOL i32 (i32.const 6))
  (global $TYPE_STRING i32 (i32.const 7))

  ;; Test data section for string literals
  (data (i32.const 1000) "hello")
  (data (i32.const 1010) "world")
  (data (i32.const 1020) "myVar")

  ;; Helper function to run a test
  (func $run_test (param $expected i32) (param $actual i32) (result i32)
    (local $result i32)

    ;; Increment test counter
    (global.set $test_count (i32.add (global.get $test_count) (i32.const 1)))

    ;; Check if expected equals actual
    (local.set $result (i32.eq (local.get $expected) (local.get $actual)))

    (if (local.get $result)
      (then
        ;; Test passed
        (global.set $pass_count (i32.add (global.get $pass_count) (i32.const 1)))
      )
    )

    (local.get $result)
  )

  ;; Test binary arithmetic type checking
  (func $test_binary_arithmetic
    (local $result i32)

    ;; Test i32 + i32 = i32
    (local.set $result (call $check_binary_arithmetic (global.get $TYPE_I32) (global.get $TYPE_I32) (global.get $EXPR_ADD)))
    (drop (call $run_test (global.get $TYPE_I32) (local.get $result)))

    ;; Test f64 + f64 = f64
    (local.set $result (call $check_binary_arithmetic (global.get $TYPE_F64) (global.get $TYPE_F64) (global.get $EXPR_ADD)))
    (drop (call $run_test (global.get $TYPE_F64) (local.get $result)))

    ;; Test i32 + f64 = error (no implicit conversion)
    (local.set $result (call $check_binary_arithmetic (global.get $TYPE_I32) (global.get $TYPE_F64) (global.get $EXPR_ADD)))
    (drop (call $run_test (global.get $TYPE_ERROR) (local.get $result)))

    ;; Test bool + i32 = error (invalid operation)
    (local.set $result (call $check_binary_arithmetic (global.get $TYPE_BOOL) (global.get $TYPE_I32) (global.get $EXPR_ADD)))
    (drop (call $run_test (global.get $TYPE_ERROR) (local.get $result)))

    ;; Test string + string = error (no string concatenation with +)
    (local.set $result (call $check_binary_arithmetic (global.get $TYPE_STRING) (global.get $TYPE_STRING) (global.get $EXPR_ADD)))
    (drop (call $run_test (global.get $TYPE_ERROR) (local.get $result)))
  )

  ;; Test literal type inference
  (func $test_literal_inference
    (local $node i32)
    (local $result i32)

    ;; Reset type checker state
    (call $reset_type_checker)

    ;; Test integer literal (42) -> i32
    (local.set $node (call $create_integer_literal (i64.const 42)))
    (local.set $result (call $typecheck_expression (local.get $node)))
    (drop (call $run_test (global.get $TYPE_I32) (local.get $result)))

    ;; Test float literal (3.14) -> f64
    (local.set $node (call $create_float_literal (f64.const 3.14))) ;; Representing 3.14 as integer for simplicity
    (local.set $result (call $typecheck_expression (local.get $node)))
    (drop (call $run_test (global.get $TYPE_F64) (local.get $result)))

    ;; Test string literal ("hello") -> string
    (local.set $node (call $create_string_literal (i32.const 1000) (i32.const 5))) ;; "hello"
    (local.set $result (call $typecheck_expression (local.get $node)))
    (drop (call $run_test (global.get $TYPE_STRING) (local.get $result)))

    ;; Test bool literal (true) -> bool
    (local.set $node (call $create_bool_literal (i32.const 1))) ;; true
    (local.set $result (call $typecheck_expression (local.get $node)))
    (drop (call $run_test (global.get $TYPE_BOOL) (local.get $result)))

    ;; Test bool literal (false) -> bool
    (local.set $node (call $create_bool_literal (i32.const 0))) ;; false
    (local.set $result (call $typecheck_expression (local.get $node)))
    (drop (call $run_test (global.get $TYPE_BOOL) (local.get $result)))
  )

  ;; Test binary expression type checking
  (func $test_binary_expressions
    (local $left_node i32)
    (local $right_node i32)
    (local $expr_node i32)
    (local $result i32)

    ;; Reset type checker state
    (call $reset_type_checker)

    ;; Test 42 + 10 -> i32
    (local.set $left_node (call $create_integer_literal (i64.const 42)))
    (local.set $right_node (call $create_integer_literal (i64.const 10)))
    (local.set $expr_node (call $create_binary_expr (local.get $left_node) (local.get $right_node))) ;; Addition expression
    (local.set $result (call $typecheck_expression (local.get $expr_node)))
    (drop (call $run_test (global.get $TYPE_I32) (local.get $result)))

    ;; Test 3.14 * 2.0 -> f64 (simulated)
    (local.set $left_node (call $create_float_literal (f64.const 3.14)))
    (local.set $right_node (call $create_float_literal (f64.const 2.00)))
    (local.set $expr_node (call $create_mul_expr (local.get $left_node) (local.get $right_node)))
    (local.set $result (call $typecheck_expression (local.get $expr_node)))
    (drop (call $run_test (global.get $TYPE_F64) (local.get $result)))
  )

  ;; Test variable type lookup
  (func $test_variable_lookup
    (local $var_node i32)
    (local $result i32)
    (local $symbol_result i32)

    ;; Reset type checker state
    (call $reset_type_checker)

    ;; Add a variable to symbol table
    (local.set $symbol_result (call $add_symbol (i32.const 1020) (i32.const 5) (global.get $TYPE_I32))) ;; "myVar" -> i32

    ;; Create identifier expression for the variable
    (local.set $var_node (call $create_identifier_expr (i32.const 1020) (i32.const 5))) ;; "myVar"

    ;; Check the expression type should resolve to i32
    (local.set $result (call $typecheck_expression (local.get $var_node)))
    (drop (call $run_test (global.get $TYPE_I32) (local.get $result)))
  )

  ;; Test all arithmetic operators
  (func $test_all_operators
    (local $result i32)

    ;; Test subtraction: i32 - i32 = i32
    (local.set $result (call $check_binary_arithmetic (global.get $TYPE_I32) (global.get $TYPE_I32) (global.get $EXPR_SUB)))
    (drop (call $run_test (global.get $TYPE_I32) (local.get $result)))

    ;; Test multiplication: f64 * f64 = f64
    (local.set $result (call $check_binary_arithmetic (global.get $TYPE_F64) (global.get $TYPE_F64) (global.get $EXPR_MUL)))
    (drop (call $run_test (global.get $TYPE_F64) (local.get $result)))

    ;; Test division: i32 / i32 = i32
    (local.set $result (call $check_binary_arithmetic (global.get $TYPE_I32) (global.get $TYPE_I32) (global.get $EXPR_DIV)))
    (drop (call $run_test (global.get $TYPE_I32) (local.get $result)))

    ;; Test modulo: i32 % i32 = i32
    (local.set $result (call $check_binary_arithmetic (global.get $TYPE_I32) (global.get $TYPE_I32) (global.get $EXPR_MOD)))
    (drop (call $run_test (global.get $TYPE_I32) (local.get $result)))

    ;; Test division with floats: f64 / f64 = f64
    (local.set $result (call $check_binary_arithmetic (global.get $TYPE_F64) (global.get $TYPE_F64) (global.get $EXPR_DIV)))
    (drop (call $run_test (global.get $TYPE_F64) (local.get $result)))
  )

  ;; Main test function
  (func $run_tests (export "run_tests") (result i32)
    ;; Reset counters
    (global.set $test_count (i32.const 0))
    (global.set $pass_count (i32.const 0))

    ;; Run all test categories
    (call $test_binary_arithmetic)
    (call $test_literal_inference)
    (call $test_binary_expressions)
    (call $test_variable_lookup)
    (call $test_all_operators)

    ;; Return 1 if all tests passed, 0 otherwise
    (i32.eq (global.get $test_count) (global.get $pass_count))
  )

  ;; Export test count functions for debugging
  (func $get_test_count (export "get_test_count") (result i32)
    (global.get $test_count)
  )

  (func $get_pass_count (export "get_pass_count") (result i32)
    (global.get $pass_count)
  )
)
