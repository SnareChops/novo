;; Control Flow Code Generation
;; Handles code generation for control flow constructs (if/else, while, break, continue)

(module $codegen_control_flow
  ;; Import memory for code generation workspace
  (import "lexer_memory" "memory" (memory 1))

  ;; Import core code generation utilities
  (import "codegen_core" "write_output" (func $write_output (param i32 i32) (result i32)))
  (import "codegen_core" "push_stack" (func $push_stack))
  (import "codegen_core" "pop_stack" (func $pop_stack))

  ;; Import expression generation
  (import "codegen_expressions" "generate_expression" (func $generate_expression (param i32) (result i32)))

  ;; Import AST utilities
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "ast_node_core" "get_child_count" (func $get_child_count (param i32) (result i32)))
  (import "ast_node_core" "get_child" (func $get_child (param i32 i32) (result i32)))
  (import "ast_node_core" "get_node_value" (func $get_node_value (param i32) (result i32)))

  ;; Import AST control flow node types
  (import "ast_node_types" "CTRL_IF" (global $CTRL_IF i32))
  (import "ast_node_types" "CTRL_WHILE" (global $CTRL_WHILE i32))
  (import "ast_node_types" "CTRL_BREAK" (global $CTRL_BREAK i32))
  (import "ast_node_types" "CTRL_CONTINUE" (global $CTRL_CONTINUE i32))
  (import "ast_node_types" "CTRL_RETURN" (global $CTRL_RETURN i32))
  (import "ast_node_types" "EXPR_BLOCK" (global $EXPR_BLOCK i32))

  ;; Control flow generation state
  (global $block_depth (mut i32) (i32.const 0))
  (global $loop_depth (mut i32) (i32.const 0))
  (global $label_counter (mut i32) (i32.const 0))

  ;; Generate WASM code for a control flow construct
  ;; @param ctrl_node: i32 - AST node pointer for the control flow construct
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_control_flow (export "generate_control_flow") (param $ctrl_node i32) (result i32)
    (local $node_type i32)
    (local $result i32)

    ;; Get the node type to determine which control flow construct to generate
    (local.set $node_type (call $get_node_type (local.get $ctrl_node)))
    (local.set $result (i32.const 0))

    ;; Dispatch based on control flow type
    (if (i32.eq (local.get $node_type) (global.get $CTRL_IF))
      (then
        (local.set $result (call $generate_if_statement (local.get $ctrl_node)))
      )
      (else
        (if (i32.eq (local.get $node_type) (global.get $CTRL_WHILE))
          (then
            (local.set $result (call $generate_while_loop (local.get $ctrl_node)))
          )
          (else
            (if (i32.eq (local.get $node_type) (global.get $CTRL_BREAK))
              (then
                (local.set $result (call $generate_break (local.get $ctrl_node)))
              )
              (else
                (if (i32.eq (local.get $node_type) (global.get $CTRL_CONTINUE))
                  (then
                    (local.set $result (call $generate_continue (local.get $ctrl_node)))
                  )
                  (else
                    (if (i32.eq (local.get $node_type) (global.get $CTRL_RETURN))
                      (then
                        (local.set $result (call $generate_return (local.get $ctrl_node)))
                      )
                      (else
                        (if (i32.eq (local.get $node_type) (global.get $EXPR_BLOCK))
                          (then
                            (local.set $result (call $generate_block (local.get $ctrl_node)))
                          )
                          (else
                            ;; Unsupported control flow type
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

    (local.get $result)
  )

  ;; Generate WASM code for if statement
  ;; Structure: if (condition) { then_block } [else { else_block }]
  ;; @param if_node: i32 - AST node for if statement
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_if_statement (param $if_node i32) (result i32)
    (local $child_count i32)
    (local $condition i32)
    (local $then_block i32)
    (local $else_block i32)
    (local $result i32)

    ;; Get child count to determine if we have else block
    (local.set $child_count (call $get_child_count (local.get $if_node)))

    ;; Must have at least condition and then block
    (if (i32.lt_s (local.get $child_count) (i32.const 2))
      (then (return (i32.const 0)))
    )

    ;; Get child nodes
    (local.set $condition (call $get_child (local.get $if_node) (i32.const 0)))
    (local.set $then_block (call $get_child (local.get $if_node) (i32.const 1)))

    ;; Generate condition expression
    (local.set $result (call $generate_expression (local.get $condition)))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Start if block
    (drop (call $write_output (i32.const 0) (i32.const 2))) ;; "if"
    (drop (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"

    ;; Generate then block
    (drop (call $write_output (i32.const 16) (i32.const 4))) ;; "then"
    (drop (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"

    (local.set $result (call $generate_control_flow_or_expression (local.get $then_block)))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Generate else block if present
    (if (i32.ge_s (local.get $child_count) (i32.const 3))
      (then
        (local.set $else_block (call $get_child (local.get $if_node) (i32.const 2)))
        (drop (call $write_output (i32.const 32) (i32.const 4))) ;; "else"
        (drop (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"

        (local.set $result (call $generate_control_flow_or_expression (local.get $else_block)))
        (if (i32.eqz (local.get $result))
          (then (return (i32.const 0)))
        )
      )
    )

    ;; End if block
    (drop (call $write_output (i32.const 48) (i32.const 1))) ;; ")"
    (drop (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"

    (i32.const 1)
  )

  ;; Generate WASM code for while loop
  ;; Structure: while (condition) { body }
  ;; @param while_node: i32 - AST node for while loop
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_while_loop (param $while_node i32) (result i32)
    (local $child_count i32)
    (local $condition i32)
    (local $body i32)
    (local $result i32)
    (local $loop_label i32)

    ;; Get child nodes
    (local.set $child_count (call $get_child_count (local.get $while_node)))

    ;; Must have condition and body
    (if (i32.lt_s (local.get $child_count) (i32.const 2))
      (then (return (i32.const 0)))
    )

    (local.set $condition (call $get_child (local.get $while_node) (i32.const 0)))
    (local.set $body (call $get_child (local.get $while_node) (i32.const 1)))

    ;; Generate loop label
    (local.set $loop_label (global.get $label_counter))
    (global.set $label_counter (i32.add (global.get $label_counter) (i32.const 1)))

    ;; Start loop
    (drop (call $write_output (i32.const 64) (i32.const 4))) ;; "loop"
    (drop (call $write_output (i32.const 32) (i32.const 1))) ;; " "
    (drop (call $write_output (i32.const 80) (i32.const 5))) ;; "$loop"
    (call $write_number (local.get $loop_label))
    (drop (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"

    ;; Generate condition
    (local.set $result (call $generate_expression (local.get $condition)))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Branch if condition is false (exit loop)
    (drop (call $write_output (i32.const 96) (i32.const 5))) ;; "br_if"
    (drop (call $write_output (i32.const 32) (i32.const 1))) ;; " "
    (drop (call $write_output (i32.const 112) (i32.const 5))) ;; "$exit"
    (call $write_number (local.get $loop_label))
    (drop (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"
    (drop (call $write_output (i32.const 128) (i32.const 6))) ;; "i32.eqz"
    (drop (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"

    ;; Generate loop body
    (global.set $loop_depth (i32.add (global.get $loop_depth) (i32.const 1)))
    (local.set $result (call $generate_control_flow_or_expression (local.get $body)))
    (global.set $loop_depth (i32.sub (global.get $loop_depth) (i32.const 1)))

    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Branch back to loop start
    (drop (call $write_output (i32.const 144) (i32.const 2))) ;; "br"
    (drop (call $write_output (i32.const 32) (i32.const 1))) ;; " "
    (drop (call $write_output (i32.const 80) (i32.const 5))) ;; "$loop"
    (call $write_number (local.get $loop_label))
    (drop (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"

    ;; End loop (with exit label)
    (drop (call $write_output (i32.const 48) (i32.const 1))) ;; ")"
    (drop (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"

    (i32.const 1)
  )

  ;; Generate WASM code for break statement
  ;; @param break_node: i32 - AST node for break statement
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_break (param $break_node i32) (result i32)
    ;; Can only break if we're inside a loop
    (if (i32.eqz (global.get $loop_depth))
      (then (return (i32.const 0)))
    )

    ;; Generate break (branch to loop exit)
    (drop (call $write_output (i32.const 144) (i32.const 2))) ;; "br"
    (drop (call $write_output (i32.const 32) (i32.const 1))) ;; " "
    (drop (call $write_output (i32.const 112) (i32.const 5))) ;; "$exit"
    (call $write_number (i32.sub (global.get $label_counter) (i32.const 1)))
    (drop (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"

    (i32.const 1)
  )

  ;; Generate WASM code for continue statement
  ;; @param continue_node: i32 - AST node for continue statement
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_continue (param $continue_node i32) (result i32)
    ;; Can only continue if we're inside a loop
    (if (i32.eqz (global.get $loop_depth))
      (then (return (i32.const 0)))
    )

    ;; Generate continue (branch to loop start)
    (drop (call $write_output (i32.const 144) (i32.const 2))) ;; "br"
    (drop (call $write_output (i32.const 32) (i32.const 1))) ;; " "
    (drop (call $write_output (i32.const 80) (i32.const 5))) ;; "$loop"
    (call $write_number (i32.sub (global.get $label_counter) (i32.const 1)))
    (drop (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"

    (i32.const 1)
  )

  ;; Generate WASM code for return statement
  ;; @param return_node: i32 - AST node for return statement
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_return (param $return_node i32) (result i32)
    (local $child_count i32)
    (local $return_expr i32)
    (local $result i32)

    ;; Check if return has a value
    (local.set $child_count (call $get_child_count (local.get $return_node)))

    (if (i32.gt_s (local.get $child_count) (i32.const 0))
      (then
        ;; Generate return value expression
        (local.set $return_expr (call $get_child (local.get $return_node) (i32.const 0)))
        (local.set $result (call $generate_expression (local.get $return_expr)))
        (if (i32.eqz (local.get $result))
          (then (return (i32.const 0)))
        )
      )
    )

    ;; Generate return instruction
    (drop (call $write_output (i32.const 160) (i32.const 6))) ;; "return"
    (drop (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"

    (i32.const 1)
  )

  ;; Generate WASM code for block expression
  ;; @param block_node: i32 - AST node for block
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_block (param $block_node i32) (result i32)
    (local $child_count i32)
    (local $i i32)
    (local $child i32)
    (local $result i32)

    ;; Get child count
    (local.set $child_count (call $get_child_count (local.get $block_node)))

    ;; Start block
    (drop (call $write_output (i32.const 176) (i32.const 5))) ;; "block"
    (drop (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"

    ;; Generate each statement in the block
    (local.set $i (i32.const 0))
    (loop $stmt_loop
      (if (i32.lt_s (local.get $i) (local.get $child_count))
        (then
          (local.set $child (call $get_child (local.get $block_node) (local.get $i)))
          (local.set $result (call $generate_control_flow_or_expression (local.get $child)))
          (if (i32.eqz (local.get $result))
            (then (return (i32.const 0)))
          )
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $stmt_loop)
        )
      )
    )

    ;; End block
    (drop (call $write_output (i32.const 48) (i32.const 1))) ;; ")"
    (drop (call $write_output (i32.const 10) (i32.const 1))) ;; "\n"

    (i32.const 1)
  )

  ;; Helper function to generate either control flow or expression
  ;; @param node: i32 - AST node
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_control_flow_or_expression (param $node i32) (result i32)
    (local $node_type i32)

    (local.set $node_type (call $get_node_type (local.get $node)))

    ;; Check if it's a control flow node
    (if (i32.and
          (i32.ge_s (local.get $node_type) (i32.const 60))  ;; CTRL_* start at 60
          (i32.le_s (local.get $node_type) (i32.const 79))  ;; CTRL_* end at 79
        )
      (then
        (return (call $generate_control_flow (local.get $node)))
      )
    )

    ;; Otherwise it's an expression
    (call $generate_expression (local.get $node))
  )

  ;; Utility function to write a number to output
  ;; @param num: i32 - Number to write
  (func $write_number (param $num i32)
    ;; Simplified number writing (single digit only for now)
    (if (i32.lt_s (local.get $num) (i32.const 10))
      (then
        (i32.store8 (i32.const 200) (i32.add (i32.const 48) (local.get $num)))
        (drop (call $write_output (i32.const 200) (i32.const 1)))
      )
      (else
        ;; Multi-digit (simplified - just write "N" for now)
        (drop (call $write_output (i32.const 78) (i32.const 1))) ;; "N"
      )
    )
  )

  ;; Initialize control flow generation system
  (func $init_control_flow (export "init_control_flow")
    (global.set $block_depth (i32.const 0))
    (global.set $loop_depth (i32.const 0))
    (global.set $label_counter (i32.const 0))
  )

  ;; String constants for WASM control flow instructions
  (data (i32.const 0) "if")         ;; 0-1
  (data (i32.const 16) "then")      ;; 16-19
  (data (i32.const 32) "else")      ;; 32-35
  (data (i32.const 48) ")")         ;; 48
  (data (i32.const 64) "loop")      ;; 64-67
  (data (i32.const 80) "$loop")     ;; 80-84
  (data (i32.const 96) "br_if")     ;; 96-100
  (data (i32.const 112) "$exit")    ;; 112-116
  (data (i32.const 128) "i32.eqz")  ;; 128-134
  (data (i32.const 144) "br")       ;; 144-145
  (data (i32.const 160) "return")   ;; 160-165
  (data (i32.const 176) "block")    ;; 176-180
)
