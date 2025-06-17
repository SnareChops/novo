;; Novo Parser Type System
;; Handles parsing of type declarations and type expressions

(module $novo_parser_types
  ;; Import memory from lexer
  (import "lexer_memory" "memory" (memory 1))

  ;; Import lexer functions
  (import "novo_lexer" "next_token" (func $next_token (param i32) (result i32 i32)))

  ;; Import token constants - Basic tokens
  (import "lexer_tokens" "TOKEN_ERROR" (global $TOKEN_ERROR i32))
  (import "lexer_tokens" "TOKEN_EOF" (global $TOKEN_EOF i32))
  (import "lexer_tokens" "TOKEN_IDENTIFIER" (global $TOKEN_IDENTIFIER i32))
  (import "lexer_tokens" "TOKEN_COLON" (global $TOKEN_COLON i32))
  (import "lexer_tokens" "TOKEN_COMMA" (global $TOKEN_COMMA i32))
  (import "lexer_tokens" "TOKEN_LBRACE" (global $TOKEN_LBRACE i32))
  (import "lexer_tokens" "TOKEN_RBRACE" (global $TOKEN_RBRACE i32))
  (import "lexer_tokens" "TOKEN_LPAREN" (global $TOKEN_LPAREN i32))
  (import "lexer_tokens" "TOKEN_RPAREN" (global $TOKEN_RPAREN i32))

  ;; Import primitive type tokens
  (import "lexer_tokens" "TOKEN_KW_BOOL" (global $TOKEN_KW_BOOL i32))
  (import "lexer_tokens" "TOKEN_KW_S8" (global $TOKEN_KW_S8 i32))
  (import "lexer_tokens" "TOKEN_KW_S16" (global $TOKEN_KW_S16 i32))
  (import "lexer_tokens" "TOKEN_KW_S32" (global $TOKEN_KW_S32 i32))
  (import "lexer_tokens" "TOKEN_KW_S64" (global $TOKEN_KW_S64 i32))
  (import "lexer_tokens" "TOKEN_KW_U8" (global $TOKEN_KW_U8 i32))
  (import "lexer_tokens" "TOKEN_KW_U16" (global $TOKEN_KW_U16 i32))
  (import "lexer_tokens" "TOKEN_KW_U32" (global $TOKEN_KW_U32 i32))
  (import "lexer_tokens" "TOKEN_KW_U64" (global $TOKEN_KW_U64 i32))
  (import "lexer_tokens" "TOKEN_KW_F32" (global $TOKEN_KW_F32 i32))
  (import "lexer_tokens" "TOKEN_KW_F64" (global $TOKEN_KW_F64 i32))
  (import "lexer_tokens" "TOKEN_KW_CHAR" (global $TOKEN_KW_CHAR i32))
  (import "lexer_tokens" "TOKEN_KW_STRING" (global $TOKEN_KW_STRING i32))

  ;; Import compound type tokens
  (import "lexer_tokens" "TOKEN_KW_LIST" (global $TOKEN_KW_LIST i32))
  (import "lexer_tokens" "TOKEN_KW_OPTION" (global $TOKEN_KW_OPTION i32))
  (import "lexer_tokens" "TOKEN_KW_RESULT" (global $TOKEN_KW_RESULT i32))
  (import "lexer_tokens" "TOKEN_KW_TUPLE" (global $TOKEN_KW_TUPLE i32))
  (import "lexer_tokens" "TOKEN_KW_RECORD" (global $TOKEN_KW_RECORD i32))
  (import "lexer_tokens" "TOKEN_KW_VARIANT" (global $TOKEN_KW_VARIANT i32))
  (import "lexer_tokens" "TOKEN_KW_ENUM" (global $TOKEN_KW_ENUM i32))
  (import "lexer_tokens" "TOKEN_KW_FLAGS" (global $TOKEN_KW_FLAGS i32))
  (import "lexer_tokens" "TOKEN_KW_TYPE" (global $TOKEN_KW_TYPE i32))
  (import "lexer_tokens" "TOKEN_KW_RESOURCE" (global $TOKEN_KW_RESOURCE i32))

  ;; Import AST node creators
  (import "ast_node_creators" "create_type_primitive" (func $create_type_primitive (param i32) (result i32)))
  (import "ast_node_creators" "create_type_list" (func $create_type_list (param i32) (result i32)))
  (import "ast_node_creators" "create_type_option" (func $create_type_option (param i32) (result i32)))
  (import "ast_node_creators" "create_type_result" (func $create_type_result (param i32 i32) (result i32)))
  (import "ast_node_creators" "create_type_tuple" (func $create_type_tuple (param i32) (result i32)))

  ;; Import AST core functions
  (import "ast_node_core" "add_child" (func $add_child (param i32 i32) (result i32)))

  ;; Import helper functions
  (import "parser_utils" "get_token_type" (func $get_token_type (param i32) (result i32)))
  (import "parser_utils" "get_token_start" (func $get_token_start (param i32) (result i32)))
  (import "parser_utils" "get_token_length" (func $get_token_length (param i32) (result i32)))

  ;; Primitive type constants matching the AST definitions
  (global $PRIM_TYPE_BOOL i32 (i32.const 0))
  (global $PRIM_TYPE_S8 i32 (i32.const 1))
  (global $PRIM_TYPE_S16 i32 (i32.const 2))
  (global $PRIM_TYPE_S32 i32 (i32.const 3))
  (global $PRIM_TYPE_S64 i32 (i32.const 4))
  (global $PRIM_TYPE_U8 i32 (i32.const 5))
  (global $PRIM_TYPE_U16 i32 (i32.const 6))
  (global $PRIM_TYPE_U32 i32 (i32.const 7))
  (global $PRIM_TYPE_U64 i32 (i32.const 8))
  (global $PRIM_TYPE_F32 i32 (i32.const 9))
  (global $PRIM_TYPE_F64 i32 (i32.const 10))
  (global $PRIM_TYPE_CHAR i32 (i32.const 11))
  (global $PRIM_TYPE_STRING i32 (i32.const 12))

  ;; Parse a primitive type (bool, s32, u64, f32, string, etc.)
  (func $parse_primitive_type (param $pos i32) (result i32 i32)
    (local $token_idx i32)
    (local $next_pos i32)
    (local $token_type i32)
    (local $type_id i32)
    (local $ast_node i32)

    ;; Get next token
    (call $next_token (local.get $pos))
    (local.set $next_pos) ;; Store next position
    (local.set $token_idx) ;; Store token index

    (local.set $token_type (call $get_token_type (local.get $token_idx)))

    ;; Match against primitive type tokens
    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_BOOL))
      (then
        (local.set $type_id (global.get $PRIM_TYPE_BOOL))
        (local.set $ast_node (call $create_type_primitive (local.get $type_id)))
        (return (local.get $ast_node) (local.get $next_pos))
      )
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_S8))
      (then
        (local.set $type_id (global.get $PRIM_TYPE_S8))
        (local.set $ast_node (call $create_type_primitive (local.get $type_id)))
        (return (local.get $ast_node) (local.get $next_pos))
      )
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_S16))
      (then
        (local.set $type_id (global.get $PRIM_TYPE_S16))
        (local.set $ast_node (call $create_type_primitive (local.get $type_id)))
        (return (local.get $ast_node) (local.get $next_pos))
      )
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_S32))
      (then
        (local.set $type_id (global.get $PRIM_TYPE_S32))
        (local.set $ast_node (call $create_type_primitive (local.get $type_id)))
        (return (local.get $ast_node) (local.get $next_pos))
      )
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_S64))
      (then
        (local.set $type_id (global.get $PRIM_TYPE_S64))
        (local.set $ast_node (call $create_type_primitive (local.get $type_id)))
        (return (local.get $ast_node) (local.get $next_pos))
      )
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_U8))
      (then
        (local.set $type_id (global.get $PRIM_TYPE_U8))
        (local.set $ast_node (call $create_type_primitive (local.get $type_id)))
        (return (local.get $ast_node) (local.get $next_pos))
      )
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_U16))
      (then
        (local.set $type_id (global.get $PRIM_TYPE_U16))
        (local.set $ast_node (call $create_type_primitive (local.get $type_id)))
        (return (local.get $ast_node) (local.get $next_pos))
      )
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_U32))
      (then
        (local.set $type_id (global.get $PRIM_TYPE_U32))
        (local.set $ast_node (call $create_type_primitive (local.get $type_id)))
        (return (local.get $ast_node) (local.get $next_pos))
      )
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_U64))
      (then
        (local.set $type_id (global.get $PRIM_TYPE_U64))
        (local.set $ast_node (call $create_type_primitive (local.get $type_id)))
        (return (local.get $ast_node) (local.get $next_pos))
      )
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_F32))
      (then
        (local.set $type_id (global.get $PRIM_TYPE_F32))
        (local.set $ast_node (call $create_type_primitive (local.get $type_id)))
        (return (local.get $ast_node) (local.get $next_pos))
      )
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_F64))
      (then
        (local.set $type_id (global.get $PRIM_TYPE_F64))
        (local.set $ast_node (call $create_type_primitive (local.get $type_id)))
        (return (local.get $ast_node) (local.get $next_pos))
      )
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_CHAR))
      (then
        (local.set $type_id (global.get $PRIM_TYPE_CHAR))
        (local.set $ast_node (call $create_type_primitive (local.get $type_id)))
        (return (local.get $ast_node) (local.get $next_pos))
      )
    )

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_STRING))
      (then
        (local.set $type_id (global.get $PRIM_TYPE_STRING))
        (local.set $ast_node (call $create_type_primitive (local.get $type_id)))
        (return (local.get $ast_node) (local.get $next_pos))
      )
    )

    ;; No primitive type matched - return error
    (return (i32.const 0) (local.get $pos))
  )

  ;; Parse any type expression (primitive, compound, user-defined)
  (func $parse_type (export "parse_type") (param $pos i32) (result i32 i32)
    (local $token_idx i32)
    (local $next_pos i32)
    (local $token_type i32)
    (local $ast_node i32)

    ;; Look ahead to determine what kind of type this is
    (call $next_token (local.get $pos))
    (drop) ;; Don't advance position yet
    (local.set $token_idx) ;; Get token index

    (local.set $token_type (call $get_token_type (local.get $token_idx)))

    ;; Try primitive types first
    (call $parse_primitive_type (local.get $pos))
    (local.set $next_pos)
    (local.set $ast_node)

    ;; If primitive type parsing succeeded, return it
    (if (i32.ne (local.get $ast_node) (i32.const 0))
      (then
        (return (local.get $ast_node) (local.get $next_pos))
      )
    )

    ;; Parse compound types: list, option, result, tuple
    (call $parse_compound_type (local.get $pos))
    (local.set $next_pos)
    (local.set $ast_node)

    ;; If compound type parsing succeeded, return it
    (if (i32.ne (local.get $ast_node) (i32.const 0))
      (then
        (return (local.get $ast_node) (local.get $next_pos))
      )
    )

    ;; TODO: Add user-defined type parsing (identifiers)
    ;; TODO: Add type alias parsing

    ;; For now, return error if no type matched
    (return (i32.const 0) (local.get $pos))
  )

  ;; Parse a compound type like list<T>, option<T>, result<T,E>, tuple<T1,T2,...>
  (func $parse_compound_type (param $pos i32) (result i32 i32)
    (local $token_idx i32)
    (local $next_pos i32)
    (local $token_type i32)
    (local $inner_type i32)
    (local $ok_type i32)
    (local $err_type i32)
    (local $tuple_node i32)
    (local $element_count i32)
    (local $current_pos i32)

    ;; Get next token to see what compound type this is
    (call $next_token (local.get $pos))
    (local.set $next_pos)
    (local.set $token_idx)

    (local.set $token_type (call $get_token_type (local.get $token_idx)))

    ;; Parse list<T>
    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_LIST))
      (then
        ;; Expect <
        ;; TODO: Add TOKEN_LT when available, for now return simple list
        (call $parse_type (local.get $next_pos))
        (local.set $next_pos)
        (local.set $inner_type)

        (if (i32.eqz (local.get $inner_type))
          (then (return (i32.const 0) (local.get $next_pos)))
        )

        (return (call $create_type_list (local.get $inner_type)) (local.get $next_pos))
      )
    )

    ;; Parse option<T>
    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_OPTION))
      (then
        ;; Parse inner type
        (call $parse_type (local.get $next_pos))
        (local.set $next_pos)
        (local.set $inner_type)

        (if (i32.eqz (local.get $inner_type))
          (then (return (i32.const 0) (local.get $next_pos)))
        )

        (return (call $create_type_option (local.get $inner_type)) (local.get $next_pos))
      )
    )

    ;; Parse result<T,E>
    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_RESULT))
      (then
        ;; Parse ok type
        (call $parse_type (local.get $next_pos))
        (local.set $current_pos)
        (local.set $ok_type)

        (if (i32.eqz (local.get $ok_type))
          (then (return (i32.const 0) (local.get $current_pos)))
        )

        ;; Parse error type
        (call $parse_type (local.get $current_pos))
        (local.set $next_pos)
        (local.set $err_type)

        (if (i32.eqz (local.get $err_type))
          (then (return (i32.const 0) (local.get $next_pos)))
        )

        (return (call $create_type_result (local.get $ok_type) (local.get $err_type)) (local.get $next_pos))
      )
    )

    ;; Parse tuple<T1, T2, ...>
    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KW_TUPLE))
      (then
        ;; For now, create tuple with element count 0
        ;; TODO: Parse actual tuple elements
        (local.set $element_count (i32.const 0))
        (local.set $tuple_node (call $create_type_tuple (local.get $element_count)))
        (return (local.get $tuple_node) (local.get $next_pos))
      )
    )

    ;; No compound type matched - return error
    (return (i32.const 0) (local.get $pos))
  )
)
