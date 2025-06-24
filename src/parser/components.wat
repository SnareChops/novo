;; Novo Component Declaration Parser
;; Handles parsing of component, interface, world, import, and export declarations

(module $novo_parser_components
  ;; Import memory from lexer memory module
  (import "lexer_memory" "memory" (memory 1))

  ;; Import lexer functions
  (import "novo_lexer" "next_token" (func $next_token (param i32) (result i32 i32)))

  ;; Import token constants
  (import "lexer_tokens" "TOKEN_ERROR" (global $TOKEN_ERROR i32))
  (import "lexer_tokens" "TOKEN_EOF" (global $TOKEN_EOF i32))
  (import "lexer_tokens" "TOKEN_IDENTIFIER" (global $TOKEN_IDENTIFIER i32))
  (import "lexer_tokens" "TOKEN_LBRACE" (global $TOKEN_LBRACE i32))
  (import "lexer_tokens" "TOKEN_RBRACE" (global $TOKEN_RBRACE i32))
  (import "lexer_tokens" "TOKEN_COLON" (global $TOKEN_COLON i32))
  (import "lexer_tokens" "TOKEN_COMMA" (global $TOKEN_COMMA i32))
  (import "lexer_tokens" "TOKEN_KW_COMPONENT" (global $TOKEN_KW_COMPONENT i32))
  (import "lexer_tokens" "TOKEN_KW_INTERFACE" (global $TOKEN_KW_INTERFACE i32))
  (import "lexer_tokens" "TOKEN_KW_WORLD" (global $TOKEN_KW_WORLD i32))
  (import "lexer_tokens" "TOKEN_KW_IMPORT" (global $TOKEN_KW_IMPORT i32))
  (import "lexer_tokens" "TOKEN_KW_EXPORT" (global $TOKEN_KW_EXPORT i32))
  (import "lexer_tokens" "TOKEN_KW_USE" (global $TOKEN_KW_USE i32))
  (import "lexer_tokens" "TOKEN_KW_INCLUDE" (global $TOKEN_KW_INCLUDE i32))
  (import "lexer_tokens" "TOKEN_KW_FUNC" (global $TOKEN_KW_FUNC i32))

  ;; Import AST node types
  (import "ast_node_types" "DECL_COMPONENT" (global $DECL_COMPONENT i32))
  (import "ast_node_types" "DECL_INTERFACE" (global $DECL_INTERFACE i32))
  (import "ast_node_types" "DECL_IMPORT" (global $DECL_IMPORT i32))
  (import "ast_node_types" "DECL_EXPORT" (global $DECL_EXPORT i32))

  ;; Import AST creation functions
  (import "ast_declaration_creators" "create_decl_component" (func $create_decl_component (param i32 i32) (result i32)))
  (import "ast_declaration_creators" "create_decl_interface" (func $create_decl_interface (param i32 i32) (result i32)))
  (import "ast_declaration_creators" "create_decl_import" (func $create_decl_import (param i32 i32 i32 i32) (result i32)))
  (import "ast_declaration_creators" "create_decl_export" (func $create_decl_export (param i32 i32 i32 i32) (result i32)))
  (import "ast_node_core" "add_child" (func $add_child (param i32 i32) (result i32)))

  ;; Import utility functions
  (import "parser_utils" "get_token_type" (func $get_token_type (param i32) (result i32)))
  (import "parser_utils" "get_token_start" (func $get_token_start (param i32) (result i32)))
  (import "parser_utils" "get_token_length" (func $get_token_length (param i32) (result i32)))

  ;; Import function declaration parsing for interface/component contents
  (import "parser_functions" "parse_function_declaration" (func $parse_function_declaration (param i32) (result i32 i32)))

  ;; Parse a component declaration
  ;; @param pos i32 - Current position in input
  ;; @returns i32 i32 - AST node pointer, next position
  (func $parse_component_declaration (export "parse_component_declaration") (param $pos i32) (result i32 i32)
    (local $token i32)
    (local $token_type i32)
    (local $next_pos i32)
    (local $component_node i32)
    (local $name_start i32)
    (local $name_len i32)
    (local $temp_node i32)

    ;; Parse 'component' keyword
    (call $next_token (local.get $pos))
    (local.set $next_pos)
    (local.set $token)

    (local.set $token_type (call $get_token_type (local.get $token)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_KW_COMPONENT))
      (then
        ;; Not a component declaration
        (return (i32.const 0) (local.get $pos))))

    ;; Parse component name
    (call $next_token (local.get $next_pos))
    (local.set $next_pos)
    (local.set $token)

    (local.set $token_type (call $get_token_type (local.get $token)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_IDENTIFIER))
      (then
        ;; Missing component name
        (return (i32.const 0) (local.get $pos))))

    ;; Get component name details
    (local.set $name_start (call $get_token_start (local.get $token)))
    (local.set $name_len (call $get_token_length (local.get $token)))

    ;; Create component node
    (local.set $component_node
      (call $create_decl_component (local.get $name_start) (local.get $name_len)))

    (if (i32.eqz (local.get $component_node))
      (then
        ;; Memory allocation failed
        (return (i32.const 0) (local.get $pos))))

    ;; Parse opening brace
    (call $next_token (local.get $next_pos))
    (local.set $next_pos)
    (local.set $token)

    (local.set $token_type (call $get_token_type (local.get $token)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_LBRACE))
      (then
        ;; Missing opening brace
        (return (i32.const 0) (local.get $pos))))

    ;; Parse component body (imports, exports, functions)
    (call $parse_component_body (local.get $component_node) (local.get $next_pos))
    (local.set $next_pos)

    ;; Return component node and final position
    (local.get $component_node)
    (local.get $next_pos))

  ;; Parse component body contents
  ;; @param component_node i32 - Component AST node to add children to
  ;; @param pos i32 - Current position in input
  ;; @returns i32 - Next position after component body
  (func $parse_component_body (param $component_node i32) (param $pos i32) (result i32)
    (local $token i32)
    (local $token_type i32)
    (local $next_pos i32)
    (local $child_node i32)
    (local $temp_pos i32)

    (local.set $next_pos (local.get $pos))

    ;; Parse component body until closing brace
    (block $done
      (loop $parse_loop
        ;; Get next token
        (call $next_token (local.get $next_pos))
        (local.set $next_pos)
        (local.set $token)

        (local.set $token_type (call $get_token_type (local.get $token)))

        ;; Check for end of component
        (if (i32.eq (local.get $token_type) (global.get $TOKEN_RBRACE))
          (then
            (br $done)))

        ;; Check for EOF or error
        (if (i32.or
              (i32.eq (local.get $token_type) (global.get $TOKEN_EOF))
              (i32.eq (local.get $token_type) (global.get $TOKEN_ERROR)))
          (then
            (br $done)))

        ;; Parse different component elements
        (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_IMPORT))
          (then
            ;; Parse import statement
            (call $parse_import_declaration (local.get $next_pos))
            (local.set $next_pos)
            (local.set $child_node)
            (if (local.get $child_node)
              (then
                (call $add_child (local.get $component_node) (local.get $child_node))
                (drop)))))

        (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_EXPORT))
          (then
            ;; Parse export statement
            (call $parse_export_declaration (local.get $next_pos))
            (local.set $next_pos)
            (local.set $child_node)
            (if (local.get $child_node)
              (then
                (call $add_child (local.get $component_node) (local.get $child_node))
                (drop)))))

        (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_FUNC))
          (then
            ;; Parse function declaration (backtrack to include 'func' keyword)
            (local.set $temp_pos (i32.sub (local.get $next_pos) (i32.const 1)))
            (call $parse_function_declaration (local.get $temp_pos))
            (local.set $next_pos)
            (local.set $child_node)
            (if (local.get $child_node)
              (then
                (call $add_child (local.get $component_node) (local.get $child_node))
                (drop)))))

        ;; Continue to next statement
        (br $parse_loop)))

    (local.get $next_pos))

  ;; Parse an import declaration
  ;; @param pos i32 - Current position in input (after 'import' keyword)
  ;; @returns i32 i32 - AST node pointer, next position
  (func $parse_import_declaration (param $pos i32) (result i32 i32)
    (local $token i32)
    (local $token_type i32)
    (local $next_pos i32)
    (local $import_node i32)
    (local $module_start i32)
    (local $module_len i32)
    (local $item_start i32)
    (local $item_len i32)

    ;; Parse module name
    (call $next_token (local.get $pos))
    (local.set $next_pos)
    (local.set $token)

    (local.set $token_type (call $get_token_type (local.get $token)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_IDENTIFIER))
      (then
        ;; Missing module name
        (return (i32.const 0) (local.get $pos))))

    ;; Get module name details
    (local.set $module_start (call $get_token_start (local.get $token)))
    (local.set $module_len (call $get_token_length (local.get $token)))

    ;; Initialize item name as empty (whole module import)
    (local.set $item_start (i32.const 0))
    (local.set $item_len (i32.const 0))

    ;; TODO: Parse granular imports like module.{item1, item2}
    ;; For now, only support whole module imports

    ;; Create import node
    (local.set $import_node
      (call $create_decl_import
        (local.get $module_start) (local.get $module_len)
        (local.get $item_start) (local.get $item_len)))

    ;; Return import node and next position
    (local.get $import_node)
    (local.get $next_pos))

  ;; Parse an export declaration
  ;; @param pos i32 - Current position in input (after 'export' keyword)
  ;; @returns i32 i32 - AST node pointer, next position
  (func $parse_export_declaration (param $pos i32) (result i32 i32)
    (local $token i32)
    (local $token_type i32)
    (local $next_pos i32)
    (local $export_node i32)
    (local $name_start i32)
    (local $name_len i32)
    (local $alias_start i32)
    (local $alias_len i32)

    ;; Parse exported name
    (call $next_token (local.get $pos))
    (local.set $next_pos)
    (local.set $token)

    (local.set $token_type (call $get_token_type (local.get $token)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_IDENTIFIER))
      (then
        ;; Missing export name
        (return (i32.const 0) (local.get $pos))))

    ;; Get export name details
    (local.set $name_start (call $get_token_start (local.get $token)))
    (local.set $name_len (call $get_token_length (local.get $token)))

    ;; Initialize alias as empty (same name)
    (local.set $alias_start (i32.const 0))
    (local.set $alias_len (i32.const 0))

    ;; TODO: Parse export aliases and granular exports
    ;; For now, only support simple name exports

    ;; Create export node
    (local.set $export_node
      (call $create_decl_export
        (local.get $name_start) (local.get $name_len)
        (local.get $alias_start) (local.get $alias_len)))

    ;; Return export node and next position
    (local.get $export_node)
    (local.get $next_pos))

  ;; Parse an interface declaration
  ;; @param pos i32 - Current position in input
  ;; @returns i32 i32 - AST node pointer, next position
  (func $parse_interface_declaration (export "parse_interface_declaration") (param $pos i32) (result i32 i32)
    (local $token i32)
    (local $token_type i32)
    (local $next_pos i32)
    (local $interface_node i32)
    (local $name_start i32)
    (local $name_len i32)

    ;; Parse 'interface' keyword
    (call $next_token (local.get $pos))
    (local.set $next_pos)
    (local.set $token)

    (local.set $token_type (call $get_token_type (local.get $token)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_KW_INTERFACE))
      (then
        ;; Not an interface declaration
        (return (i32.const 0) (local.get $pos))))

    ;; Parse interface name
    (call $next_token (local.get $next_pos))
    (local.set $next_pos)
    (local.set $token)

    (local.set $token_type (call $get_token_type (local.get $token)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_IDENTIFIER))
      (then
        ;; Missing interface name
        (return (i32.const 0) (local.get $pos))))

    ;; Get interface name details
    (local.set $name_start (call $get_token_start (local.get $token)))
    (local.set $name_len (call $get_token_length (local.get $token)))

    ;; Create interface node
    (local.set $interface_node
      (call $create_decl_interface (local.get $name_start) (local.get $name_len)))

    (if (i32.eqz (local.get $interface_node))
      (then
        ;; Memory allocation failed
        (return (i32.const 0) (local.get $pos))))

    ;; Parse opening brace
    (call $next_token (local.get $next_pos))
    (local.set $next_pos)
    (local.set $token)

    (local.set $token_type (call $get_token_type (local.get $token)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_LBRACE))
      (then
        ;; Missing opening brace
        (return (i32.const 0) (local.get $pos))))

    ;; Parse interface body (function signatures and type definitions)
    (call $parse_interface_body (local.get $interface_node) (local.get $next_pos))
    (local.set $next_pos)

    ;; Return interface node and final position
    (local.get $interface_node)
    (local.get $next_pos))

  ;; Parse interface body contents
  ;; @param interface_node i32 - Interface AST node to add children to
  ;; @param pos i32 - Current position in input
  ;; @returns i32 - Next position after interface body
  (func $parse_interface_body (param $interface_node i32) (param $pos i32) (result i32)
    (local $token i32)
    (local $token_type i32)
    (local $next_pos i32)
    (local $child_node i32)
    (local $temp_pos i32)

    (local.set $next_pos (local.get $pos))

    ;; Parse interface body until closing brace
    (block $done
      (loop $parse_loop
        ;; Get next token
        (call $next_token (local.get $next_pos))
        (local.set $next_pos)
        (local.set $token)

        (local.set $token_type (call $get_token_type (local.get $token)))

        ;; Check for end of interface
        (if (i32.eq (local.get $token_type) (global.get $TOKEN_RBRACE))
          (then
            (br $done)))

        ;; Check for EOF or error
        (if (i32.or
              (i32.eq (local.get $token_type) (global.get $TOKEN_EOF))
              (i32.eq (local.get $token_type) (global.get $TOKEN_ERROR)))
          (then
            (br $done)))

        ;; Parse function signatures (no implementation bodies in interfaces)
        (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_FUNC))
          (then
            ;; Parse function signature (backtrack to include 'func' keyword)
            (local.set $temp_pos (i32.sub (local.get $next_pos) (i32.const 1)))
            (call $parse_function_declaration (local.get $temp_pos))
            (local.set $next_pos)
            (local.set $child_node)
            (if (local.get $child_node)
              (then
                (call $add_child (local.get $interface_node) (local.get $child_node))
                (drop)))))

        ;; TODO: Parse record, variant, enum type definitions within interfaces

        ;; Continue to next statement
        (br $parse_loop)))

    (local.get $next_pos))

  ;; Parse a world declaration (alias for component)
  ;; @param pos i32 - Current position in input
  ;; @returns i32 i32 - AST node pointer, next position
  (func $parse_world_declaration (export "parse_world_declaration") (param $pos i32) (result i32 i32)
    (local $token i32)
    (local $token_type i32)
    (local $next_pos i32)

    ;; Parse 'world' keyword
    (call $next_token (local.get $pos))
    (local.set $next_pos)
    (local.set $token)

    (local.set $token_type (call $get_token_type (local.get $token)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_KW_WORLD))
      (then
        ;; Not a world declaration
        (return (i32.const 0) (local.get $pos))))

    ;; World is essentially a component, so delegate to component parsing
    ;; but first replace the 'world' keyword conceptually with 'component'
    (call $parse_component_declaration_impl (local.get $next_pos)))

  ;; Internal implementation of component parsing (shared by world parsing)
  ;; @param pos i32 - Current position in input (after keyword)
  ;; @returns i32 i32 - AST node pointer, next position
  (func $parse_component_declaration_impl (param $pos i32) (result i32 i32)
    (local $token i32)
    (local $token_type i32)
    (local $next_pos i32)
    (local $component_node i32)
    (local $name_start i32)
    (local $name_len i32)

    ;; Parse component/world name
    (call $next_token (local.get $pos))
    (local.set $next_pos)
    (local.set $token)

    (local.set $token_type (call $get_token_type (local.get $token)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_IDENTIFIER))
      (then
        ;; Missing name
        (return (i32.const 0) (local.get $pos))))

    ;; Get name details
    (local.set $name_start (call $get_token_start (local.get $token)))
    (local.set $name_len (call $get_token_length (local.get $token)))

    ;; Create component node (world uses same AST node type)
    (local.set $component_node
      (call $create_decl_component (local.get $name_start) (local.get $name_len)))

    (if (i32.eqz (local.get $component_node))
      (then
        ;; Memory allocation failed
        (return (i32.const 0) (local.get $pos))))

    ;; Parse opening brace
    (call $next_token (local.get $next_pos))
    (local.set $next_pos)
    (local.set $token)

    (local.set $token_type (call $get_token_type (local.get $token)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_LBRACE))
      (then
        ;; Missing opening brace
        (return (i32.const 0) (local.get $pos))))

    ;; Parse component body
    (call $parse_component_body (local.get $component_node) (local.get $next_pos))
    (local.set $next_pos)

    ;; Return component node and final position
    (local.get $component_node)
    (local.get $next_pos))
)
