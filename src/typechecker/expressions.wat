;; Novo Expression Type Checker
;; Handles type checking and inference for expressions

(module $typechecker_expressions
  ;; Import memory from parser main
  (import "parser_main" "memory" (memory 1))

  ;; Import type checker infrastructure
  (import "typechecker_main" "get_node_type_info" (func $get_node_type_info (param i32) (result i32)))
  (import "typechecker_main" "set_node_type_info" (func $set_node_type_info (param i32 i32) (result i32)))
  (import "typechecker_main" "types_compatible" (func $types_compatible (param i32 i32) (result i32)))
  (import "typechecker_main" "infer_literal_type" (func $infer_literal_type (param i32) (result i32)))
  (import "typechecker_main" "lookup_symbol" (func $lookup_symbol (param i32 i32) (result i32)))

  ;; Import AST node type constants
  (import "ast_node_types" "EXPR_IDENTIFIER" (global $EXPR_IDENTIFIER i32))
  (import "ast_node_types" "EXPR_INTEGER_LITERAL" (global $EXPR_INTEGER_LITERAL i32))
  (import "ast_node_types" "EXPR_FLOAT_LITERAL" (global $EXPR_FLOAT_LITERAL i32))
  (import "ast_node_types" "EXPR_STRING_LITERAL" (global $EXPR_STRING_LITERAL i32))
  (import "ast_node_types" "EXPR_BOOL_LITERAL" (global $EXPR_BOOL_LITERAL i32))
  (import "ast_node_types" "EXPR_ADD" (global $EXPR_ADD i32))
  (import "ast_node_types" "EXPR_SUB" (global $EXPR_SUB i32))
  (import "ast_node_types" "EXPR_MUL" (global $EXPR_MUL i32))
  (import "ast_node_types" "EXPR_DIV" (global $EXPR_DIV i32))
  (import "ast_node_types" "EXPR_MOD" (global $EXPR_MOD i32))
  (import "ast_node_types" "EXPR_TRADITIONAL_CALL" (global $EXPR_TRADITIONAL_CALL i32))
  (import "ast_node_types" "EXPR_META_CALL" (global $EXPR_META_CALL i32))

  ;; Import AST core functions
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "ast_node_core" "get_child_count" (func $get_child_count (param i32) (result i32)))
  (import "ast_node_core" "get_child" (func $get_child (param i32 i32) (result i32)))

  ;; Type constants (matching typechecker_main)
  (global $TYPE_UNKNOWN i32 (i32.const 0))
  (global $TYPE_ERROR i32 (i32.const 1))
  (global $TYPE_I32 i32 (i32.const 2))
  (global $TYPE_I64 i32 (i32.const 3))
  (global $TYPE_F32 i32 (i32.const 4))
  (global $TYPE_F64 i32 (i32.const 5))
  (global $TYPE_BOOL i32 (i32.const 6))
  (global $TYPE_STRING i32 (i32.const 7))

  ;; Type check a binary arithmetic operation
  ;; @param left_type i32 - Type of left operand
  ;; @param right_type i32 - Type of right operand
  ;; @param op_type i32 - Operation type (ADD, SUB, MUL, DIV, MOD)
  ;; @returns i32 - Result type (TYPE_ERROR if invalid)
  (func $check_binary_arithmetic (export "check_binary_arithmetic") (param $left_type i32) (param $right_type i32) (param $op_type i32) (result i32)
    ;; Both operands must be numeric
    (if (i32.eqz (call $is_numeric_type (local.get $left_type)))
      (then (return (global.get $TYPE_ERROR))))
    (if (i32.eqz (call $is_numeric_type (local.get $right_type)))
      (then (return (global.get $TYPE_ERROR))))

    ;; Determine result type based on operand types
    (block $result_determined
      ;; If either operand is f64, result is f64
      (if (i32.or
            (i32.eq (local.get $left_type) (global.get $TYPE_F64))
            (i32.eq (local.get $right_type) (global.get $TYPE_F64)))
        (then (return (global.get $TYPE_F64))))

      ;; If either operand is f32, result is f32
      (if (i32.or
            (i32.eq (local.get $left_type) (global.get $TYPE_F32))
            (i32.eq (local.get $right_type) (global.get $TYPE_F32)))
        (then (return (global.get $TYPE_F32))))

      ;; If either operand is i64, result is i64
      (if (i32.or
            (i32.eq (local.get $left_type) (global.get $TYPE_I64))
            (i32.eq (local.get $right_type) (global.get $TYPE_I64)))
        (then (return (global.get $TYPE_I64))))

      ;; Both operands are i32, result is i32
      (if (i32.and
            (i32.eq (local.get $left_type) (global.get $TYPE_I32))
            (i32.eq (local.get $right_type) (global.get $TYPE_I32)))
        (then (return (global.get $TYPE_I32))))

      ;; Unknown numeric combination
      (return (global.get $TYPE_ERROR))
    )

    (global.get $TYPE_ERROR)
  )

  ;; Check if a type is numeric
  ;; @param type_id i32 - Type to check
  ;; @returns i32 - 1 if numeric, 0 if not
  (func $is_numeric_type (param $type_id i32) (result i32)
    (if (i32.eq (local.get $type_id) (global.get $TYPE_I32)) (then (return (i32.const 1))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_I64)) (then (return (i32.const 1))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_F32)) (then (return (i32.const 1))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_F64)) (then (return (i32.const 1))))
    (i32.const 0)
  )

  ;; Type check an expression node and all its children recursively
  ;; @param expr_node i32 - Pointer to expression AST node
  ;; @returns i32 - Type ID of the expression (TYPE_ERROR if type checking failed)
  (func $typecheck_expression (export "typecheck_expression") (param $expr_node i32) (result i32)
    (local $node_type i32)
    (local $existing_type i32)
    (local $inferred_type i32)
    (local $left_child i32)
    (local $right_child i32)
    (local $left_type i32)
    (local $right_type i32)
    (local $result_type i32)

    ;; Check if node is null
    (if (i32.eqz (local.get $expr_node))
      (then (return (global.get $TYPE_ERROR))))

    ;; Check if type is already known
    (local.set $existing_type (call $get_node_type_info (local.get $expr_node)))
    (if (i32.ne (local.get $existing_type) (global.get $TYPE_UNKNOWN))
      (then (return (local.get $existing_type))))

    (local.set $node_type (call $get_node_type (local.get $expr_node)))

    (block $type_determined
      ;; Handle literal expressions
      (if (i32.or
            (i32.or
              (i32.eq (local.get $node_type) (global.get $EXPR_INTEGER_LITERAL))
              (i32.eq (local.get $node_type) (global.get $EXPR_FLOAT_LITERAL)))
            (i32.or
              (i32.eq (local.get $node_type) (global.get $EXPR_STRING_LITERAL))
              (i32.eq (local.get $node_type) (global.get $EXPR_BOOL_LITERAL))))
        (then
          (local.set $inferred_type (call $infer_literal_type (local.get $expr_node)))
          (drop (call $set_node_type_info (local.get $expr_node) (local.get $inferred_type)))
          (return (local.get $inferred_type))
        )
      )

      ;; Handle identifier expressions
      (if (i32.eq (local.get $node_type) (global.get $EXPR_IDENTIFIER))
        (then
          ;; TODO: Look up identifier type in symbol table
          ;; For now, assume unknown type
          (local.set $inferred_type (global.get $TYPE_UNKNOWN))
          (drop (call $set_node_type_info (local.get $expr_node) (local.get $inferred_type)))
          (return (local.get $inferred_type))
        )
      )

      ;; Handle binary arithmetic operations
      (if (i32.or
            (i32.or
              (i32.or
                (i32.eq (local.get $node_type) (global.get $EXPR_ADD))
                (i32.eq (local.get $node_type) (global.get $EXPR_SUB)))
              (i32.or
                (i32.eq (local.get $node_type) (global.get $EXPR_MUL))
                (i32.eq (local.get $node_type) (global.get $EXPR_DIV))))
            (i32.eq (local.get $node_type) (global.get $EXPR_MOD)))
        (then
          ;; Binary operation: type check both children
          (local.set $left_child (call $get_child (local.get $expr_node) (i32.const 0)))
          (local.set $right_child (call $get_child (local.get $expr_node) (i32.const 1)))

          (if (i32.or (i32.eqz (local.get $left_child)) (i32.eqz (local.get $right_child)))
            (then
              ;; Missing child nodes
              (local.set $result_type (global.get $TYPE_ERROR))
            )
            (else
              ;; Type check children recursively
              (local.set $left_type (call $typecheck_expression (local.get $left_child)))
              (local.set $right_type (call $typecheck_expression (local.get $right_child)))

              ;; Determine result type
              (local.set $result_type (call $check_binary_arithmetic
                (local.get $left_type) (local.get $right_type) (local.get $node_type)))
            )
          )

          (drop (call $set_node_type_info (local.get $expr_node) (local.get $result_type)))
          (return (local.get $result_type))
        )
      )

      ;; Handle function calls
      (if (i32.eq (local.get $node_type) (global.get $EXPR_TRADITIONAL_CALL))
        (then
          ;; TODO: Look up function signature and check arguments
          ;; For now, assume unknown return type
          (local.set $inferred_type (global.get $TYPE_UNKNOWN))
          (drop (call $set_node_type_info (local.get $expr_node) (local.get $inferred_type)))
          (return (local.get $inferred_type))
        )
      )

      ;; Handle meta-function calls
      (if (i32.eq (local.get $node_type) (global.get $EXPR_META_CALL))
        (then
          ;; TODO: Look up meta-function signature and check arguments
          ;; For now, assume unknown return type
          (local.set $inferred_type (global.get $TYPE_UNKNOWN))
          (drop (call $set_node_type_info (local.get $expr_node) (local.get $inferred_type)))
          (return (local.get $inferred_type))
        )
      )

      ;; Unknown expression type
      (local.set $result_type (global.get $TYPE_ERROR))
    )

    ;; Store result and return
    (drop (call $set_node_type_info (local.get $expr_node) (local.get $result_type)))
    (local.get $result_type)
  )

  ;; Type check a list of expressions (e.g., function arguments)
  ;; @param expr_list_start i32 - Pointer to first expression node
  ;; @param expr_count i32 - Number of expressions
  ;; @returns i32 - 1 if all expressions type check successfully, 0 if any fail
  (func $typecheck_expression_list (export "typecheck_expression_list") (param $expr_list_start i32) (param $expr_count i32) (result i32)
    (local $i i32)
    (local $expr_node i32)
    (local $expr_type i32)

    (local.set $i (i32.const 0))
    (loop $check_loop
      (if (i32.lt_u (local.get $i) (local.get $expr_count))
        (then
          ;; Get expression node (assuming they're stored sequentially)
          (local.set $expr_node (i32.load (i32.add (local.get $expr_list_start) (i32.mul (local.get $i) (i32.const 4)))))

          ;; Type check this expression
          (local.set $expr_type (call $typecheck_expression (local.get $expr_node)))

          ;; Check for type error
          (if (i32.eq (local.get $expr_type) (global.get $TYPE_ERROR))
            (then (return (i32.const 0))))

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $check_loop)
        )
      )
    )

    ;; All expressions type checked successfully
    (i32.const 1)
  )

  ;; Get the expected type for a numeric literal based on context
  ;; @param literal_node i32 - Pointer to literal AST node
  ;; @param context_type i32 - Expected type from context
  ;; @returns i32 - Refined type for the literal
  (func $refine_literal_type (export "refine_literal_type") (param $literal_node i32) (param $context_type i32) (result i32)
    (local $node_type i32)
    (local $default_type i32)

    (local.set $node_type (call $get_node_type (local.get $literal_node)))
    (local.set $default_type (call $infer_literal_type (local.get $literal_node)))

    ;; For integer literals, use context type if it's a compatible integer type
    (if (i32.eq (local.get $node_type) (global.get $EXPR_INTEGER_LITERAL))
      (then
        (if (i32.or
              (i32.eq (local.get $context_type) (global.get $TYPE_I32))
              (i32.eq (local.get $context_type) (global.get $TYPE_I64)))
          (then (return (local.get $context_type))))
      )
    )

    ;; For float literals, use context type if it's a compatible float type
    (if (i32.eq (local.get $node_type) (global.get $EXPR_FLOAT_LITERAL))
      (then
        (if (i32.or
              (i32.eq (local.get $context_type) (global.get $TYPE_F32))
              (i32.eq (local.get $context_type) (global.get $TYPE_F64)))
          (then (return (local.get $context_type))))
      )
    )

    ;; Use default type
    (local.get $default_type)
  )
)
