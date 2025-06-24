;; Novo AST Main Module
;; Main orchestration module that brings together all AST components
;; Provides the primary interface for AST operations and initialization

(module $novo_ast
  ;; Memory for storing AST nodes and their data - 4 pages = 256KB
  (import "memory" "memory" (memory 1))

  ;; Import all node type constants
  (import "ast_node_types" "TYPE_PRIMITIVE" (global $TYPE_PRIMITIVE i32))
  (import "ast_node_types" "TYPE_LIST" (global $TYPE_LIST i32))
  (import "ast_node_types" "TYPE_OPTION" (global $TYPE_OPTION i32))
  (import "ast_node_types" "TYPE_RESULT" (global $TYPE_RESULT i32))
  (import "ast_node_types" "TYPE_TUPLE" (global $TYPE_TUPLE i32))
  (import "ast_node_types" "TYPE_RECORD" (global $TYPE_RECORD i32))
  (import "ast_node_types" "TYPE_VARIANT" (global $TYPE_VARIANT i32))
  (import "ast_node_types" "TYPE_ENUM" (global $TYPE_ENUM i32))
  (import "ast_node_types" "TYPE_FLAGS" (global $TYPE_FLAGS i32))
  (import "ast_node_types" "TYPE_RESOURCE" (global $TYPE_RESOURCE i32))
  (import "ast_node_types" "EXPR_IDENTIFIER" (global $EXPR_IDENTIFIER i32))
  (import "ast_node_types" "DECL_FUNCTION" (global $DECL_FUNCTION i32))
  (import "ast_node_types" "DECL_COMPONENT" (global $DECL_COMPONENT i32))
  (import "ast_node_types" "DECL_INTERFACE" (global $DECL_INTERFACE i32))
  (import "ast_node_types" "DECL_IMPORT" (global $DECL_IMPORT i32))
  (import "ast_node_types" "DECL_EXPORT" (global $DECL_EXPORT i32))

  ;; Import memory management functions
  (import "ast_memory" "init_memory_manager" (func $init_memory_manager))
  (import "ast_memory" "free" (func $free (param i32)))

  ;; Import core node operations
  (import "ast_node_core" "create_node" (func $create_node (param i32 i32) (result i32)))
  (import "ast_node_core" "add_child" (func $add_child (param i32 i32) (result i32)))
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "ast_node_core" "free_node_tree" (func $free_node_tree (param i32)))

  ;; Import node creator functions
  (import "ast_type_creators" "create_type_primitive" (func $create_type_primitive (param i32) (result i32)))
  (import "ast_declaration_creators" "create_decl_function" (func $create_decl_function (param i32 i32) (result i32)))
  (import "ast_declaration_creators" "create_decl_component" (func $create_decl_component (param i32 i32) (result i32)))
  (import "ast_declaration_creators" "create_decl_interface" (func $create_decl_interface (param i32 i32) (result i32)))
  (import "ast_declaration_creators" "create_decl_import" (func $create_decl_import (param i32 i32 i32 i32) (result i32)))
  (import "ast_declaration_creators" "create_decl_export" (func $create_decl_export (param i32 i32 i32 i32) (result i32)))
  (import "ast_expression_creators" "create_expr_identifier" (func $create_expr_identifier (param i32 i32) (result i32)))
  (import "ast_expression_creators" "create_integer_literal" (func $create_integer_literal (param i32) (result i32)))
  (import "ast_expression_creators" "create_float_literal" (func $create_float_literal (param i32) (result i32)))
  (import "ast_expression_creators" "create_string_literal" (func $create_string_literal (param i32 i32) (result i32)))
  (import "ast_expression_creators" "create_bool_literal" (func $create_bool_literal (param i32) (result i32)))
  (import "ast_expression_creators" "create_binary_expr" (func $create_binary_expr (param i32 i32 i32 i32) (result i32)))

  ;; Initialize the AST system
  ;; Must be called before using any other AST functions
  (func $init_ast (export "init_ast")
    (call $init_memory_manager))

  ;; Export interface - Core operations
  (export "init_memory_manager" (func $init_memory_manager))
  (export "create_node" (func $create_node))
  (export "free" (func $free))
  (export "add_child" (func $add_child))
  (export "get_node_type" (func $get_node_type))
  (export "free_node_tree" (func $free_node_tree))

  ;; Export interface - Node creators
  (export "create_decl_function" (func $create_decl_function))
  (export "create_decl_component" (func $create_decl_component))
  (export "create_decl_interface" (func $create_decl_interface))
  (export "create_decl_import" (func $create_decl_import))
  (export "create_decl_export" (func $create_decl_export))
  (export "create_expr_identifier" (func $create_expr_identifier))
  (export "create_integer_literal" (func $create_integer_literal))
  (export "create_float_literal" (func $create_float_literal))
  (export "create_string_literal" (func $create_string_literal))
  (export "create_bool_literal" (func $create_bool_literal))
  (export "create_binary_expr" (func $create_binary_expr))

  ;; Export node type constants for external use
  (export "TYPE_PRIMITIVE" (global $TYPE_PRIMITIVE))
  (export "TYPE_LIST" (global $TYPE_LIST))
  (export "TYPE_OPTION" (global $TYPE_OPTION))
  (export "TYPE_RESULT" (global $TYPE_RESULT))
  (export "TYPE_TUPLE" (global $TYPE_TUPLE))
  (export "TYPE_RECORD" (global $TYPE_RECORD))
  (export "TYPE_VARIANT" (global $TYPE_VARIANT))
  (export "TYPE_ENUM" (global $TYPE_ENUM))
  (export "TYPE_FLAGS" (global $TYPE_FLAGS))
  (export "TYPE_RESOURCE" (global $TYPE_RESOURCE))
  (export "EXPR_IDENTIFIER" (global $EXPR_IDENTIFIER))
  (export "DECL_FUNCTION" (global $DECL_FUNCTION))
  (export "DECL_COMPONENT" (global $DECL_COMPONENT))
  (export "DECL_INTERFACE" (global $DECL_INTERFACE))
  (export "DECL_IMPORT" (global $DECL_IMPORT))
  (export "DECL_EXPORT" (global $DECL_EXPORT))
)
