;; Expression Code Generation
;; Handles code generation for all types of expressions in Novo

(module $codegen_expressions
  ;; Import memory for code generation workspace
  (import "lexer_memory" "memory" (memory 1))

  ;; Import core code generation utilities
  (import "codegen_core" "write_output" (func $write_output (param i32 i32) (result i32)))
  (import "codegen_core" "push_stack" (func $push_stack))
  (import "codegen_core" "pop_stack" (func $pop_stack))
  (import "codegen_core" "get_wasm_type_string" (func $get_wasm_type_string (param i32 i32)))
  (import "codegen_core" "lookup_local_var" (func $lookup_local_var (param i32 i32) (result i32)))

  ;; Import AST utilities
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "ast_node_core" "get_child_count" (func $get_child_count (param i32) (result i32)))
  (import "ast_node_core" "get_child" (func $get_child (param i32 i32) (result i32)))
  (import "ast_node_core" "get_node_value" (func $get_node_value (param i32) (result i32)))

  ;; Import AST node type constants
  (import "ast_node_types" "EXPR_INTEGER_LITERAL" (global $EXPR_INTEGER_LITERAL i32))
  (import "ast_node_types" "EXPR_FLOAT_LITERAL" (global $EXPR_FLOAT_LITERAL i32))
  (import "ast_node_types" "EXPR_BOOL_LITERAL" (global $EXPR_BOOL_LITERAL i32))
  (import "ast_node_types" "EXPR_STRING_LITERAL" (global $EXPR_STRING_LITERAL i32))
  (import "ast_node_types" "EXPR_IDENTIFIER" (global $EXPR_IDENTIFIER i32))
  (import "ast_node_types" "EXPR_TRADITIONAL_CALL" (global $EXPR_TRADITIONAL_CALL i32))
  (import "ast_node_types" "EXPR_WAT_STYLE_CALL" (global $EXPR_WAT_STYLE_CALL i32))
  (import "ast_node_types" "EXPR_META_CALL" (global $EXPR_META_CALL i32))
  (import "ast_node_types" "EXPR_ADD" (global $EXPR_ADD i32))
  (import "ast_node_types" "EXPR_SUB" (global $EXPR_SUB i32))
  (import "ast_node_types" "EXPR_MUL" (global $EXPR_MUL i32))
  (import "ast_node_types" "EXPR_DIV" (global $EXPR_DIV i32))
  (import "ast_node_types" "EXPR_MOD" (global $EXPR_MOD i32))
  (import "ast_node_types" "EXPR_BLOCK" (global $EXPR_BLOCK i32))

  ;; Import type checker for type information
  (import "typechecker_main" "get_node_type_info" (func $get_node_type_info (param i32) (result i32)))
  (import "typechecker_main" "TYPE_I32" (global $TYPE_I32 i32))
  (import "typechecker_main" "TYPE_I64" (global $TYPE_I64 i32))
  (import "typechecker_main" "TYPE_F32" (global $TYPE_F32 i32))
  (import "typechecker_main" "TYPE_F64" (global $TYPE_F64 i32))
  (import "typechecker_main" "TYPE_BOOL" (global $TYPE_BOOL i32))
  (import "typechecker_main" "TYPE_STRING" (global $TYPE_STRING i32))

  ;; Expression generation workspace
  (global $EXPR_BUFFER_START i32 (i32.const 43008))  ;; After local var table
  (global $EXPR_BUFFER_SIZE i32 (i32.const 4096))
  (global $expr_buffer_pos (mut i32) (i32.const 0))

  ;; Generate WASM code for an expression AST node
  ;; @param expr_node: i32 - AST node pointer for the expression
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_expression (export "generate_expression") (param $expr_node i32) (result i32)
    (local $node_type i32)
    (local $result i32)

    ;; Get the node type to determine how to generate code
    (local.set $node_type (call $get_node_type (local.get $expr_node)))
    (local.set $result (i32.const 0))

    ;; Dispatch based on expression type
    (if (i32.eq (local.get $node_type) (global.get $EXPR_INTEGER_LITERAL))
      (then
        (local.set $result (call $generate_integer_literal (local.get $expr_node)))
      )
      (else
        (if (i32.eq (local.get $node_type) (global.get $EXPR_FLOAT_LITERAL))
          (then
            (local.set $result (call $generate_float_literal (local.get $expr_node)))
          )
          (else
            (if (i32.eq (local.get $node_type) (global.get $EXPR_BOOL_LITERAL))
              (then
                (local.set $result (call $generate_bool_literal (local.get $expr_node)))
              )
              (else
                (if (i32.eq (local.get $node_type) (global.get $EXPR_STRING_LITERAL))
                  (then
                    (local.set $result (call $generate_string_literal (local.get $expr_node)))
                  )
                  (else
                    (if (i32.eq (local.get $node_type) (global.get $EXPR_IDENTIFIER))
                      (then
                        (local.set $result (call $generate_identifier (local.get $expr_node)))
                      )
                      (else
                        (if (i32.eq (local.get $node_type) (global.get $EXPR_ADD))
                          (then
                            (local.set $result (call $generate_binary_op (local.get $expr_node) (i32.const 0))) ;; 0 = add
                          )
                          (else
                            (if (i32.eq (local.get $node_type) (global.get $EXPR_SUB))
                              (then
                                (local.set $result (call $generate_binary_op (local.get $expr_node) (i32.const 1))) ;; 1 = sub
                              )
                              (else
                                (if (i32.eq (local.get $node_type) (global.get $EXPR_MUL))
                                  (then
                                    (local.set $result (call $generate_binary_op (local.get $expr_node) (i32.const 2))) ;; 2 = mul
                                  )
                                  (else
                                    (if (i32.eq (local.get $node_type) (global.get $EXPR_DIV))
                                      (then
                                        (local.set $result (call $generate_binary_op (local.get $expr_node) (i32.const 3))) ;; 3 = div
                                      )
                                      (else
                                        (if (i32.eq (local.get $node_type) (global.get $EXPR_TRADITIONAL_CALL))
                                          (then
                                            (local.set $result (call $generate_function_call (local.get $expr_node)))
                                          )
                                          (else
                                            (if (i32.eq (local.get $node_type) (global.get $EXPR_WAT_STYLE_CALL))
                                              (then
                                                (local.set $result (call $generate_wat_call (local.get $expr_node)))
                                              )
                                              (else
                                                ;; Unsupported expression type
                                                (local.set $result (i32.const 0))
                                              )
                                            )
                                          )
                                        )
                                      )
                                    )
                                  )
                                )
                              )
                            )
                          )
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    )

    (local.get $result)
  )

  ;; Generate WASM code for integer literal
  ;; @param node: i32 - AST node for integer literal
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_integer_literal (param $node i32) (result i32)
    (local $value_ptr i32)
    (local $value_len i32)
    (local $i i32)
    (local $char i32)

    ;; Get the integer value string from the node
    (local.set $value_ptr (call $get_node_value (local.get $node)))

    ;; Calculate string length
    (local.set $value_len (i32.const 0))
    (local.set $i (local.get $value_ptr))
    (loop $len_loop
      (local.set $char (i32.load8_u (local.get $i)))
      (br_if $len_loop (i32.eqz (local.get $char)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (local.set $value_len (i32.add (local.get $value_len) (i32.const 1)))
      (br $len_loop)
    )

    ;; Write i32.const instruction
    (drop (call $write_output (i32.const 0) (i32.const 9))) ;; "i32.const"
    (drop (call $write_output (i32.const 32) (i32.const 1))) ;; " "
    (drop (call $write_output (local.get $value_ptr) (local.get $value_len)))
    (drop (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"

    ;; Update stack depth
    (call $push_stack)

    (i32.const 1)
  )

  ;; Generate WASM code for float literal
  ;; @param node: i32 - AST node for float literal
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_float_literal (param $node i32) (result i32)
    (local $value_ptr i32)
    (local $value_len i32)
    (local $i i32)
    (local $char i32)

    ;; Get the float value string from the node
    (local.set $value_ptr (call $get_node_value (local.get $node)))

    ;; Calculate string length
    (local.set $value_len (i32.const 0))
    (local.set $i (local.get $value_ptr))
    (loop $len_loop
      (local.set $char (i32.load8_u (local.get $i)))
      (br_if $len_loop (i32.eqz (local.get $char)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (local.set $value_len (i32.add (local.get $value_len) (i32.const 1)))
      (br $len_loop)
    )

    ;; Write f32.const instruction (assume f32 for now)
    (drop (call $write_output (i32.const 16) (i32.const 9))) ;; "f32.const"
    (drop (call $write_output (i32.const 32) (i32.const 1))) ;; " "
    (drop (call $write_output (local.get $value_ptr) (local.get $value_len)))
    (drop (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"

    ;; Update stack depth
    (call $push_stack)

    (i32.const 1)
  )

  ;; Generate WASM code for boolean literal
  ;; @param node: i32 - AST node for boolean literal
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_bool_literal (param $node i32) (result i32)
    (local $value_ptr i32)
    (local $is_true i32)

    ;; Get the boolean value string from the node
    (local.set $value_ptr (call $get_node_value (local.get $node)))

    ;; Check if it's "true" (assuming first char is 't' for true, 'f' for false)
    (local.set $is_true (i32.eq (i32.load8_u (local.get $value_ptr)) (i32.const 116))) ;; 't'

    ;; Write i32.const 1 for true, 0 for false
    (drop (call $write_output (i32.const 0) (i32.const 9))) ;; "i32.const"
    (drop (call $write_output (i32.const 32) (i32.const 1))) ;; " "
    (if (local.get $is_true)
      (then
        (drop (call $write_output (i32.const 49) (i32.const 1))) ;; "1"
      )
      (else
        (drop (call $write_output (i32.const 48) (i32.const 1))) ;; "0"
      )
    )
    (drop (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"

    ;; Update stack depth
    (call $push_stack)

    (i32.const 1)
  )

  ;; Generate WASM code for string literal (placeholder - more complex)
  ;; @param node: i32 - AST node for string literal
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_string_literal (param $node i32) (result i32)
    ;; For now, just push a string pointer (simplified)
    (drop (call $write_output (i32.const 0) (i32.const 9))) ;; "i32.const"
    (drop (call $write_output (i32.const 32) (i32.const 1))) ;; " "
    (drop (call $write_output (i32.const 48) (i32.const 1))) ;; "0" (placeholder string ptr)
    (drop (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"

    ;; Update stack depth
    (call $push_stack)

    (i32.const 1)
  )

  ;; Generate WASM code for identifier (variable access)
  ;; @param node: i32 - AST node for identifier
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_identifier (param $node i32) (result i32)
    (local $name_ptr i32)
    (local $name_len i32)
    (local $var_index i32)
    (local $i i32)
    (local $char i32)

    ;; Get the identifier name from the node
    (local.set $name_ptr (call $get_node_value (local.get $node)))

    ;; Calculate string length
    (local.set $name_len (i32.const 0))
    (local.set $i (local.get $name_ptr))
    (loop $len_loop
      (local.set $char (i32.load8_u (local.get $i)))
      (br_if $len_loop (i32.eqz (local.get $char)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (local.set $name_len (i32.add (local.get $name_len) (i32.const 1)))
      (br $len_loop)
    )

    ;; Look up the variable in the local variable table
    (local.set $var_index (call $lookup_local_var (local.get $name_ptr) (local.get $name_len)))

    ;; If variable found, generate local.get
    (if (i32.ge_s (local.get $var_index) (i32.const 0))
      (then
        (drop (call $write_output (i32.const 64) (i32.const 9))) ;; "local.get"
        (drop (call $write_output (i32.const 32) (i32.const 1))) ;; " "
        (call $write_number (local.get $var_index))
        (drop (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"

        ;; Update stack depth
        (call $push_stack)

        (return (i32.const 1))
      )
    )

    ;; Variable not found - could be global or function name
    ;; For now, just fail
    (i32.const 0)
  )

  ;; Generate WASM code for binary operations
  ;; @param node: i32 - AST node for binary operation
  ;; @param op_type: i32 - Operation type (0=add, 1=sub, 2=mul, 3=div)
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_binary_op (param $node i32) (param $op_type i32) (result i32)
    (local $left_child i32)
    (local $right_child i32)
    (local $result i32)

    ;; Get left and right operands
    (local.set $left_child (call $get_child (local.get $node) (i32.const 0)))
    (local.set $right_child (call $get_child (local.get $node) (i32.const 1)))

    ;; Generate code for left operand
    (local.set $result (call $generate_expression (local.get $left_child)))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Generate code for right operand
    (local.set $result (call $generate_expression (local.get $right_child)))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Generate the operation instruction (assume i32 for now)
    (if (i32.eq (local.get $op_type) (i32.const 0))
      (then
        (drop (call $write_output (i32.const 96) (i32.const 7))) ;; "i32.add"
      )
      (else
        (if (i32.eq (local.get $op_type) (i32.const 1))
          (then
            (drop (call $write_output (i32.const 104) (i32.const 7))) ;; "i32.sub"
          )
          (else
            (if (i32.eq (local.get $op_type) (i32.const 2))
              (then
                (drop (call $write_output (i32.const 112) (i32.const 7))) ;; "i32.mul"
              )
              (else
                (if (i32.eq (local.get $op_type) (i32.const 3))
                  (then
                    (drop (call $write_output (i32.const 120) (i32.const 9))) ;; "i32.div_s"
                  )
                )
              )
            )
          )
        )
      )
    )
    (drop (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"

    ;; Pop two stack items, push one result
    (call $pop_stack)
    ;; One item remains on stack (the result)

    (i32.const 1)
  )

  ;; Generate WASM code for traditional function calls
  ;; @param node: i32 - AST node for function call
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_function_call (param $node i32) (result i32)
    (local $func_name_node i32)
    (local $func_name_ptr i32)
    (local $func_name_len i32)
    (local $arg_count i32)
    (local $i i32)
    (local $arg_node i32)
    (local $result i32)
    (local $char i32)

    ;; Get function name (first child)
    (local.set $func_name_node (call $get_child (local.get $node) (i32.const 0)))
    (local.set $func_name_ptr (call $get_node_value (local.get $func_name_node)))

    ;; Calculate function name length
    (local.set $func_name_len (i32.const 0))
    (local.set $i (local.get $func_name_ptr))
    (loop $len_loop
      (local.set $char (i32.load8_u (local.get $i)))
      (br_if $len_loop (i32.eqz (local.get $char)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (local.set $func_name_len (i32.add (local.get $func_name_len) (i32.const 1)))
      (br $len_loop)
    )

    ;; Get argument count (total children - 1 for function name)
    (local.set $arg_count (i32.sub (call $get_child_count (local.get $node)) (i32.const 1)))

    ;; Generate code for each argument
    (local.set $i (i32.const 1)) ;; Start from second child (first argument)
    (loop $arg_loop
      (if (i32.lt_s (local.get $i) (i32.add (local.get $arg_count) (i32.const 1)))
        (then
          (local.set $arg_node (call $get_child (local.get $node) (local.get $i)))
          (local.set $result (call $generate_expression (local.get $arg_node)))
          (if (i32.eqz (local.get $result))
            (then (return (i32.const 0)))
          )
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $arg_loop)
        )
      )
    )

    ;; Generate the call instruction
    (drop (call $write_output (i32.const 130) (i32.const 4))) ;; "call"
    (drop (call $write_output (i32.const 32) (i32.const 1))) ;; " "
    (drop (call $write_output (local.get $func_name_ptr) (local.get $func_name_len)))
    (drop (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"

    ;; Pop arguments from stack, push result
    (local.set $i (i32.const 0))
    (loop $pop_loop
      (if (i32.lt_s (local.get $i) (local.get $arg_count))
        (then
          (call $pop_stack)
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $pop_loop)
        )
      )
    )
    (call $push_stack) ;; Push function result

    (i32.const 1)
  )

  ;; Generate WASM code for WAT-style function calls (placeholder)
  ;; @param node: i32 - AST node for WAT-style call
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_wat_call (param $node i32) (result i32)
    ;; Similar to traditional call but different syntax
    ;; For now, delegate to traditional call
    (call $generate_function_call (local.get $node))
  )

  ;; Utility function to write a number to output
  ;; @param num: i32 - Number to write
  (func $write_number (param $num i32)
    (local $temp i32)
    (local $digits i32)
    (local $digit_count i32)
    (local $i i32)

    ;; Handle special case of 0
    (if (i32.eqz (local.get $num))
      (then
        (call $write_output (i32.const 48) (i32.const 1)) ;; "0"
        (return)
      )
    )

    ;; Convert number to string (simplified - only handles positive numbers)
    (local.set $temp (local.get $num))
    (local.set $digit_count (i32.const 0))

    ;; Count digits
    (loop $count_loop
      (if (i32.gt_s (local.get $temp) (i32.const 0))
        (then
          (local.set $temp (i32.div_s (local.get $temp) (i32.const 10)))
          (local.set $digit_count (i32.add (local.get $digit_count) (i32.const 1)))
          (br $count_loop)
        )
      )
    )

    ;; Write digits (simplified approach)
    (if (i32.lt_s (local.get $num) (i32.const 10))
      (then
        ;; Single digit
        (i32.store8 (global.get $EXPR_BUFFER_START)
          (i32.add (i32.const 48) (local.get $num)))
        (drop (call $write_output (global.get $EXPR_BUFFER_START) (i32.const 1)))
      )
      (else
        ;; Multi-digit (simplified - just write "N" for now)
        (drop (call $write_output (i32.const 78) (i32.const 1))) ;; "N"
      )
    )
  )

  ;; Initialize expression generation system
  (func $init_expressions (export "init_expressions")
    (global.set $expr_buffer_pos (i32.const 0))
  )

  ;; String constants for WASM instructions
  (data (i32.const 0) "i32.const")      ;; 0-8
  (data (i32.const 16) "f32.const")     ;; 16-24
  (data (i32.const 32) " ")             ;; 32
  (data (i32.const 48) "0")             ;; 48
  (data (i32.const 49) "1")             ;; 49
  (data (i32.const 64) "local.get")     ;; 64-72
  (data (i32.const 78) "N")             ;; 78
  (data (i32.const 96) "i32.add")       ;; 96-102
  (data (i32.const 104) "i32.sub")      ;; 104-110
  (data (i32.const 112) "i32.mul")      ;; 112-118
  (data (i32.const 120) "i32.div_s")    ;; 120-128
  (data (i32.const 130) "call")         ;; 130-133
)
