;; Novo Type Checker Infrastructure
;; Core type checking and type management system

(module $typechecker_main
  ;; Import memory from parser main for shared type information
  (import "parser_main" "memory" (memory 1))

  ;; Import AST node type constants
  (import "ast_node_types" "TYPE_PRIMITIVE" (global $TYPE_PRIMITIVE i32))
  (import "ast_node_types" "TYPE_LIST" (global $TYPE_LIST i32))
  (import "ast_node_types" "TYPE_OPTION" (global $TYPE_OPTION i32))
  (import "ast_node_types" "TYPE_RESULT" (global $TYPE_RESULT i32))
  (import "ast_node_types" "TYPE_TUPLE" (global $TYPE_TUPLE i32))
  (import "ast_node_types" "EXPR_IDENTIFIER" (global $EXPR_IDENTIFIER i32))
  (import "ast_node_types" "EXPR_INTEGER_LITERAL" (global $EXPR_INTEGER_LITERAL i32))
  (import "ast_node_types" "EXPR_FLOAT_LITERAL" (global $EXPR_FLOAT_LITERAL i32))
  (import "ast_node_types" "EXPR_STRING_LITERAL" (global $EXPR_STRING_LITERAL i32))
  (import "ast_node_types" "EXPR_BOOL_LITERAL" (global $EXPR_BOOL_LITERAL i32))
  (import "ast_node_types" "DECL_FUNCTION" (global $DECL_FUNCTION i32))

  ;; Import AST core functions
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "ast_node_core" "get_child_count" (func $get_child_count (param i32) (result i32)))
  (import "ast_node_core" "get_child" (func $get_child (param i32 i32) (result i32)))

  ;; Type system constants
  (global $TYPE_UNKNOWN i32 (i32.const 0))
  (global $TYPE_ERROR i32 (i32.const 1))
  (global $TYPE_I32 i32 (i32.const 2))
  (global $TYPE_I64 i32 (i32.const 3))
  (global $TYPE_F32 i32 (i32.const 4))
  (global $TYPE_F64 i32 (i32.const 5))
  (global $TYPE_BOOL i32 (i32.const 6))
  (global $TYPE_STRING i32 (i32.const 7))

  ;; Export type constants for use by other modules
  (export "TYPE_UNKNOWN" (global $TYPE_UNKNOWN))
  (export "TYPE_ERROR" (global $TYPE_ERROR))
  (export "TYPE_I32" (global $TYPE_I32))
  (export "TYPE_I64" (global $TYPE_I64))
  (export "TYPE_F32" (global $TYPE_F32))
  (export "TYPE_F64" (global $TYPE_F64))
  (export "TYPE_BOOL" (global $TYPE_BOOL))
  (export "TYPE_STRING" (global $TYPE_STRING))

  ;; Type information table - maps AST nodes to types
  ;; Memory layout: [node_ptr: i32][type_id: i32]
  (global $TYPE_TABLE_START i32 (i32.const 8192))
  (global $TYPE_TABLE_SIZE i32 (i32.const 4096))  ;; 512 entries max
  (global $TYPE_ENTRY_SIZE i32 (i32.const 8))     ;; 8 bytes per entry
  (global $type_table_count (mut i32) (i32.const 0))

  ;; Symbol table for variable and function types
  ;; Memory layout: [name_ptr: i32][name_len: i32][type_id: i32][scope_level: i32]
  (global $SYMBOL_TABLE_START i32 (i32.const 12288))
  (global $SYMBOL_TABLE_SIZE i32 (i32.const 4096))   ;; 256 entries max
  (global $SYMBOL_ENTRY_SIZE i32 (i32.const 16))     ;; 16 bytes per entry
  (global $symbol_table_count (mut i32) (i32.const 0))
  (global $current_scope_level (mut i32) (i32.const 0))

  ;; Get type information for an AST node
  ;; @param node_ptr i32 - Pointer to AST node
  ;; @returns i32 - Type ID (TYPE_UNKNOWN if not found)
  (func $get_node_type_info (export "get_node_type_info") (param $node_ptr i32) (result i32)
    (local $i i32)
    (local $entry_ptr i32)
    (local $stored_node_ptr i32)

    ;; Search type table for this node
    (local.set $i (i32.const 0))
    (loop $search_loop
      (if (i32.lt_u (local.get $i) (global.get $type_table_count))
        (then
          (local.set $entry_ptr
            (i32.add
              (global.get $TYPE_TABLE_START)
              (i32.mul (local.get $i) (global.get $TYPE_ENTRY_SIZE))))

          (local.set $stored_node_ptr (i32.load (local.get $entry_ptr)))

          (if (i32.eq (local.get $stored_node_ptr) (local.get $node_ptr))
            (then
              ;; Found entry, return type
              (return (i32.load (i32.add (local.get $entry_ptr) (i32.const 4))))
            )
          )

          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $search_loop)
        )
      )
    )

    ;; Not found
    (global.get $TYPE_UNKNOWN)
  )

  ;; Set type information for an AST node
  ;; @param node_ptr i32 - Pointer to AST node
  ;; @param type_id i32 - Type ID
  ;; @returns i32 - 1 if successful, 0 if table full
  (func $set_node_type_info (export "set_node_type_info") (param $node_ptr i32) (param $type_id i32) (result i32)
    (local $entry_ptr i32)

    ;; Check if table is full
    (if (i32.ge_u
          (global.get $type_table_count)
          (i32.div_u (global.get $TYPE_TABLE_SIZE) (global.get $TYPE_ENTRY_SIZE)))
      (then
        ;; Table full
        (return (i32.const 0))
      )
    )

    ;; Add new entry
    (local.set $entry_ptr
      (i32.add
        (global.get $TYPE_TABLE_START)
        (i32.mul (global.get $type_table_count) (global.get $TYPE_ENTRY_SIZE))))

    (i32.store (local.get $entry_ptr) (local.get $node_ptr))
    (i32.store (i32.add (local.get $entry_ptr) (i32.const 4)) (local.get $type_id))

    ;; Increment count
    (global.set $type_table_count (i32.add (global.get $type_table_count) (i32.const 1)))

    (i32.const 1)
  )

  ;; Check if two types are compatible (basic implementation)
  ;; @param type1 i32 - First type ID
  ;; @param type2 i32 - Second type ID
  ;; @returns i32 - 1 if compatible, 0 if not
  (func $types_compatible (export "types_compatible") (param $type1 i32) (param $type2 i32) (result i32)
    ;; Exact match
    (if (i32.eq (local.get $type1) (local.get $type2))
      (then (return (i32.const 1))))

    ;; Unknown type is compatible with anything (for now)
    (if (i32.eq (local.get $type1) (global.get $TYPE_UNKNOWN))
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $type2) (global.get $TYPE_UNKNOWN))
      (then (return (i32.const 1))))

    ;; Error type is not compatible with anything
    (if (i32.eq (local.get $type1) (global.get $TYPE_ERROR))
      (then (return (i32.const 0))))
    (if (i32.eq (local.get $type2) (global.get $TYPE_ERROR))
      (then (return (i32.const 0))))

    ;; Integer types are compatible with each other (with potential conversion)
    (if (i32.and
          (i32.or (i32.eq (local.get $type1) (global.get $TYPE_I32))
                  (i32.eq (local.get $type1) (global.get $TYPE_I64)))
          (i32.or (i32.eq (local.get $type2) (global.get $TYPE_I32))
                  (i32.eq (local.get $type2) (global.get $TYPE_I64))))
      (then (return (i32.const 1))))

    ;; Float types are compatible with each other
    (if (i32.and
          (i32.or (i32.eq (local.get $type1) (global.get $TYPE_F32))
                  (i32.eq (local.get $type1) (global.get $TYPE_F64)))
          (i32.or (i32.eq (local.get $type2) (global.get $TYPE_F32))
                  (i32.eq (local.get $type2) (global.get $TYPE_F64))))
      (then (return (i32.const 1))))

    ;; Otherwise not compatible
    (i32.const 0)
  )

  ;; Infer type for a literal expression
  ;; @param node_ptr i32 - Pointer to AST node
  ;; @returns i32 - Inferred type ID
  (func $infer_literal_type (export "infer_literal_type") (param $node_ptr i32) (result i32)
    (local $node_type i32)

    (local.set $node_type (call $get_node_type (local.get $node_ptr)))

    (block $type_inferred
      ;; Integer literal -> i32 by default
      (if (i32.eq (local.get $node_type) (global.get $EXPR_INTEGER_LITERAL))
        (then
          (return (global.get $TYPE_I32))
        )
      )

      ;; Float literal -> f64 by default
      (if (i32.eq (local.get $node_type) (global.get $EXPR_FLOAT_LITERAL))
        (then
          (return (global.get $TYPE_F64))
        )
      )

      ;; String literal -> string
      (if (i32.eq (local.get $node_type) (global.get $EXPR_STRING_LITERAL))
        (then
          (return (global.get $TYPE_STRING))
        )
      )

      ;; Boolean literal -> bool
      (if (i32.eq (local.get $node_type) (global.get $EXPR_BOOL_LITERAL))
        (then
          (return (global.get $TYPE_BOOL))
        )
      )

      ;; Unknown literal type
      (return (global.get $TYPE_UNKNOWN))
    )

    (global.get $TYPE_UNKNOWN)
  )

  ;; Add a symbol to the symbol table
  ;; @param name_ptr i32 - Pointer to symbol name
  ;; @param name_len i32 - Length of symbol name
  ;; @param type_id i32 - Type ID for the symbol
  ;; @returns i32 - 1 if successful, 0 if table full
  (func $add_symbol (export "add_symbol") (param $name_ptr i32) (param $name_len i32) (param $type_id i32) (result i32)
    (local $entry_ptr i32)

    ;; Check if table is full
    (if (i32.ge_u
          (global.get $symbol_table_count)
          (i32.div_u (global.get $SYMBOL_TABLE_SIZE) (global.get $SYMBOL_ENTRY_SIZE)))
      (then
        ;; Table full
        (return (i32.const 0))
      )
    )

    ;; Add new entry
    (local.set $entry_ptr
      (i32.add
        (global.get $SYMBOL_TABLE_START)
        (i32.mul (global.get $symbol_table_count) (global.get $SYMBOL_ENTRY_SIZE))))

    (i32.store (local.get $entry_ptr) (local.get $name_ptr))
    (i32.store (i32.add (local.get $entry_ptr) (i32.const 4)) (local.get $name_len))
    (i32.store (i32.add (local.get $entry_ptr) (i32.const 8)) (local.get $type_id))
    (i32.store (i32.add (local.get $entry_ptr) (i32.const 12)) (global.get $current_scope_level))

    ;; Increment count
    (global.set $symbol_table_count (i32.add (global.get $symbol_table_count) (i32.const 1)))

    (i32.const 1)
  )

  ;; Look up a symbol in the symbol table
  ;; @param name_ptr i32 - Pointer to symbol name
  ;; @param name_len i32 - Length of symbol name
  ;; @returns i32 - Type ID (TYPE_UNKNOWN if not found)
  (func $lookup_symbol (export "lookup_symbol") (param $name_ptr i32) (param $name_len i32) (result i32)
    (local $i i32)
    (local $entry_ptr i32)
    (local $stored_name_ptr i32)
    (local $stored_name_len i32)
    (local $j i32)
    (local $match i32)

    ;; Search symbol table (reverse order for scope precedence)
    (local.set $i (global.get $symbol_table_count))
    (loop $search_loop
      (if (i32.gt_u (local.get $i) (i32.const 0))
        (then
          (local.set $i (i32.sub (local.get $i) (i32.const 1)))

          (local.set $entry_ptr
            (i32.add
              (global.get $SYMBOL_TABLE_START)
              (i32.mul (local.get $i) (global.get $SYMBOL_ENTRY_SIZE))))

          (local.set $stored_name_ptr (i32.load (local.get $entry_ptr)))
          (local.set $stored_name_len (i32.load (i32.add (local.get $entry_ptr) (i32.const 4))))

          ;; Check if names match
          (if (i32.eq (local.get $stored_name_len) (local.get $name_len))
            (then
              ;; Compare byte by byte
              (local.set $match (i32.const 1))
              (local.set $j (i32.const 0))
              (loop $compare_loop
                (if (i32.lt_u (local.get $j) (local.get $name_len))
                  (then
                    (if (i32.ne
                          (i32.load8_u (i32.add (local.get $name_ptr) (local.get $j)))
                          (i32.load8_u (i32.add (local.get $stored_name_ptr) (local.get $j))))
                      (then
                        (local.set $match (i32.const 0))
                      )
                    )
                    (local.set $j (i32.add (local.get $j) (i32.const 1)))
                    (br $compare_loop)
                  )
                )
              )

              (if (local.get $match)
                (then
                  ;; Found match, return type
                  (return (i32.load (i32.add (local.get $entry_ptr) (i32.const 8))))
                )
              )
            )
          )

          (br $search_loop)
        )
      )
    )

    ;; Not found
    (global.get $TYPE_UNKNOWN)
  )

  ;; Enter a new scope
  (func $enter_scope (export "enter_scope")
    (global.set $current_scope_level (i32.add (global.get $current_scope_level) (i32.const 1)))
  )

  ;; Exit current scope (remove symbols from current scope level)
  (func $exit_scope (export "exit_scope")
    (local $i i32)
    (local $entry_ptr i32)
    (local $scope_level i32)

    ;; Remove symbols from current scope level
    (local.set $i (global.get $symbol_table_count))
    (loop $cleanup_loop
      (if (i32.gt_u (local.get $i) (i32.const 0))
        (then
          (local.set $i (i32.sub (local.get $i) (i32.const 1)))

          (local.set $entry_ptr
            (i32.add
              (global.get $SYMBOL_TABLE_START)
              (i32.mul (local.get $i) (global.get $SYMBOL_ENTRY_SIZE))))

          (local.set $scope_level (i32.load (i32.add (local.get $entry_ptr) (i32.const 12))))

          (if (i32.eq (local.get $scope_level) (global.get $current_scope_level))
            (then
              ;; Remove this symbol by decrementing count
              (global.set $symbol_table_count (local.get $i))
            )
            (else
              ;; Found symbol from outer scope, stop cleanup
              (br $cleanup_loop)
            )
          )

          (br $cleanup_loop)
        )
      )
    )

    ;; Decrement scope level
    (global.set $current_scope_level (i32.sub (global.get $current_scope_level) (i32.const 1)))
  )

  ;; Reset type checker state
  (func $reset_type_checker (export "reset_type_checker")
    (global.set $type_table_count (i32.const 0))
    (global.set $symbol_table_count (i32.const 0))
    (global.set $current_scope_level (i32.const 0))
  )
)
