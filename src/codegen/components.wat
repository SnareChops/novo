;; Component Code Generation Module
;; Generates WebAssembly Component Model compatible output
;; Phase 8.3: Component Code Generation

(module $codegen_components
  ;; Import memory for data storage
  (import "lexer_memory" "memory" (memory 1))

  ;; Import AST for tree traversal
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "ast_node_core" "get_child_count" (func $get_child_count (param i32) (result i32)))
  (import "ast_node_core" "get_child" (func $get_child (param i32 i32) (result i32)))
  (import "ast_node_core" "get_node_value" (func $get_node_value (param i32) (result i32)))

  ;; Import AST node types
  (import "ast_node_types" "DECL_COMPONENT" (global $DECL_COMPONENT i32))
  (import "ast_node_types" "DECL_INTERFACE" (global $DECL_INTERFACE i32))
  (import "ast_node_types" "DECL_IMPORT" (global $DECL_IMPORT i32))
  (import "ast_node_types" "DECL_EXPORT" (global $DECL_EXPORT i32))
  (import "ast_node_types" "DECL_FUNCTION" (global $DECL_FUNCTION i32))

  ;; Import binary encoder for WASM generation (component-compatible)
  (import "binary_encoder" "init_binary_encoder" (func $init_binary_encoder))
  (import "binary_encoder" "generate_binary_wasm_module" (func $generate_binary_wasm_module (param i32 i32 i32) (result i32)))
  (import "binary_encoder" "get_binary_output" (func $get_binary_output (param i32)))

  ;; Import codegen functions for core WASM generation
  (import "codegen_functions" "generate_function" (func $generate_function (param i32) (result i32)))
  (import "codegen_expressions" "generate_expression" (func $generate_expression (param i32) (result i32)))

  ;; Output buffer management
  (global $component_output_ptr (mut i32) (i32.const 0))
  (global $component_output_len (mut i32) (i32.const 0))
  (global $component_output_capacity (mut i32) (i32.const 0))

  ;; Component generation statistics
  (global $components_generated (mut i32) (i32.const 0))
  (global $interfaces_generated (mut i32) (i32.const 0))
  (global $component_imports_generated (mut i32) (i32.const 0))
  (global $component_exports_generated (mut i32) (i32.const 0))

  ;; Memory layout constants for output buffer
  (global $COMPONENT_BUFFER_START i32 (i32.const 65536))  ;; 64KB offset
  (global $COMPONENT_BUFFER_SIZE i32 (i32.const 32768))   ;; 32KB buffer

  ;; Initialize component code generation system
  (func $init_component_generation (export "init_component_generation")
    ;; Initialize binary encoder for component support
    (call $init_binary_encoder)

    ;; Initialize output buffer
    (global.set $component_output_ptr (global.get $COMPONENT_BUFFER_START))
    (global.set $component_output_len (i32.const 0))
    (global.set $component_output_capacity (global.get $COMPONENT_BUFFER_SIZE))

    ;; Reset statistics
    (global.set $components_generated (i32.const 0))
    (global.set $interfaces_generated (i32.const 0))
    (global.set $component_imports_generated (i32.const 0))
    (global.set $component_exports_generated (i32.const 0))
  )

  ;; Generate a complete component from AST
  ;; @param component_node: i32 - Component AST node
  ;; @param component_name_ptr: i32 - Component name string
  ;; @param component_name_len: i32 - Component name length
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_component (export "generate_component")
        (param $component_node i32) (param $component_name_ptr i32) (param $component_name_len i32) (result i32)
    (local $node_type i32)
    (local $child_count i32)
    (local $child_index i32)
    (local $child_node i32)
    (local $success i32)

    ;; Validate this is a component node
    (local.set $node_type (call $get_node_type (local.get $component_node)))
    (if (i32.ne (local.get $node_type) (global.get $DECL_COMPONENT))
      (then (return (i32.const 0)))  ;; Not a component node
    )

    ;; Generate component-compatible WASM module using existing binary encoder
    ;; Components compile to core WASM modules with specific import/export patterns
    (local.set $success (call $generate_binary_wasm_module
      (local.get $component_node)
      (local.get $component_name_ptr)
      (local.get $component_name_len)))

    ;; Update statistics
    (if (local.get $success)
      (then (global.set $components_generated
              (i32.add (global.get $components_generated) (i32.const 1))))
    )

    (return (local.get $success))
  )

  ;; Process a child node within a component
  ;; @param child_node: i32 - Child AST node
  ;; @returns i32 - Success (1) or failure (0)
  (func $process_component_child (param $child_node i32) (result i32)
    (local $node_type i32)

    (local.set $node_type (call $get_node_type (local.get $child_node)))

    ;; For now, all component children are processed as regular WASM constructs
    ;; Component model specifics will be handled at a higher level

    (if (i32.eq (local.get $node_type) (global.get $DECL_INTERFACE))
      (then (return (call $process_component_interface (local.get $child_node))))
    )

    (if (i32.eq (local.get $node_type) (global.get $DECL_IMPORT))
      (then (return (call $process_component_import (local.get $child_node))))
    )

    (if (i32.eq (local.get $node_type) (global.get $DECL_EXPORT))
      (then (return (call $process_component_export (local.get $child_node))))
    )

    (if (i32.eq (local.get $node_type) (global.get $DECL_FUNCTION))
      (then (return (call $generate_component_function (local.get $child_node))))
    )

    ;; Unknown or unsupported node type - skip but don't fail
    (return (i32.const 1))
  )

  ;; Process an interface within a component (simplified)
  ;; @param interface_node: i32 - Interface AST node
  ;; @returns i32 - Success (1) or failure (0)
  (func $process_component_interface (param $interface_node i32) (result i32)
    ;; For now, interfaces are tracked but not specially processed
    ;; Component model integration will handle interface instantiation

    ;; Update statistics
    (global.set $interfaces_generated
      (i32.add (global.get $interfaces_generated) (i32.const 1)))

    (return (i32.const 1))
  )

  ;; Process a component import declaration (simplified)
  ;; @param import_node: i32 - Import AST node
  ;; @returns i32 - Success (1) or failure (0)
  (func $process_component_import (param $import_node i32) (result i32)
    ;; Component imports will be handled by the component runtime
    ;; For now, track them for statistics

    ;; Update statistics
    (global.set $component_imports_generated
      (i32.add (global.get $component_imports_generated) (i32.const 1)))

    (return (i32.const 1))
  )

  ;; Process a component export declaration (simplified)
  ;; @param export_node: i32 - Export AST node
  ;; @returns i32 - Success (1) or failure (0)
  (func $process_component_export (param $export_node i32) (result i32)
    ;; Component exports will be handled by the component runtime
    ;; For now, track them for statistics

    ;; Update statistics
    (global.set $component_exports_generated
      (i32.add (global.get $component_exports_generated) (i32.const 1)))

    (return (i32.const 1))
  )

  ;; Generate a function within a component context
  ;; @param function_node: i32 - Function AST node
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_component_function (param $function_node i32) (result i32)
    ;; For component functions, generate standard WASM function
    ;; but with component model calling conventions
    (return (call $generate_function (local.get $function_node)))
  )

  ;; Get component generation output buffer
  ;; @param output_info_ptr: i32 - Pointer to write [ptr, len] output info
  (func $get_component_output (export "get_component_output") (param $output_info_ptr i32)
    ;; Use binary encoder output
    (call $get_binary_output (local.get $output_info_ptr))
  )

  ;; Get component generation statistics
  ;; @param stats_ptr: i32 - Pointer to write [components, interfaces, imports, exports] statistics
  (func $get_component_stats (export "get_component_stats") (param $stats_ptr i32)
    (i32.store (local.get $stats_ptr) (global.get $components_generated))
    (i32.store (i32.add (local.get $stats_ptr) (i32.const 4)) (global.get $interfaces_generated))
    (i32.store (i32.add (local.get $stats_ptr) (i32.const 8)) (global.get $component_imports_generated))
    (i32.store (i32.add (local.get $stats_ptr) (i32.const 12)) (global.get $component_exports_generated))
  )

  ;; Check if a node is a component-related declaration
  ;; @param node: i32 - AST node to check
  ;; @returns i32 - 1 if component-related, 0 otherwise
  (func $is_component_declaration (export "is_component_declaration") (param $node i32) (result i32)
    (local $node_type i32)

    (local.set $node_type (call $get_node_type (local.get $node)))

    ;; Check for component-related node types
    (if (i32.eq (local.get $node_type) (global.get $DECL_COMPONENT))
      (then (return (i32.const 1)))
    )

    (if (i32.eq (local.get $node_type) (global.get $DECL_INTERFACE))
      (then (return (i32.const 1)))
    )

    (return (i32.const 0))
  )

  ;; Generate entry point for component
  ;; Creates a standard _start function that initializes the component
  ;; @param component_node: i32 - Component AST node
  ;; @returns i32 - Success (1) or failure (0)
  (func $generate_component_entry_point (export "generate_component_entry_point")
        (param $component_node i32) (result i32)
    ;; TODO: Implement component-specific entry point generation
    ;; For now, assume standard WASM _start function
    ;; Component model may require different initialization patterns

    (return (i32.const 1))  ;; Success placeholder
  )
)
