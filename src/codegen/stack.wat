;; Stack Management Utilities
;; Provides stack depth tracking and management for expression evaluation

(module $codegen_stack
  ;; Import memory for workspace
  (import "lexer_memory" "memory" (memory 1))

  ;; Import code generation core
  (import "codegen_core" "push_stack" (func $push_stack))
  (import "codegen_core" "pop_stack" (func $pop_stack))
  (import "codegen_core" "get_stack_depth" (func $get_stack_depth (result i32)))
  (import "codegen_core" "get_max_stack_depth" (func $get_max_stack_depth (result i32)))
  (import "codegen_core" "write_output" (func $write_output (param i32 i32) (result i32)))
  (import "codegen_core" "allocate_workspace" (func $allocate_workspace (param i32) (result i32)))

  ;; Stack operation tracking
  (global $stack_operations_count (mut i32) (i32.const 0))

  ;; Track stack operation for debugging/validation
  (func $track_stack_operation (export "track_stack_operation") (param $is_push i32)
    (if (local.get $is_push)
      (then (call $push_stack))
      (else (call $pop_stack)))

    (global.set $stack_operations_count
      (i32.add (global.get $stack_operations_count) (i32.const 1)))
  )

  ;; Generate stack validation code
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $generate_stack_validation (export "generate_stack_validation") (result i32)
    (local $comment_start i32)
    (local $success i32)
    (local $max_depth i32)
    (local $digit_char i32)

    ;; Allocate workspace for comment
    (local.set $comment_start (call $allocate_workspace (i32.const 128)))
    (if (i32.eqz (local.get $comment_start))
      (then (return (i32.const 0))))

    ;; Get maximum stack depth reached
    (local.set $max_depth (call $get_max_stack_depth))

    ;; Build comment string ";; Max stack depth: "
    (i32.store8 (local.get $comment_start) (i32.const 59))      ;; ';'
    (i32.store8 offset=1 (local.get $comment_start) (i32.const 59))   ;; ';'
    (i32.store8 offset=2 (local.get $comment_start) (i32.const 32))   ;; ' '
    (i32.store8 offset=3 (local.get $comment_start) (i32.const 77))   ;; 'M'
    (i32.store8 offset=4 (local.get $comment_start) (i32.const 97))   ;; 'a'
    (i32.store8 offset=5 (local.get $comment_start) (i32.const 120))  ;; 'x'
    (i32.store8 offset=6 (local.get $comment_start) (i32.const 32))   ;; ' '
    (i32.store8 offset=7 (local.get $comment_start) (i32.const 115))  ;; 's'
    (i32.store8 offset=8 (local.get $comment_start) (i32.const 116))  ;; 't'
    (i32.store8 offset=9 (local.get $comment_start) (i32.const 97))   ;; 'a'
    (i32.store8 offset=10 (local.get $comment_start) (i32.const 99))  ;; 'c'
    (i32.store8 offset=11 (local.get $comment_start) (i32.const 107)) ;; 'k'
    (i32.store8 offset=12 (local.get $comment_start) (i32.const 32))  ;; ' '
    (i32.store8 offset=13 (local.get $comment_start) (i32.const 100)) ;; 'd'
    (i32.store8 offset=14 (local.get $comment_start) (i32.const 101)) ;; 'e'
    (i32.store8 offset=15 (local.get $comment_start) (i32.const 112)) ;; 'p'
    (i32.store8 offset=16 (local.get $comment_start) (i32.const 116)) ;; 't'
    (i32.store8 offset=17 (local.get $comment_start) (i32.const 104)) ;; 'h'
    (i32.store8 offset=18 (local.get $comment_start) (i32.const 58))  ;; ':'
    (i32.store8 offset=19 (local.get $comment_start) (i32.const 32))  ;; ' '

    ;; Write comment prefix
    (local.set $success (call $write_output (local.get $comment_start) (i32.const 20)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write max depth (simplified - single digit for now)
    (local.set $digit_char (i32.add (i32.const 48) (local.get $max_depth))) ;; '0' + depth
    (i32.store8 (local.get $comment_start) (local.get $digit_char))
    (local.set $success (call $write_output (local.get $comment_start) (i32.const 1)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write newline
    (i32.store8 (local.get $comment_start) (i32.const 10))     ;; '\n'
    (call $write_output (local.get $comment_start) (i32.const 1))
  )

  ;; Reset stack tracking for new function
  (func $reset_stack_tracking (export "reset_stack_tracking")
    (global.set $stack_operations_count (i32.const 0))
    ;; Note: core stack depth is reset in codegen_core
  )

  ;; Validate balanced stack operations
  ;; @returns i32 - 1 if balanced, 0 if unbalanced
  (func $validate_stack_balance (export "validate_stack_balance") (result i32)
    (local $current_depth i32)

    (local.set $current_depth (call $get_stack_depth))

    ;; Stack should return to 0 at end of expression/function
    (if (result i32) (i32.eq (local.get $current_depth) (i32.const 0))
      (then (i32.const 1))
      (else (i32.const 0)))
  )

  ;; Generate stack depth comment for debugging
  ;; @param operation_name_ptr i32 - Name of operation
  ;; @param operation_name_len i32 - Length of operation name
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $generate_stack_comment (export "generate_stack_comment")
        (param $operation_name_ptr i32) (param $operation_name_len i32) (result i32)
    (local $comment_start i32)
    (local $success i32)
    (local $current_depth i32)
    (local $digit_char i32)

    ;; Allocate workspace
    (local.set $comment_start (call $allocate_workspace (i32.const 64)))
    (if (i32.eqz (local.get $comment_start))
      (then (return (i32.const 0))))

    ;; Get current stack depth
    (local.set $current_depth (call $get_stack_depth))

    ;; Build ";; " prefix
    (i32.store8 (local.get $comment_start) (i32.const 59))     ;; ';'
    (i32.store8 offset=1 (local.get $comment_start) (i32.const 59))  ;; ';'
    (i32.store8 offset=2 (local.get $comment_start) (i32.const 32))  ;; ' '

    ;; Write comment prefix
    (local.set $success (call $write_output (local.get $comment_start) (i32.const 3)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write operation name
    (local.set $success (call $write_output (local.get $operation_name_ptr) (local.get $operation_name_len)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Build " (depth: " string
    (i32.store8 (local.get $comment_start) (i32.const 32))     ;; ' '
    (i32.store8 offset=1 (local.get $comment_start) (i32.const 40))  ;; '('
    (i32.store8 offset=2 (local.get $comment_start) (i32.const 100)) ;; 'd'
    (i32.store8 offset=3 (local.get $comment_start) (i32.const 101)) ;; 'e'
    (i32.store8 offset=4 (local.get $comment_start) (i32.const 112)) ;; 'p'
    (i32.store8 offset=5 (local.get $comment_start) (i32.const 116)) ;; 't'
    (i32.store8 offset=6 (local.get $comment_start) (i32.const 104)) ;; 'h'
    (i32.store8 offset=7 (local.get $comment_start) (i32.const 58))  ;; ':'
    (i32.store8 offset=8 (local.get $comment_start) (i32.const 32))  ;; ' '

    ;; Write depth info
    (local.set $success (call $write_output (local.get $comment_start) (i32.const 9)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write current depth
    (local.set $digit_char (i32.add (i32.const 48) (local.get $current_depth)))
    (i32.store8 (local.get $comment_start) (local.get $digit_char))
    (local.set $success (call $write_output (local.get $comment_start) (i32.const 1)))
    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0))))

    ;; Write closing ")\n"
    (i32.store8 (local.get $comment_start) (i32.const 41))     ;; ')'
    (i32.store8 offset=1 (local.get $comment_start) (i32.const 10))  ;; '\n'
    (call $write_output (local.get $comment_start) (i32.const 2))
  )

  ;; Get stack statistics for debugging
  ;; @param stats_ptr i32 - Pointer to store stats (current_depth, max_depth, operations_count)
  (func $get_stack_stats (export "get_stack_stats") (param $stats_ptr i32)
    (i32.store (local.get $stats_ptr) (call $get_stack_depth))
    (i32.store offset=4 (local.get $stats_ptr) (call $get_max_stack_depth))
    (i32.store offset=8 (local.get $stats_ptr) (global.get $stack_operations_count))
  )
)
