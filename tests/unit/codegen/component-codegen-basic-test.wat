;; Component Code Generation Basic Test
;; Tests basic component compilation functionality

(module $component_codegen_basic_test
  ;; Import memory for data storage
  (import "memory" "memory" (memory 1))

  ;; Import component codegen
  (import "codegen_components" "init_component_generation" (func $init_component_generation))
  (import "codegen_components" "generate_component" (func $generate_component (param i32 i32 i32) (result i32)))
  (import "codegen_components" "get_component_output" (func $get_component_output (param i32)))
  (import "codegen_components" "get_component_stats" (func $get_component_stats (param i32)))
  (import "codegen_components" "is_component_declaration" (func $is_component_declaration (param i32) (result i32)))

  ;; Import AST for testing
  (import "ast_declaration_creators" "create_decl_component" (func $create_decl_component (param i32 i32) (result i32)))
  (import "ast_declaration_creators" "create_decl_function" (func $create_decl_function (param i32 i32) (result i32)))
  (import "ast_node_core" "add_child" (func $add_child (param i32 i32) (result i32)))
  (import "ast_node_types" "DECL_COMPONENT" (global $DECL_COMPONENT i32))

  ;; Global test state
  (global $test_passed (mut i32) (i32.const 1))

  ;; Test helper: string constants
  (data (i32.const 1000) "test_component")
  (data (i32.const 1020) "compute")

  ;; Test basic component generation
  (func $test_basic_component_generation (export "test_basic_component_generation") (result i32)
    (local $component_node i32)
    (local $function_node i32)
    (local $success i32)
    (local $output_info i32)
    (local $stats i32)
    (local $is_component i32)

    ;; Initialize component generation
    (call $init_component_generation)

    ;; Create test component AST
    (local.set $component_node (call $create_decl_component (i32.const 1000) (i32.const 14)))  ;; "test_component"

    ;; Test is_component_declaration
    (local.set $is_component (call $is_component_declaration (local.get $component_node)))
    (if (i32.eqz (local.get $is_component))
      (then
        (global.set $test_passed (i32.const 0))
        (return (i32.const 0))
      )
    )

    ;; Create a simple function inside the component
    (local.set $function_node (call $create_decl_function (i32.const 1020) (i32.const 7)))  ;; "compute"
    (drop (call $add_child (local.get $component_node) (local.get $function_node)))

    ;; Generate component
    (local.set $success (call $generate_component
      (local.get $component_node)
      (i32.const 1000) (i32.const 14)))  ;; "test_component"

    (if (i32.eqz (local.get $success))
      (then
        (global.set $test_passed (i32.const 0))
        (return (i32.const 0))
      )
    )

    ;; Check output exists
    (local.set $output_info (i32.const 2000))
    (call $get_component_output (local.get $output_info))

    ;; Output should have non-zero length
    (if (i32.eqz (i32.load (i32.add (local.get $output_info) (i32.const 4))))
      (then
        (global.set $test_passed (i32.const 0))
        (return (i32.const 0))
      )
    )

    ;; Check statistics
    (local.set $stats (i32.const 2100))
    (call $get_component_stats (local.get $stats))

    ;; Should have generated 1 component
    (if (i32.ne (i32.load (local.get $stats)) (i32.const 1))
      (then
        (global.set $test_passed (i32.const 0))
        (return (i32.const 0))
      )
    )

    ;; Test passed
    (return (i32.const 1))
  )

  ;; Test component detection
  (func $test_component_detection (export "test_component_detection") (result i32)
    (local $component_node i32)
    (local $function_node i32)
    (local $is_component i32)

    ;; Create component node
    (local.set $component_node (call $create_decl_component (i32.const 1000) (i32.const 14)))
    (local.set $is_component (call $is_component_declaration (local.get $component_node)))
    (if (i32.eqz (local.get $is_component))
      (then (return (i32.const 0)))
    )

    ;; Create function node (should not be detected as component)
    (local.set $function_node (call $create_decl_function (i32.const 1020) (i32.const 7)))
    (local.set $is_component (call $is_component_declaration (local.get $function_node)))
    (if (local.get $is_component)
      (then (return (i32.const 0)))  ;; Should return false for non-component
    )

    (return (i32.const 1))
  )

  ;; Main test function
  (func $run_test (export "run_test") (result i32)
    (local $result i32)

    ;; Reset test state
    (global.set $test_passed (i32.const 1))

    ;; Test 1: Basic component generation
    (local.set $result (call $test_basic_component_generation))
    (if (i32.eqz (local.get $result))
      (then (global.set $test_passed (i32.const 0)))
    )

    ;; Test 2: Component detection
    (local.set $result (call $test_component_detection))
    (if (i32.eqz (local.get $result))
      (then (global.set $test_passed (i32.const 0)))
    )

    (return (global.get $test_passed))
  )
)
