;; Parser test module
;; Interface: parser_test.wit
(module
    ;; Import memory and parser functions
    (import "memory" "memory" (memory 1))
    (import "parser" "init-parser" (func $init_parser (param i32 i32) (result i32)))
    (import "parser" "parse-root" (func $parse_root (result i32)))
    (import "parser" "get-node-type" (func $get_node_type (param i32) (result i32)))
    (import "parser" "get-node-parent" (func $get_node_parent (param i32) (result i32)))
    (import "parser" "get-ast-root" (func $get_ast_root (result i32)))

    ;; AST Node type constants (matching parser module)
    (global $AST_MODULE i32 (i32.const 10))
    (global $AST_COMPONENT i32 (i32.const 11))
    (global $AST_INTERFACE i32 (i32.const 12))
    (global $AST_WORLD i32 (i32.const 13))
    (global $AST_FUNC i32 (i32.const 14))
    (global $AST_IMPORT i32 (i32.const 15))
    (global $AST_EXPORT i32 (i32.const 16))
    (global $AST_TYPE i32 (i32.const 17))
    (global $AST_INSTR i32 (i32.const 18))
    (global $AST_BLOCK i32 (i32.const 19))
    (global $AST_LOOP i32 (i32.const 20))

    ;; Test data section
    (data (i32.const 0x0000) "(module)")  ;; Simple module
    (data (i32.const 0x0010) "(component)") ;; Simple component
    (data (i32.const 0x0020) "(module (func))") ;; Module with function
    (data (i32.const 0x0040) "(module (import \"env\" \"memory\"))") ;; Import test
    (data (i32.const 0x0060) "(module (export \"add\" (func $add)))") ;; Export test
    (data (i32.const 0x0080) "(module (type $t (func (param i32) (result i32))))") ;; Type test
    (data (i32.const 0x00A0) "(module (func (i32.const 42)))") ;; Instruction test
    (data (i32.const 0x00C0) "(module (func (block $label (i32.const 1) (i32.const 2))))") ;; Block test
    (data (i32.const 0x00F0) "(module (func (loop $loop (local.get 0) (br $loop))))") ;; Loop test
    (data (i32.const 0x0120) "(module (func (if (local.get 0) (then (i32.const 1)))))") ;; If test
    (data (i32.const 0x0150) "(module (func (param i32) (param f64)))") ;; Parameter types
    (data (i32.const 0x0180) "(module (func (result externref)))") ;; Result type
    (data (i32.const 0x01A0) "(module (type $func (func (param i32) (result i32))))") ;; Type definition

    ;; Error codes
    (global $ERROR_INIT_FAILED i32 (i32.const 1))
    (global $ERROR_PARSE_FAILED i32 (i32.const 2))
    (global $ERROR_WRONG_NODE_TYPE i32 (i32.const 3))
    (global $ERROR_WRONG_PARENT i32 (i32.const 4))
    (global $ERROR_INVALID_TYPE i32 (i32.const 5))

    ;; Error storage
    (global $last_error (mut i32) (i32.const 0))

    ;; Store error code
    (func $report_error
        (param $error_code i32)
        (global.set $last_error (local.get $error_code)))

    ;; Test entry point
    (func $test (export "test") (result i32)
        ;; Run all test cases
        (call $test_init_parser)
        (if (global.get $last_error)
            (then (return (global.get $last_error))))

        (call $test_parse_module)
        (if (global.get $last_error)
            (then (return (global.get $last_error))))

        (call $test_parse_component)
        (if (global.get $last_error)
            (then (return (global.get $last_error))))

        (call $test_parse_function)
        (if (global.get $last_error)
            (then (return (global.get $last_error))))

        (call $test_parse_import)
        (if (global.get $last_error)
            (then (return (global.get $last_error))))

        (call $test_parse_export)
        (if (global.get $last_error)
            (then (return (global.get $last_error))))

        (call $test_parse_type)
        (if (global.get $last_error)
            (then (return (global.get $last_error))))

        (call $test_parse_instruction)
        (if (global.get $last_error)
            (then (return (global.get $last_error))))

        (call $test_parse_block)
        (if (global.get $last_error)
            (then (return (global.get $last_error))))

        (call $test_parse_loop)
        (if (global.get $last_error)
            (then (return (global.get $last_error))))

        (call $test_param_types)
        (if (global.get $last_error)
            (then (return (global.get $last_error))))

        (i32.const 0) ;; All tests passed
    )

    ;; Test parser initialization
    (func $test_init_parser
        ;; Test with simple module
        (if (i32.eqz
                (call $init_parser
                    (i32.const 0x0000)  ;; "(module)"
                    (i32.const 8)))     ;; length
            (then
                (call $report_error (global.get $ERROR_INIT_FAILED))
                (return)))
    )

    ;; Test parsing a simple module
    (func $test_parse_module
        (local $root_id i32)

        ;; Initialize parser with module test data
        (if (i32.eqz (call $init_parser
                (i32.const 0x0000)  ;; "(module)"
                (i32.const 8)))     ;; length
            (then
                (call $report_error (global.get $ERROR_INIT_FAILED))
                (return)))

        ;; Parse and get root node
        (local.set $root_id (call $parse_root))
        (if (i32.eqz (local.get $root_id))
            (then
                (call $report_error (global.get $ERROR_PARSE_FAILED))
                (return)))

        ;; Verify node type is module
        (if (i32.ne
                (call $get_node_type (local.get $root_id))
                (global.get $AST_MODULE))
            (then
                (call $report_error (global.get $ERROR_WRONG_NODE_TYPE))
                (return)))

        ;; Verify root has no parent
        (if (call $get_node_parent (local.get $root_id))
            (then
                (call $report_error (global.get $ERROR_WRONG_PARENT))
                (return)))
    )

    ;; Test parsing a simple component
    (func $test_parse_component
        (local $root_id i32)

        ;; Initialize parser with component test data
        (if (i32.eqz (call $init_parser
                (i32.const 0x0010)  ;; "(component)"
                (i32.const 11)))    ;; length
            (then
                (call $report_error (global.get $ERROR_INIT_FAILED))
                (return)))

        ;; Parse and get root node
        (local.set $root_id (call $parse_root))
        (if (i32.eqz (local.get $root_id))
            (then
                (call $report_error (global.get $ERROR_PARSE_FAILED))
                (return)))

        ;; Verify node type is component
        (if (i32.ne
                (call $get_node_type (local.get $root_id))
                (global.get $AST_COMPONENT))
            (then
                (call $report_error (global.get $ERROR_WRONG_NODE_TYPE))
                (return)))

        ;; Verify root has no parent
        (if (call $get_node_parent (local.get $root_id))
            (then
                (call $report_error (global.get $ERROR_WRONG_PARENT))
                (return)))
    )

    ;; Test parsing a function definition
    (func $test_parse_function
        (local $root_id i32)
        (local $func_node i32)

        ;; Initialize parser with function test data
        (if (i32.eqz (call $init_parser
                (i32.const 0x0020)  ;; "(module (func))"
                (i32.const 14)))    ;; length
            (then
                (call $report_error (global.get $ERROR_INIT_FAILED))
                (return)))

        ;; Parse module
        (local.set $root_id (call $parse_root))
        (if (i32.eqz (local.get $root_id))
            (then
                (call $report_error (global.get $ERROR_PARSE_FAILED))
                (return)))

        ;; Get first child (function node)
        (local.set $func_node
            (call $get_first_child (local.get $root_id)))

        ;; Verify function node exists and type is correct
        (if (i32.eqz (local.get $func_node))
            (then
                (call $report_error (global.get $ERROR_PARSE_FAILED))
                (return)))

        (if (i32.ne
                (call $get_node_type (local.get $func_node))
                (global.get $AST_FUNC))
            (then
                (call $report_error (global.get $ERROR_WRONG_NODE_TYPE))
                (return)))
    )

    ;; Test parsing an import declaration
    (func $test_parse_import
        (local $root_id i32)
        (local $import_id i32)

        ;; Initialize parser with import test data
        (if (i32.eqz
                (call $init_parser
                    (i32.const 0x0040)    ;; Import test data
                    (i32.const 32)))      ;; Length
            (then
                (call $report_error (global.get $ERROR_INIT_FAILED))
                (return)))

        ;; Parse module
        (local.set $root_id (call $parse_root))
        (if (i32.eqz (local.get $root_id))
            (then
                (call $report_error (global.get $ERROR_PARSE_FAILED))
                (return)))

        ;; Check import node
        (local.set $import_id
            (i32.load offset=8   ;; first_child
                (i32.add
                    (i32.const 0x3000)
                    (i32.mul (local.get $root_id) (i32.const 32)))))

        (if (i32.ne
                (call $get_node_type (local.get $import_id))
                (global.get $AST_IMPORT))
            (then
                (call $report_error (global.get $ERROR_WRONG_NODE_TYPE))
                (return)))
    )

    ;; Test parsing an export declaration
    (func $test_parse_export
        (local $root_id i32)
        (local $export_id i32)

        ;; Initialize parser with export test data
        (if (i32.eqz
                (call $init_parser
                    (i32.const 0x0060)    ;; Export test data
                    (i32.const 32)))      ;; Length
            (then
                (call $report_error (global.get $ERROR_INIT_FAILED))
                (return)))

        ;; Parse module
        (local.set $root_id (call $parse_root))
        (if (i32.eqz (local.get $root_id))
            (then
                (call $report_error (global.get $ERROR_PARSE_FAILED))
                (return)))

        ;; Check export node
        (local.set $export_id
            (i32.load offset=8   ;; first_child
                (i32.add
                    (i32.const 0x3000)
                    (i32.mul (local.get $root_id) (i32.const 32)))))

        (if (i32.ne
                (call $get_node_type (local.get $export_id))
                (global.get $AST_EXPORT))
            (then
                (call $report_error (global.get $ERROR_WRONG_NODE_TYPE))
                (return)))
    )

    ;; Test parsing a type declaration
    (func $test_parse_type
        (local $root_id i32)
        (local $type_id i32)

        ;; Initialize parser with type test data
        (if (i32.eqz
                (call $init_parser
                    (i32.const 0x0080)    ;; Type test data
                    (i32.const 32)))      ;; Length
            (then
                (call $report_error (global.get $ERROR_INIT_FAILED))
                (return)))

        ;; Parse module
        (local.set $root_id (call $parse_root))
        (if (i32.eqz (local.get $root_id))
            (then
                (call $report_error (global.get $ERROR_PARSE_FAILED))
                (return)))

        ;; Check type node
        (local.set $type_id
            (i32.load offset=8   ;; first_child
                (i32.add
                    (i32.const 0x3000)
                    (i32.mul (local.get $root_id) (i32.const 32)))))

        (if (i32.ne
                (call $get_node_type (local.get $type_id))
                (global.get $AST_TYPE))
            (then
                (call $report_error (global.get $ERROR_WRONG_NODE_TYPE))
                (return)))
    )

    ;; Test parsing an instruction
    (func $test_parse_instruction
        (local $root_id i32)
        (local $func_id i32)
        (local $instr_id i32)

        ;; Initialize parser with instruction test data
        (if (i32.eqz
                (call $init_parser
                    (i32.const 0x00A0)    ;; Instruction test data
                    (i32.const 32)))      ;; Length
            (then
                (call $report_error (global.get $ERROR_INIT_FAILED))
                (return)))

        ;; Parse module
        (local.set $root_id (call $parse_root))
        (if (i32.eqz (local.get $root_id))
            (then
                (call $report_error (global.get $ERROR_PARSE_FAILED))
                (return)))

        ;; Get function node
        (local.set $func_id
            (i32.load offset=8   ;; first_child
                (i32.add
                    (i32.const 0x3000)
                    (i32.mul (local.get $root_id) (i32.const 32)))))

        ;; Get instruction node
        (local.set $instr_id
            (i32.load offset=8   ;; first_child
                (i32.add
                    (i32.const 0x3000)
                    (i32.mul (local.get $func_id) (i32.const 32)))))

        ;; Check instruction type
        (if (i32.ne
                (call $get_node_type (local.get $instr_id))
                (global.get $AST_INSTR))
            (then
                (call $report_error (global.get $ERROR_WRONG_NODE_TYPE))
                (return)))
    )

    ;; Test parsing a block
    (func $test_parse_block
        (local $root_id i32)
        (local $func_id i32)
        (local $block_id i32)

        ;; Initialize parser with block test data
        (if (i32.eqz
                (call $init_parser
                    (i32.const 0x00C0)    ;; Block test data
                    (i32.const 48)))      ;; Length
            (then
                (call $report_error (global.get $ERROR_INIT_FAILED))
                (return)))

        ;; Parse module
        (local.set $root_id (call $parse_root))
        (if (i32.eqz (local.get $root_id))
            (then
                (call $report_error (global.get $ERROR_PARSE_FAILED))
                (return)))

        ;; Check block node type
        (local.set $func_id
            (i32.load offset=8   ;; first_child
                (i32.add
                    (i32.const 0x3000)
                    (i32.mul (local.get $root_id) (i32.const 32)))))

        (local.set $block_id
            (i32.load offset=8   ;; first_child
                (i32.add
                    (i32.const 0x3000)
                    (i32.mul (local.get $func_id) (i32.const 32)))))

        (if (i32.ne
                (call $get_node_type (local.get $block_id))
                (global.get $AST_BLOCK))
            (then
                (call $report_error (global.get $ERROR_WRONG_NODE_TYPE))
                (return)))
    )

    ;; Test parsing a loop
    (func $test_parse_loop
        (local $root_id i32)
        (local $func_id i32)
        (local $loop_id i32)

        ;; Initialize parser with loop test data
        (if (i32.eqz
                (call $init_parser
                    (i32.const 0x00F0)    ;; Loop test data
                    (i32.const 48)))      ;; Length
            (then
                (call $report_error (global.get $ERROR_INIT_FAILED))
                (return)))

        ;; Parse module
        (local.set $root_id (call $parse_root))
        (if (i32.eqz (local.get $root_id))
            (then
                (call $report_error (global.get $ERROR_PARSE_FAILED))
                (return)))

        ;; Check loop node type
        (local.set $func_id
            (i32.load offset=8   ;; first_child
                (i32.add
                    (i32.const 0x3000)
                    (i32.mul (local.get $root_id) (i32.const 32)))))

        (local.set $loop_id
            (i32.load offset=8   ;; first_child
                (i32.add
                    (i32.const 0x3000)
                    (i32.mul (local.get $func_id) (i32.const 32)))))

        (if (i32.ne
                (call $get_node_type (local.get $loop_id))
                (global.get $AST_LOOP))
            (then
                (call $report_error (global.get $ERROR_WRONG_NODE_TYPE))
                (return)))
    )

    ;; Test parameter type parsing
    (func $test_param_types
        (local $root_id i32)
        (local $func_id i32)
        (local $param_id i32)

        ;; Initialize parser
        (if (i32.eqz
                (call $init_parser
                    (i32.const 0x0150)    ;; Parameter types test data
                    (i32.const 48)))      ;; Length
            (then
                (call $report_error (global.get $ERROR_INIT_FAILED))
                (return)))

        ;; Parse module
        (local.set $root_id (call $parse_root))
        (if (i32.eqz (local.get $root_id))
            (then
                (call $report_error (global.get $ERROR_PARSE_FAILED))
                (return)))

        ;; Check first parameter type
        (local.set $func_id
            (i32.load offset=8   ;; first_child
                (i32.add
                    (i32.const 0x3000)
                    (i32.mul (local.get $root_id) (i32.const 32)))))

        (local.set $param_id
            (i32.load offset=8   ;; first_child
                (i32.add
                    (i32.const 0x3000)
                    (i32.mul (local.get $func_id) (i32.const 32)))))

        (if (i32.ne
                (i32.load offset=24  ;; type field
                    (i32.add
                        (i32.const 0x3000)
                        (i32.mul (local.get $param_id) (i32.const 32))))
                (global.get $TYPE_I32))
            (then
                (call $report_error (global.get $ERROR_INVALID_TYPE))
                (return)))
    )

    ;; Helper to get first child of a node
    (func $get_first_child
        (param $node_id i32)
        (result i32)
        (i32.load offset=8
            (i32.add
                (i32.const 0x3000)
                (i32.mul (local.get $node_id) (i32.const 32)))))

    ;; Export test interface
    (export "get-error" (func $get_error))
    (func $get_error (result i32)
        (global.get $last_error))
)
