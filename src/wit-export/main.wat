;; WIT Export Main Module
;; Orchestrates WIT generation from Novo AST

(module
  ;; Import the generator functions
  (import "wit_export_generator" "init_output_buffer" (func $init_generator))
  (import "wit_export_generator" "generate_wit_file" (func $generate_wit_file (param i32) (result i32)))
  (import "wit_export_generator" "generate_component_wit" (func $generate_component_wit (param i32) (result i32)))
  (import "wit_export_generator" "generate_interface_wit" (func $generate_interface_wit (param i32) (result i32)))
  (import "wit_export_generator" "get_output_buffer" (func $get_output_buffer (result i32)))
  (import "wit_export_generator" "get_output_length" (func $get_output_length (result i32)))
  (import "wit_export_generator" "reset_output" (func $reset_output))

  ;; Import type mapping functions
  (import "wit_export_type_mapping" "map_type_to_wit" (func $map_type_to_wit (param i32) (result i32)))

  ;; Export main WIT generation functions
  (func $init (export "init")
    (call $init_generator))

  ;; Generate WIT file from AST root
  ;; @param $ast_root i32 - Pointer to AST root node
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $export_wit_file (export "export_wit_file") (param $ast_root i32) (result i32)
    (call $generate_wit_file (local.get $ast_root)))

  ;; Generate WIT for a single component
  ;; @param $component_node i32 - Pointer to component AST node
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $export_component_wit (export "export_component_wit") (param $component_node i32) (result i32)
    (call $generate_component_wit (local.get $component_node)))

  ;; Generate WIT for a single interface
  ;; @param $interface_node i32 - Pointer to interface AST node
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $export_interface_wit (export "export_interface_wit") (param $interface_node i32) (result i32)
    (call $generate_interface_wit (local.get $interface_node)))

  ;; Get the generated WIT output buffer
  ;; @returns i32 - Pointer to output buffer
  (func $get_wit_output (export "get_wit_output") (result i32)
    (call $get_output_buffer))

  ;; Get the length of generated WIT output
  ;; @returns i32 - Length of output in buffer
  (func $get_wit_length (export "get_wit_length") (result i32)
    (call $get_output_length))

  ;; Reset the WIT output buffer
  (func $reset_wit_output (export "reset_wit_output")
    (call $reset_output))

  ;; Convert a type node to WIT format
  ;; @param $type_node i32 - Pointer to type AST node
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $convert_type_to_wit (export "convert_type_to_wit") (param $type_node i32) (result i32)
    (call $map_type_to_wit (local.get $type_node)))
)
