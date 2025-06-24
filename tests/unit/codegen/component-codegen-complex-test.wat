;; Component Code Generation Complex Test
;; Tests component compilation with imports, exports, and interfaces

(module $component_codegen_complex_test
  ;; Import memory for data storage
  (import "memory" "memory" (memory 1))

  ;; Import component codegen
  (import "codegen_components" "init_component_generation" (func $init_component_generation))
  (import "codegen_components" "generate_component" (func $generate_component (param i32 i32 i32) (result i32)))
  (import "codegen_components" "get_component_output" (func $get_component_output (param i32)))
  (import "codegen_components" "get_component_stats" (func $get_component_stats (param i32)))

  ;; Import AST for testing
  (import "ast_declaration_creators" "create_decl_component" (func $create_decl_component (param i32 i32) (result i32)))
  (import "ast_declaration_creators" "create_decl_interface" (func $create_decl_interface (param i32 i32) (result i32)))
  (import "ast_declaration_creators" "create_decl_import" (func $create_decl_import (param i32 i32 i32 i32) (result i32)))
  (import "ast_declaration_creators" "create_decl_export" (func $create_decl_export (param i32 i32 i32 i32) (result i32)))
  (import "ast_declaration_creators" "create_decl_function" (func $create_decl_function (param i32 i32) (result i32)))
  (import "ast_node_core" "add_child" (func $add_child (param i32 i32) (result i32)))

  ;; Global test state
  (global $test_passed (mut i32) (i32.const 1))

  ;; Test helper: string constants
  (data (i32.const 1000) "wasi_component")
  (data (i32.const 1020) "io_interface")
  (data (i32.const 1040) "wasi:io")
  (data (i32.const 1060) "compute_fn")
  (data (i32.const 1080) "process")

  ;; Test complex component with imports and exports
  (func $test_complex_component_generation (export "test_complex_component_generation") (result i32)
    (local $component_node i32)
    (local $interface_node i32)
    (local $import_node i32)
    (local $export_node i32)
    (local $function_node i32)
    (local $success i32)
    (local $stats i32)

    ;; Initialize component generation
    (call $init_component_generation)

    ;; Create test component AST: wasi_component
    (local.set $component_node (call $create_decl_component (i32.const 1000) (i32.const 14)))

    ;; Add interface to component: io_interface
    (local.set $interface_node (call $create_decl_interface (i32.const 1020) (i32.const 12)))
    (drop (call $add_child (local.get $component_node) (local.get $interface_node)))

    ;; Add import to component: wasi:io (using placeholder strings for module/item)
    (local.set $import_node (call $create_decl_import
      (i32.const 1040) (i32.const 7)   ;; module: "wasi:io"
      (i32.const 1040) (i32.const 7))) ;; item: "wasi:io" (simplified)
    (drop (call $add_child (local.get $component_node) (local.get $import_node)))

    ;; Add export to component: compute_fn (using placeholder strings)
    (local.set $export_node (call $create_decl_export
      (i32.const 1060) (i32.const 10)  ;; external: "compute_fn"
      (i32.const 1060) (i32.const 10))) ;; internal: "compute_fn" (simplified)
    (drop (call $add_child (local.get $component_node) (local.get $export_node)))

    ;; Add function to component: process
    (local.set $function_node (call $create_decl_function (i32.const 1080) (i32.const 7)))
    (drop (call $add_child (local.get $component_node) (local.get $function_node)))

    ;; Generate component
    (local.set $success (call $generate_component
      (local.get $component_node)
      (i32.const 1000) (i32.const 14)))  ;; "wasi_component"

    (if (i32.eqz (local.get $success))
      (then
        (global.set $test_passed (i32.const 0))
        (return (i32.const 0))
      )
    )

    ;; Check statistics
    (local.set $stats (i32.const 2000))
    (call $get_component_stats (local.get $stats))

    ;; Should have generated:
    ;; 1 component, 1 interface, 1 import, 1 export
    (if (i32.ne (i32.load (local.get $stats)) (i32.const 1))  ;; components
      (then
        (global.set $test_passed (i32.const 0))
        (return (i32.const 0))
      )
    )

    (if (i32.ne (i32.load (i32.add (local.get $stats) (i32.const 4))) (i32.const 1))  ;; interfaces
      (then
        (global.set $test_passed (i32.const 0))
        (return (i32.const 0))
      )
    )

    (if (i32.ne (i32.load (i32.add (local.get $stats) (i32.const 8))) (i32.const 1))  ;; imports
      (then
        (global.set $test_passed (i32.const 0))
        (return (i32.const 0))
      )
    )

    (if (i32.ne (i32.load (i32.add (local.get $stats) (i32.const 12))) (i32.const 1))  ;; exports
      (then
        (global.set $test_passed (i32.const 0))
        (return (i32.const 0))
      )
    )

    ;; Test passed
    (return (i32.const 1))
  )

  ;; Test multiple components
  (func $test_multiple_components (export "test_multiple_components") (result i32)
    (local $component1 i32)
    (local $component2 i32)
    (local $success i32)
    (local $stats i32)

    ;; Initialize component generation
    (call $init_component_generation)

    ;; Generate first component
    (local.set $component1 (call $create_decl_component (i32.const 1000) (i32.const 14)))
    (local.set $success (call $generate_component
      (local.get $component1)
      (i32.const 1000) (i32.const 14)))

    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0)))
    )

    ;; Generate second component
    (local.set $component2 (call $create_decl_component (i32.const 1020) (i32.const 12)))
    (local.set $success (call $generate_component
      (local.get $component2)
      (i32.const 1020) (i32.const 12)))

    (if (i32.eqz (local.get $success))
      (then (return (i32.const 0)))
    )

    ;; Check statistics - should have 2 components
    (local.set $stats (i32.const 2000))
    (call $get_component_stats (local.get $stats))

    (if (i32.ne (i32.load (local.get $stats)) (i32.const 2))  ;; 2 components
      (then (return (i32.const 0)))
    )

    (return (i32.const 1))
  )

  ;; Main test function
  (func $run_test (export "run_test") (result i32)
    (local $result i32)

    ;; Reset test state
    (global.set $test_passed (i32.const 1))

    ;; Test 1: Complex component generation
    (local.set $result (call $test_complex_component_generation))
    (if (i32.eqz (local.get $result))
      (then (global.set $test_passed (i32.const 0)))
    )

    ;; Test 2: Multiple components
    (local.set $result (call $test_multiple_components))
    (if (i32.eqz (local.get $result))
      (then (global.set $test_passed (i32.const 0)))
    )

    (return (global.get $test_passed))
  )
)
