;; WebAssembly Text Format Parser Module
;; Interface: parser.wit
(module
    ;; Import memory and lexer functions
    (import "memory" "memory" (memory 1))
    (import "lexer" "next-token" (func $next_token (result i32)))
    (import "lexer" "init-lexer" (func $init_lexer (param i32 i32) (result i32)))

    ;; AST Node type constants (matching spec)
    (global $AST_MODULE i32 (i32.const 10))
    (global $AST_COMPONENT i32 (i32.const 11))
    (global $AST_INTERFACE i32 (i32.const 12))
    (global $AST_WORLD i32 (i32.const 13))
    (global $AST_FUNC i32 (i32.const 14))
    (global $AST_PARAM i32 (i32.const 15))
    (global $AST_RESULT i32 (i32.const 16))
    (global $AST_LOCAL i32 (i32.const 17))
    (global $AST_INSTR i32 (i32.const 18))
    (global $AST_BLOCK i32 (i32.const 19))
    (global $AST_LOOP i32 (i32.const 20))
    (global $AST_IF i32 (i32.const 21))
    (global $AST_RESOURCE i32 (i32.const 22))
    (global $AST_VARIANT i32 (i32.const 23))
    (global $AST_RECORD i32 (i32.const 24))
    (global $AST_FLAGS i32 (i32.const 25))
    (global $AST_ENUM i32 (i32.const 26))
    (global $AST_IMPORT i32 (i32.const 27))
    (global $AST_EXPORT i32 (i32.const 28))
    (global $AST_TYPE i32 (i32.const 29))

    ;; Token type constants (imported from lexer)
    (global $TOKEN_LPAREN i32 (i32.const 0))
    (global $TOKEN_RPAREN i32 (i32.const 1))
    (global $TOKEN_IDENTIFIER i32 (i32.const 2))
    (global $TOKEN_KEYWORD i32 (i32.const 3))
    (global $TOKEN_INTEGER i32 (i32.const 4))
    (global $TOKEN_STRING i32 (i32.const 6))

    ;; Parser state constants
    (global $PARSE_OK i32 (i32.const 0))
    (global $PARSE_ERROR i32 (i32.const 1))
    (global $PARSE_UNEXPECTED_TOKEN i32 (i32.const 2))
    (global $PARSE_EXPECTED_IDENTIFIER i32 (i32.const 3))

    ;; Parser state
    (global $current_token (mut i32) (i32.const 0))
    (global $ast_root (mut i32) (i32.const 0))
    (global $next_node_id (mut i32) (i32.const 1))

    ;; Initialize parser with source text
    (func $init_parser (export "init-parser")
        (param $source_ptr i32)    ;; Pointer to source text
        (param $source_len i32)    ;; Length of source text
        (result i32)               ;; Returns 1 on success, 0 on failure

        ;; Initialize lexer
        (if (i32.eqz (call $init_lexer (local.get $source_ptr) (local.get $source_len)))
            (then (return (i32.const 0))))

        ;; Reset parser state
        (global.set $current_token (i32.const 0))
        (global.set $ast_root (i32.const 0))
        (global.set $next_node_id (i32.const 1))

        ;; Get first token
        (global.set $current_token (call $next_token))
        (i32.const 1)
    )

    ;; Create a new AST node
    (func $create_node
        (param $type i32)          ;; Node type
        (param $parent i32)        ;; Parent node ID (0 for root)
        (result i32)               ;; Returns node ID
        (local $node_ptr i32)      ;; Pointer to node memory
        (local $node_id i32)       ;; Node ID

        ;; Allocate node memory (20 bytes base structure)
        (local.set $node_ptr
            (i32.add
                (i32.const 0x3000)     ;; AST node pool base
                (i32.mul
                    (global.get $next_node_id)
                    (i32.const 32))))   ;; 32 bytes per node with extra space

        ;; Set node ID
        (local.set $node_id (global.get $next_node_id))
        (global.set $next_node_id
            (i32.add (global.get $next_node_id) (i32.const 1)))

        ;; Initialize node structure
        (i32.store (local.get $node_ptr) (local.get $type))           ;; type
        (i32.store offset=4 (local.get $node_ptr) (local.get $parent));; parent
        (i32.store offset=8 (local.get $node_ptr) (i32.const 0))      ;; first_child
        (i32.store offset=12 (local.get $node_ptr) (i32.const 0))     ;; next_sibling
        (i32.store offset=16 (local.get $node_ptr) (i32.const 0))     ;; data

        (local.get $node_id)
    )

    ;; Parse module or component
    (func $parse_root (export "parse-root")
        (result i32)               ;; Returns root node ID or 0 on error
        (local $token_type i32)
        (local $root_node i32)

        ;; Get token type
        (local.set $token_type
            (i32.load (global.get $current_token)))

        ;; Create appropriate root node
        (local.set $root_node
            (if (result i32)
                (i32.eq (local.get $token_type) (global.get $AST_MODULE))
                (then (call $create_node (global.get $AST_MODULE) (i32.const 0)))
                (else
                    (if (result i32)
                        (i32.eq (local.get $token_type) (global.get $AST_COMPONENT))
                        (then (call $create_node (global.get $AST_COMPONENT) (i32.const 0)))
                        (else (i32.const 0))))))

        ;; Store root node
        (global.set $ast_root (local.get $root_node))
        (local.get $root_node)
    )

    ;; Get node type
    (func $get_node_type (export "get-node-type")
        (param $node_id i32)
        (result i32)
        (i32.load
            (i32.add
                (i32.const 0x3000)
                (i32.mul (local.get $node_id) (i32.const 32))))
    )

    ;; Get node parent
    (func $get_node_parent (export "get-node-parent")
        (param $node_id i32)
        (result i32)
        (i32.load offset=4
            (i32.add
                (i32.const 0x3000)
                (i32.mul (local.get $node_id) (i32.const 32))))
    )

    ;; Add child node
    (func $add_child
        (param $parent_id i32)
        (param $child_id i32)
        (local $parent_ptr i32)
        (local $last_child i32)
        (local $current_child i32)

        ;; Get parent node pointer
        (local.set $parent_ptr
            (i32.add
                (i32.const 0x3000)
                (i32.mul (local.get $parent_id) (i32.const 32))))

        ;; Get first child
        (local.set $current_child
            (i32.load offset=8 (local.get $parent_ptr)))

        ;; If no children, set as first child
        (if (i32.eqz (local.get $current_child))
            (then
                (i32.store offset=8
                    (local.get $parent_ptr)
                    (local.get $child_id))
                (return)))

        ;; Find last child
        (local.set $last_child (local.get $current_child))
        (loop $find_last
            (local.set $current_child
                (i32.load offset=12
                    (i32.add
                        (i32.const 0x3000)
                        (i32.mul (local.get $last_child) (i32.const 32)))))
            (if (local.get $current_child)
                (then
                    (local.set $last_child (local.get $current_child))
                    (br $find_last))))

        ;; Add new child as next sibling of last child
        (i32.store offset=12
            (i32.add
                (i32.const 0x3000)
                (i32.mul (local.get $last_child) (i32.const 32)))
            (local.get $child_id))
    )

    ;; Export parser interface functions
    (export "get-ast-root" (func $get_ast_root))
    (func $get_ast_root (result i32)
        (global.get $ast_root))

    ;; Initialize parser with source text
    (func $init_parser (export "init-parser")
        (param $source_ptr i32)    ;; Pointer to source text
        (param $source_len i32)    ;; Length of source text
        (result i32)               ;; Returns 1 on success, 0 on failure

        ;; Initialize lexer
        (if (i32.eqz (call $init_lexer (local.get $source_ptr) (local.get $source_len)))
            (then (return (i32.const 0))))

        ;; Reset parser state
        (global.set $current_token (i32.const 0))
        (global.set $ast_root (i32.const 0))
        (global.set $next_node_id (i32.const 1))

        ;; Get first token
        (global.set $current_token (call $next_token))
        (i32.const 1)
    )

    ;; Parse Function node
    (func $parse_function
        (param $parent_id i32)     ;; Parent node ID
        (result i32)               ;; Returns function node ID or 0 on error
        (local $func_node i32)     ;; Function node ID
        (local $token_type i32)    ;; Current token type
        (local $token_value i32)   ;; Token value pointer
        (local $token_len i32)     ;; Token length

        ;; Create function node
        (local.set $func_node
            (call $create_node (global.get $AST_FUNC) (local.get $parent_id)))

        ;; Add to parent's children
        (call $add_child (local.get $parent_id) (local.get $func_node))

        ;; Get next token (should be either identifier or param/result)
        (global.set $current_token (call $next_token))
        (local.set $token_type (i32.load (global.get $current_token)))

        ;; Check for function name (identifier prefixed with $)
        (if (i32.eq (local.get $token_type) (global.get $TOKEN_IDENTIFIER))
            (then
                ;; Store function name in node data
                (i32.store offset=16
                    (i32.add
                        (i32.const 0x3000)
                        (i32.mul (local.get $func_node) (i32.const 32)))
                    (i32.load offset=4 (global.get $current_token)))  ;; Store name pointer
                (i32.store offset=20
                    (i32.add
                        (i32.const 0x3000)
                        (i32.mul (local.get $func_node) (i32.const 32)))
                    (i32.load offset=8 (global.get $current_token)))  ;; Store name length

                ;; Move to next token
                (global.set $current_token (call $next_token))
                (local.set $token_type (i32.load (global.get $current_token)))))

    ;; Parse function parameters
    (block $params_done
        (loop $parse_params
            (br_if $params_done
                (i32.ne (local.get $token_type) (global.get $TOKEN_KEYWORD)))

            ;; Check for param keyword
            (local.set $token_value (i32.load offset=4 (global.get $current_token)))
            (local.set $token_len (i32.load offset=8 (global.get $current_token)))

            (if (call $is_keyword_param
                    (local.get $token_value)
                    (local.get $token_len))
                (then
                    ;; Parse parameter
                    (call $parse_param (local.get $func_node))
                    ;; Update token for next iteration
                    (global.set $current_token (call $next_token))
                    (local.set $token_type (i32.load (global.get $current_token)))
                    (br $parse_params))))
    )

    ;; Parse function result type
    (if (i32.eq (local.get $token_type) (global.get $TOKEN_KEYWORD))
        (then
            (local.set $token_value (i32.load offset=4 (global.get $current_token)))
            (local.set $token_len (i32.load offset=8 (global.get $current_token)))

            (if (call $is_keyword_result
                    (local.get $token_value)
                    (local.get $token_len))
                (then
                    ;; Parse result type
                    (call $parse_result (local.get $func_node))
                    ;; Move to function body
                    (global.set $current_token (call $next_token))))))

    ;; Parse function body (instructions)
    (call $parse_instructions (local.get $func_node))

    ;; Return function node ID
    (local.get $func_node)
)

;; Helper to check if token is 'param' keyword
(func $is_keyword_param
    (param $str_ptr i32)
    (param $str_len i32)
    (result i32)
    ;; TODO: Implement string comparison with "param"
    (i32.const 1)
)

;; Helper to check if token is 'result' keyword
(func $is_keyword_result
    (param $str_ptr i32)
    (param $str_len i32)
    (result i32)
    ;; TODO: Implement string comparison with "result"
    (i32.const 1)
)

;; String comparison helper
(func $compare_strings
    (param $str1_ptr i32)
    (param $str2_ptr i32)
    (param $len i32)
    (result i32)
    (local $i i32)

    (local.set $i (i32.const 0))
    (loop $compare
        ;; If we've reached the end, strings are equal
        (if (i32.eq (local.get $i) (local.get $len))
            (then (return (i32.const 1))))

        ;; Compare characters
        (if (i32.ne
                (i32.load8_u (i32.add (local.get $str1_ptr) (local.get $i)))
                (i32.load8_u (i32.add (local.get $str2_ptr) (local.get $i))))
            (then (return (i32.const 0))))

        ;; Next character
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $compare))
    (i32.const 1)  ;; Equal if we get here
)

;; Check if token matches keyword
(func $is_keyword
    (param $token_ptr i32)
    (param $keyword_ptr i32)
    (param $keyword_len i32)
    (result i32)
    (local $token_len i32)

    ;; Get token length
    (local.set $token_len
        (i32.load offset=4 (local.get $token_ptr)))

    ;; Check lengths match
    (if (i32.ne (local.get $token_len) (local.get $keyword_len))
        (then (return (i32.const 0))))

    ;; Compare strings
    (return (call $compare_strings
        (i32.load (local.get $token_ptr))    ;; Token text pointer
        (local.get $keyword_ptr)             ;; Keyword pointer
        (local.get $keyword_len)))           ;; Length
)

;; Store operand data in node
(func $store_operand
    (param $node_id i32)
    (param $operand_type i32)
    (param $operand_value i32)
    (local $node_ptr i32)

    ;; Calculate node pointer
    (local.set $node_ptr
        (i32.add
            (i32.const 0x3000)
            (i32.mul (local.get $node_id) (i32.const 32))))

    ;; Store operand type and value in data fields
    (i32.store offset=16 (local.get $node_ptr) (local.get $operand_type))
    (i32.store offset=20 (local.get $node_ptr) (local.get $operand_value))
)

;; String value storage
(func $store_string_value
    (param $node_id i32)
    (param $value_ptr i32)
    (param $value_len i32)
    (local $node_ptr i32)

    ;; Calculate node pointer
    (local.set $node_ptr
        (i32.add
            (i32.const 0x3000)
            (i32.mul (local.get $node_id) (i32.const 32))))

    ;; Store string pointer and length in data fields
    (i32.store offset=16 (local.get $node_ptr) (local.get $value_ptr))
    (i32.store offset=20 (local.get $node_ptr) (local.get $value_len))
)

;; Parse instruction
(func $parse_instruction
    (param $parent_id i32)
    (result i32)               ;; Returns instruction node ID or 0 on error
    (local $node_id i32)
    (local $token_type i32)
    (local $token_value i32)

    ;; Create instruction node
    (local.set $node_id
        (call $create_node
            (global.get $AST_INSTR)
            (local.get $parent_id)))

    ;; Get instruction token info
    (local.set $token_type
        (i32.load (global.get $current_token)))
    (local.set $token_value
        (i32.load offset=8 (global.get $current_token)))

    ;; Store instruction type
    (call $store_operand
        (local.get $node_id)
        (local.get $token_type)
        (local.get $token_value))

    ;; Get next token (may be operand)
    (global.set $current_token (call $next_token))
    (local.set $token_type
        (i32.load (global.get $current_token)))

    ;; Check for operand
    (if (i32.eq (local.get $token_type) (global.get $TOKEN_INTEGER))
        (then
            ;; Store operand value
            (call $store_operand
                (local.get $node_id)
                (local.get $token_type)
                (i32.load offset=8 (global.get $current_token)))

            ;; Get next token
            (global.set $current_token (call $next_token))))

    (local.get $node_id)
)

;; Parse import declaration
(func $parse_import
    (param $parent_id i32)
    (result i32)
    (local $node_id i32)
    (local $token_type i32)

    ;; Create import node
    (local.set $node_id
        (call $create_node
            (global.get $AST_IMPORT)
            (local.get $parent_id)))

    ;; Parse module name (string)
    (global.set $current_token (call $next_token))
    (local.set $token_type
        (i32.load (global.get $current_token)))

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_STRING))
        (then
            (call $store_string_value
                (local.get $node_id)
                (i32.load (global.get $current_token))      ;; String ptr
                (i32.load offset=4 (global.get $current_token)))) ;; Length
        (else (return (i32.const 0))))

    ;; Parse imported name (string)
    (global.set $current_token (call $next_token))
    (local.set $token_type
        (i32.load (global.get $current_token)))

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_STRING))
        (then
            (call $store_string_value
                (local.get $node_id)
                (i32.load (global.get $current_token))
                (i32.load offset=4 (global.get $current_token))))
        (else (return (i32.const 0))))

    (local.get $node_id)
)

;; Parse export declaration
(func $parse_export
    (param $parent_id i32)
    (result i32)
    (local $node_id i32)
    (local $token_type i32)

    ;; Create export node
    (local.set $node_id
        (call $create_node
            (global.get $AST_EXPORT)
            (local.get $parent_id)))

    ;; Parse export name (string)
    (global.set $current_token (call $next_token))
    (local.set $token_type
        (i32.load (global.get $current_token)))

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_STRING))
        (then
            (call $store_string_value
                (local.get $node_id)
                (i32.load (global.get $current_token))
                (i32.load offset=4 (global.get $current_token))))
        (else (return (i32.const 0))))

    (local.get $node_id)
)

;; Parse type definition
(func $parse_type
    (param $parent_id i32)
    (result i32)
    (local $node_id i32)
    (local $token_type i32)

    ;; Create type node
    (local.set $node_id
        (call $create_node
            (global.get $AST_TYPE)
            (local.get $parent_id)))

    ;; Parse type name (identifier)
    (global.set $current_token (call $next_token))
    (local.set $token_type
        (i32.load (global.get $current_token)))

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_IDENTIFIER))
        (then
            (call $store_string_value
                (local.get $node_id)
                (i32.load (global.get $current_token))
                (i32.load offset=4 (global.get $current_token))))
        (else (return (i32.const 0))))

    (local.get $node_id)
)

;; Parse any top level element
(func $parse_top_level
    (param $parent_id i32)
    (result i32)
    (local $node_id i32)
    (local $token_type i32)

    ;; Get token type
    (local.set $token_type
        (i32.load (global.get $current_token)))

    ;; Parse based on type
    (local.set $node_id
        (if (result i32)
            (i32.eq (local.get $token_type) (global.get $TOKEN_LPAREN))
            (then
                ;; Look at next token
                (global.set $current_token (call $next_token))
                (local.set $token_type
                    (i32.load (global.get $current_token)))

                ;; Check keyword
                (if (result i32)
                    (i32.eq (local.get $token_type) (global.get $TOKEN_KEYWORD))
                    (then
                        (call $parse_keyword_element (local.get $parent_id)))
                    (else (i32.const 0))))
            (else (i32.const 0))))

    ;; Return node ID
    (local.get $node_id)
)

;; Parse keyword element
(func $parse_keyword_element
    (param $parent_id i32)
    (result i32)
    (local $token_ptr i32)
    (local $token_len i32)
    (local $node_id i32)

    ;; Get token info
    (local.set $token_ptr
        (i32.load (global.get $current_token)))
    (local.set $token_len
        (i32.load offset=4 (global.get $current_token)))

    ;; Check each keyword type
    (if (call $is_keyword
            (global.get $current_token)
            (i32.const 0x1000)  ;; "func" keyword ptr
            (i32.const 4))      ;; Length = 4
        (then
            (local.set $node_id
                (call $parse_func (local.get $parent_id)))
            (return (local.get $node_id))))

    (if (call $is_keyword
            (global.get $current_token)
            (i32.const 0x1010)  ;; "import" keyword ptr
            (i32.const 6))      ;; Length = 6
        (then
            (local.set $node_id
                (call $parse_import (local.get $parent_id)))
            (return (local.get $node_id))))

    (if (call $is_keyword
            (global.get $current_token)
            (i32.const 0x1020)  ;; "export" keyword ptr
            (i32.const 6))      ;; Length = 6
        (then
            (local.set $node_id
                (call $parse_export (local.get $parent_id)))
            (return (local.get $node_id))))

    (if (call $is_keyword
            (global.get $current_token)
            (i32.const 0x1030)  ;; "type" keyword ptr
            (i32.const 4))      ;; Length = 4
        (then
            (local.set $node_id
                (call $parse_type (local.get $parent_id)))
            (return (local.get $node_id))))

    (i32.const 0)  ;; Unknown keyword
)

;; Parse control flow instruction
(func $parse_control_flow
    (param $parent_id i32)
    (param $node_type i32)     ;; AST_BLOCK, AST_LOOP, or AST_IF
    (result i32)
    (local $node_id i32)
    (local $token_type i32)

    ;; Create control flow node
    (local.set $node_id
        (call $create_node
            (local.get $node_type)
            (local.get $parent_id)))

    ;; Parse optional label
    (global.set $current_token (call $next_token))
    (local.set $token_type
        (i32.load (global.get $current_token)))

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_IDENTIFIER))
        (then
            ;; Store label
            (call $store_string_value
                (local.get $node_id)
                (i32.load (global.get $current_token))
                (i32.load offset=4 (global.get $current_token)))

            ;; Get next token
            (global.set $current_token (call $next_token))
            (local.set $token_type
                (i32.load (global.get $current_token)))))

    ;; Parse block contents (instructions)
    (loop $parse_contents
        (if (i32.eq (local.get $token_type) (global.get $TOKEN_LPAREN))
            (then
                ;; Parse nested instruction
                (global.set $current_token (call $next_token))
                (call $parse_instruction (local.get $node_id))

                ;; Continue parsing
                (global.set $current_token (call $next_token))
                (local.set $token_type
                    (i32.load (global.get $current_token)))
                (br $parse_contents))))

    (local.get $node_id)
)

;; Type validation constants
(global $TYPE_I32 i32 (i32.const 1))
(global $TYPE_I64 i32 (i32.const 2))
(global $TYPE_F32 i32 (i32.const 3))
(global $TYPE_F64 i32 (i32.const 4))
(global $TYPE_FUNCREF i32 (i32.const 5))
(global $TYPE_EXTERNREF i32 (i32.const 6))

;; Store type information in AST node
(func $store_type_info
    (param $node_id i32)
    (param $type i32)          ;; Type constant
    (param $nullable i32)      ;; 1 if nullable, 0 if not
    (local $node_ptr i32)

    ;; Calculate node pointer
    (local.set $node_ptr
        (i32.add
            (i32.const 0x3000)
            (i32.mul (local.get $node_id) (i32.const 32))))

    ;; Store type and nullable flag
    (i32.store offset=24 (local.get $node_ptr) (local.get $type))
    (i32.store offset=28 (local.get $node_ptr) (local.get $nullable))
)

;; Parse type reference (e.g. i32, f64, etc)
(func $parse_type_ref
    (param $node_id i32)
    (result i32)              ;; Returns type constant or 0 if invalid
    (local $token_type i32)
    (local $token_ptr i32)

    (local.set $token_type
        (i32.load (global.get $current_token)))

    (if (i32.eq (local.get $token_type) (global.get $TOKEN_IDENTIFIER))
        (then
            ;; Check each type identifier
            (local.set $token_ptr (i32.load (global.get $current_token)))

            (if (call $compare_strings
                    (local.get $token_ptr)
                    (i32.const 0x2000)  ;; "i32" type string ptr
                    (i32.const 3))      ;; Length = 3
                (then (return (global.get $TYPE_I32))))

            (if (call $compare_strings
                    (local.get $token_ptr)
                    (i32.const 0x2010)  ;; "i64" type string ptr
                    (i32.const 3))      ;; Length = 3
                (then (return (global.get $TYPE_I64))))

            (if (call $compare_strings
                    (local.get $token_ptr)
                    (i32.const 0x2020)  ;; "f32" type string ptr
                    (i32.const 3))      ;; Length = 3
                (then (return (global.get $TYPE_F32))))

            (if (call $compare_strings
                    (local.get $token_ptr)
                    (i32.const 0x2030)  ;; "f64" type string ptr
                    (i32.const 3))      ;; Length = 3
                (then (return (global.get $TYPE_F64))))

            (if (call $compare_strings
                    (local.get $token_ptr)
                    (i32.const 0x2040)  ;; "funcref" type string ptr
                    (i32.const 7))      ;; Length = 7
                (then (return (global.get $TYPE_FUNCREF))))

            (if (call $compare_strings
                    (local.get $token_ptr)
                    (i32.const 0x2050)  ;; "externref" type string ptr
                    (i32.const 9))      ;; Length = 9
                (then (return (global.get $TYPE_EXTERNREF))))))

    (i32.const 0)  ;; Invalid type
)

;; Update parameter parsing to include type information
(func $parse_param
    (param $parent_id i32)
    (result i32)
    (local $node_id i32)
    (local $type i32)

    ;; Create parameter node
    (local.set $node_id
        (call $create_node
            (global.get $AST_PARAM)
            (local.get $parent_id)))

    ;; Parse type
    (global.set $current_token (call $next_token))
    (local.set $type (call $parse_type_ref (local.get $node_id)))

    ;; Store type info if valid
    (if (local.get $type)
        (then
            (call $store_type_info
                (local.get $node_id)
                (local.get $type)
                (i32.const 0))  ;; Not nullable
            (local.get $node_id))
        (else (i32.const 0)))  ;; Invalid type
)
