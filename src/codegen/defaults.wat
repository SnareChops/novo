;; Default Value Code Generation Module
;; Handles default value evaluation for function parameters and record fields
;; Phase 9.1: Default Value Implementation

(module $codegen_defaults
  ;; Import memory for data storage
  (import "lexer_memory" "memory" (memory 1))

  ;; Import AST for tree traversal
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "ast_node_core" "get_child_count" (func $get_child_count (param i32) (result i32)))
  (import "ast_node_core" "get_child" (func $get_child (param i32 i32) (result i32)))
  (import "ast_node_core" "get_node_value" (func $get_node_value (param i32) (result i32)))

  ;; Import AST node types
  (import "ast_node_types" "DECL_FUNCTION" (global $DECL_FUNCTION i32))
  (import "ast_node_types" "DECL_RECORD" (global $DECL_RECORD i32))
  (import "ast_node_types" "EXPR_INTEGER_LITERAL" (global $EXPR_INTEGER_LITERAL i32))
  (import "ast_node_types" "EXPR_FLOAT_LITERAL" (global $EXPR_FLOAT_LITERAL i32))
  (import "ast_node_types" "EXPR_STRING_LITERAL" (global $EXPR_STRING_LITERAL i32))
  (import "ast_node_types" "EXPR_BOOL_LITERAL" (global $EXPR_BOOL_LITERAL i32))
  (import "ast_node_types" "EXPR_IDENTIFIER" (global $EXPR_IDENTIFIER i32))
  (import "ast_node_types" "EXPR_TRADITIONAL_CALL" (global $EXPR_TRADITIONAL_CALL i32))

  ;; Import expression code generation for default value evaluation
  (import "codegen_expressions" "generate_expression" (func $generate_expression (param i32) (result i32)))

  ;; Default value generation state
  (global $defaults_generated (mut i32) (i32.const 0))
  (global $record_defaults_generated (mut i32) (i32.const 0))
  (global $current_function_params (mut i32) (i32.const 0))

  ;; Default value types
  (global $DEFAULT_TYPE_NONE i32 (i32.const 0))
  (global $DEFAULT_TYPE_LITERAL i32 (i32.const 1))
  (global $DEFAULT_TYPE_EXPRESSION i32 (i32.const 2))
  (global $DEFAULT_TYPE_CONSTRUCTOR i32 (i32.const 3))

  ;; Memory layout for default value tracking
  (global $DEFAULT_VALUE_BUFFER_START i32 (i32.const 98304))  ;; 96KB offset
  (global $DEFAULT_VALUE_BUFFER_SIZE i32 (i32.const 16384))   ;; 16KB buffer

  ;; Initialize default value generation system
  (func $init_default_value_generation (export "init_default_value_generation")
    ;; Reset statistics
    (global.set $defaults_generated (i32.const 0))
    (global.set $record_defaults_generated (i32.const 0))
    (global.set $current_function_params (i32.const 0))
  )

  ;; Generate default value evaluation at function call site
  ;; @param function_node: i32 - Function declaration AST node
  ;; @param call_node: i32 - Function call AST node
  ;; @param provided_args: i32 - Number of arguments provided in call
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_function_call_defaults (export "generate_function_call_defaults")
        (param $function_node i32) (param $call_node i32) (param $provided_args i32) (result i32)
    (local $param_count i32)
    (local $param_index i32)
    (local $param_node i32)
    (local $default_node i32)
    (local $success i32)

    ;; Validate function node
    (if (i32.ne (call $get_node_type (local.get $function_node)) (global.get $DECL_FUNCTION))
      (then (return (i32.const 0)))
    )

    ;; Get parameter count from function declaration
    (local.set $param_count (call $get_child_count (local.get $function_node)))

    ;; Generate default values for missing parameters
    (local.set $param_index (local.get $provided_args))
    (local.set $success (i32.const 1))

    (loop $process_defaults
      (if (i32.lt_u (local.get $param_index) (local.get $param_count))
        (then
          (local.set $param_node (call $get_child (local.get $function_node) (local.get $param_index)))

          ;; Check if parameter has default value
          (local.set $default_node (call $get_parameter_default_value (local.get $param_node)))

          (if (local.get $default_node)
            (then
              ;; Generate fresh evaluation of default value
              (local.set $success (call $generate_fresh_default_evaluation (local.get $default_node)))

              (if (i32.eqz (local.get $success))
                (then (return (i32.const 0)))
              )

              ;; Update statistics
              (global.set $defaults_generated
                (i32.add (global.get $defaults_generated) (i32.const 1)))
            )
            (else
              ;; Parameter has no default value and wasn't provided
              (return (i32.const 0))
            )
          )

          (local.set $param_index (i32.add (local.get $param_index) (i32.const 1)))
          (br $process_defaults)
        )
      )
    )

    (return (local.get $success))
  )

  ;; Generate record field default value evaluation at construction
  ;; @param record_node: i32 - Record declaration AST node
  ;; @param constructor_call: i32 - Record constructor call AST node
  ;; @param provided_fields: i32 - Number of fields provided in constructor
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_record_field_defaults (export "generate_record_field_defaults")
        (param $record_node i32) (param $constructor_call i32) (param $provided_fields i32) (result i32)
    (local $field_count i32)
    (local $field_index i32)
    (local $field_node i32)
    (local $default_node i32)
    (local $success i32)

    ;; Validate record node
    (if (i32.ne (call $get_node_type (local.get $record_node)) (global.get $DECL_RECORD))
      (then (return (i32.const 0)))
    )

    ;; Get field count from record declaration
    (local.set $field_count (call $get_child_count (local.get $record_node)))

    ;; Generate default values for missing fields
    (local.set $field_index (local.get $provided_fields))
    (local.set $success (i32.const 1))

    (loop $process_field_defaults
      (if (i32.lt_u (local.get $field_index) (local.get $field_count))
        (then
          (local.set $field_node (call $get_child (local.get $record_node) (local.get $field_index)))

          ;; Check if field has default value
          (local.set $default_node (call $get_field_default_value (local.get $field_node)))

          (if (local.get $default_node)
            (then
              ;; Generate fresh evaluation of default value
              (local.set $success (call $generate_fresh_default_evaluation (local.get $default_node)))

              (if (i32.eqz (local.get $success))
                (then (return (i32.const 0)))
              )

              ;; Update statistics
              (global.set $record_defaults_generated
                (i32.add (global.get $record_defaults_generated) (i32.const 1)))
            )
            (else
              ;; Field has no default value and wasn't provided
              (return (i32.const 0))
            )
          )

          (local.set $field_index (i32.add (local.get $field_index) (i32.const 1)))
          (br $process_field_defaults)
        )
      )
    )

    (return (local.get $success))
  )

  ;; Generate fresh evaluation of a default value expression
  ;; Ensures default values are re-evaluated each time they're used
  ;; @param default_expr: i32 - Default value expression AST node
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_fresh_default_evaluation (param $default_expr i32) (result i32)
    (local $expr_type i32)
    (local $success i32)

    ;; Get expression type
    (local.set $expr_type (call $get_node_type (local.get $default_expr)))

    ;; Generate fresh evaluation based on expression type
    (if (i32.eq (local.get $expr_type) (global.get $EXPR_INTEGER_LITERAL))
      (then (return (call $generate_literal_default (local.get $default_expr))))
    )

    (if (i32.eq (local.get $expr_type) (global.get $EXPR_FLOAT_LITERAL))
      (then (return (call $generate_literal_default (local.get $default_expr))))
    )

    (if (i32.eq (local.get $expr_type) (global.get $EXPR_STRING_LITERAL))
      (then (return (call $generate_literal_default (local.get $default_expr))))
    )

    (if (i32.eq (local.get $expr_type) (global.get $EXPR_BOOL_LITERAL))
      (then (return (call $generate_literal_default (local.get $default_expr))))
    )

    (if (i32.eq (local.get $expr_type) (global.get $EXPR_TRADITIONAL_CALL))
      (then (return (call $generate_constructor_default (local.get $default_expr))))
    )

    ;; For other expressions, use general expression generation
    (return (call $generate_expression_default (local.get $default_expr)))
  )

  ;; Generate literal default value (no fresh evaluation needed)
  ;; @param literal_node: i32 - Literal expression AST node
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_literal_default (param $literal_node i32) (result i32)
    ;; For literals, just generate the literal value directly
    ;; No fresh evaluation needed since literals are constant
    (return (call $generate_expression (local.get $literal_node)))
  )

  ;; Generate constructor call default value (fresh evaluation)
  ;; @param constructor_node: i32 - Constructor call AST node
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_constructor_default (param $constructor_node i32) (result i32)
    ;; Constructor calls need fresh evaluation each time
    ;; Generate the full constructor call expression
    (return (call $generate_expression (local.get $constructor_node)))
  )

  ;; Generate general expression default value (fresh evaluation)
  ;; @param expr_node: i32 - Expression AST node
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_expression_default (param $expr_node i32) (result i32)
    ;; General expressions need fresh evaluation
    ;; This handles variable references, function calls, etc.
    (return (call $generate_expression (local.get $expr_node)))
  )

  ;; Get default value from a function parameter node
  ;; @param param_node: i32 - Parameter AST node
  ;; @returns i32 - Default value node (0 if none)
  (func $get_parameter_default_value (param $param_node i32) (result i32)
    (local $child_count i32)
    (local $child_index i32)
    (local $child_node i32)

    ;; Look for default value in parameter children
    ;; Default values are typically the last child if present
    (local.set $child_count (call $get_child_count (local.get $param_node)))

    (if (i32.gt_u (local.get $child_count) (i32.const 2))
      (then
        ;; More than name and type, might have default value
        (local.set $child_node (call $get_child (local.get $param_node)
          (i32.sub (local.get $child_count) (i32.const 1))))

        ;; Check if this looks like a default value expression
        (if (call $is_default_value_expression (local.get $child_node))
          (then (return (local.get $child_node)))
        )
      )
    )

    (return (i32.const 0))  ;; No default value found
  )

  ;; Get default value from a record field node
  ;; @param field_node: i32 - Field AST node
  ;; @returns i32 - Default value node (0 if none)
  (func $get_field_default_value (param $field_node i32) (result i32)
    (local $child_count i32)
    (local $child_node i32)

    ;; Look for default value in field children
    (local.set $child_count (call $get_child_count (local.get $field_node)))

    (if (i32.gt_u (local.get $child_count) (i32.const 2))
      (then
        ;; More than name and type, might have default value
        (local.set $child_node (call $get_child (local.get $field_node)
          (i32.sub (local.get $child_count) (i32.const 1))))

        ;; Check if this looks like a default value expression
        (if (call $is_default_value_expression (local.get $child_node))
          (then (return (local.get $child_node)))
        )
      )
    )

    (return (i32.const 0))  ;; No default value found
  )

  ;; Check if a node represents a default value expression
  ;; @param node: i32 - AST node to check
  ;; @returns i32 - 1 if default value expression, 0 otherwise
  (func $is_default_value_expression (param $node i32) (result i32)
    (local $node_type i32)

    (local.set $node_type (call $get_node_type (local.get $node)))

    ;; Common default value expression types
    (if (i32.eq (local.get $node_type) (global.get $EXPR_INTEGER_LITERAL))
      (then (return (i32.const 1)))
    )

    (if (i32.eq (local.get $node_type) (global.get $EXPR_FLOAT_LITERAL))
      (then (return (i32.const 1)))
    )

    (if (i32.eq (local.get $node_type) (global.get $EXPR_STRING_LITERAL))
      (then (return (i32.const 1)))
    )

    (if (i32.eq (local.get $node_type) (global.get $EXPR_BOOL_LITERAL))
      (then (return (i32.const 1)))
    )

    (if (i32.eq (local.get $node_type) (global.get $EXPR_IDENTIFIER))
      (then (return (i32.const 1)))
    )

    (if (i32.eq (local.get $node_type) (global.get $EXPR_TRADITIONAL_CALL))
      (then (return (i32.const 1)))
    )

    (return (i32.const 0))
  )

  ;; Get default value generation statistics
  ;; @param stats_ptr: i32 - Pointer to write [function_defaults, record_defaults] statistics
  (func $get_default_value_stats (export "get_default_value_stats") (param $stats_ptr i32)
    (i32.store (local.get $stats_ptr) (global.get $defaults_generated))
    (i32.store (i32.add (local.get $stats_ptr) (i32.const 4)) (global.get $record_defaults_generated))
  )

  ;; Check if a function call needs default value generation
  ;; @param function_node: i32 - Function declaration AST node
  ;; @param call_node: i32 - Function call AST node
  ;; @returns i32 - Number of default values needed (0 if none)
  (func $count_required_defaults (export "count_required_defaults")
        (param $function_node i32) (param $call_node i32) (result i32)
    (local $param_count i32)
    (local $provided_args i32)
    (local $defaults_needed i32)

    ;; Get parameter count from function declaration
    (local.set $param_count (call $get_child_count (local.get $function_node)))

    ;; Get provided argument count from call
    (local.set $provided_args (call $get_child_count (local.get $call_node)))

    ;; Calculate defaults needed (if params > args)
    (if (i32.gt_u (local.get $param_count) (local.get $provided_args))
      (then
        (local.set $defaults_needed
          (i32.sub (local.get $param_count) (local.get $provided_args)))
      )
      (else
        (local.set $defaults_needed (i32.const 0))
      )
    )

    (return (local.get $defaults_needed))
  )

  ;; Validate that all required parameters have default values
  ;; @param function_node: i32 - Function declaration AST node
  ;; @param provided_args: i32 - Number of arguments provided
  ;; @returns i32 - 1 if valid (all missing params have defaults), 0 otherwise
  (func $validate_default_availability (export "validate_default_availability")
        (param $function_node i32) (param $provided_args i32) (result i32)
    (local $param_count i32)
    (local $param_index i32)
    (local $param_node i32)
    (local $default_node i32)

    (local.set $param_count (call $get_child_count (local.get $function_node)))
    (local.set $param_index (local.get $provided_args))

    ;; Check each missing parameter has a default value
    (loop $check_defaults
      (if (i32.lt_u (local.get $param_index) (local.get $param_count))
        (then
          (local.set $param_node (call $get_child (local.get $function_node) (local.get $param_index)))
          (local.set $default_node (call $get_parameter_default_value (local.get $param_node)))

          (if (i32.eqz (local.get $default_node))
            (then (return (i32.const 0)))  ;; Missing parameter has no default
          )

          (local.set $param_index (i32.add (local.get $param_index) (i32.const 1)))
          (br $check_defaults)
        )
      )
    )

    (return (i32.const 1))  ;; All missing parameters have defaults
  )

  ;; Export additional helper functions for testing
  (func $generate_fresh_default_evaluation_export (export "generate_fresh_default_evaluation") (param $default_expr i32) (result i32)
    (call $generate_fresh_default_evaluation (local.get $default_expr))
  )

  (func $is_valid_default_expression_export (export "is_valid_default_expression") (param $node i32) (result i32)
    (call $is_default_value_expression (local.get $node))
  )

  (func $get_defaults_generated_export (export "get_defaults_generated") (result i32)
    (global.get $defaults_generated)
  )

  (func $get_record_defaults_generated_export (export "get_record_defaults_generated") (result i32)
    (global.get $record_defaults_generated)
  )

  ;; Alias for function call defaults
  (func $generate_function_parameter_defaults_export (export "generate_function_parameter_defaults")
        (param $function_node i32) (param $call_node i32) (param $provided_args i32) (result i32)
    (call $generate_function_call_defaults (local.get $function_node) (local.get $call_node) (local.get $provided_args))
  )
)
