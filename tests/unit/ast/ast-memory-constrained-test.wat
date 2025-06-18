;; AST Memory Constrained Test
;; Test AST memory allocation within 64KB limits

(module $ast_memory_constrained_test
  ;; Import AST memory for this test
  (import "ast_memory" "memory" (memory 4))

  ;; Import AST memory functions
  (import "ast_memory" "init_memory_manager" (func $init_memory_manager))
  (import "ast_memory" "allocate" (func $allocate (param i32) (result i32)))

  ;; Import AST node creation
  (import "ast_node_core" "create_node" (func $create_node (param i32 i32) (result i32)))
  (import "ast_node_types" "PAT_WILDCARD" (global $PAT_WILDCARD i32))

  ;; Test function
  (func $run_constrained_test (export "run_constrained_test") (result i32)
    (local $node i32)
    (local $alloc_result i32)

    ;; Initialize AST memory manager in 64KB space
    (call $init_memory_manager)

    ;; Try to allocate small amount of memory
    (local.set $alloc_result (call $allocate (i32.const 16)))
    (if (i32.eqz (local.get $alloc_result))
      (then
        ;; Allocation failed - return error code 1
        (return (i32.const 1))
      )
    )

    ;; Try to create a simple node
    (local.set $node (call $create_node (global.get $PAT_WILDCARD) (i32.const 0)))
    (if (i32.eqz (local.get $node))
      (then
        ;; Node creation failed - return error code 2
        (return (i32.const 2))
      )
    )

    ;; Success
    (return (i32.const 0))
  )

  ;; Start function
  (func $_start (export "_start")
    (local $result i32)
    (local.set $result (call $run_constrained_test))
    (if (local.get $result)
      (then unreachable)  ;; Any non-zero result is failure
      (else)  ;; Success
    )
  )
)
