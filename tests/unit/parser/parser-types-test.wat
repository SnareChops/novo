;; Parser Types Test
;; Tests type parsing functions for primitive and compound types

(module $parser_types_test
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import the function to test
  (import "parser_types" "parse_type" (func $parse_type (param i32) (result i32 i32)))

  ;; Import token storage and scanning
  (import "novo_lexer" "scan_text" (func $scan_text (param i32) (param i32) (result i32)))
  (import "lexer_token_storage" "store_token" (func $store_token (param i32) (param i32) (result i32)))

  ;; Import AST functions
  (import "ast_memory" "init_memory_manager" (func $init_memory_manager))
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))

  ;; Import node type constants
  (import "ast_node_types" "TYPE_PRIMITIVE" (global $TYPE_PRIMITIVE i32))
  (import "ast_node_types" "TYPE_LIST" (global $TYPE_LIST i32))
  (import "ast_node_types" "TYPE_OPTION" (global $TYPE_OPTION i32))

  ;; Import token constants
  (import "lexer_tokens" "TOKEN_KW_S32" (global $TOKEN_KW_S32 i32))
  (import "lexer_tokens" "TOKEN_KW_U64" (global $TOKEN_KW_U64 i32))
  (import "lexer_tokens" "TOKEN_KW_BOOL" (global $TOKEN_KW_BOOL i32))
  (import "lexer_tokens" "TOKEN_KW_STRING" (global $TOKEN_KW_STRING i32))

  ;; Test data for type parsing
  (data (i32.const 1000) "s32")        ;; primitive type
  (data (i32.const 1010) "u64")        ;; primitive type
  (data (i32.const 1020) "bool")       ;; primitive type
  (data (i32.const 1030) "string")     ;; primitive type
  (data (i32.const 1040) "list<s32>")  ;; list type
  (data (i32.const 1055) "option<u64>") ;; option type

  ;; Helper function to store test input and scan tokens
  (func $setup_type_test (param $input_start i32) (param $input_len i32) (result i32)
    (local $i i32)

    ;; Clear memory area starting from position 0
    (local.set $i (i32.const 0))
    (loop $clear_loop
      (if (i32.lt_u (local.get $i) (local.get $input_len))
        (then
          (i32.store8
            (local.get $i)
            (i32.load8_u (i32.add (local.get $input_start) (local.get $i))))
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $clear_loop)
        )
      )
    )

    ;; Scan the input to generate tokens
    (call $scan_text (i32.const 0) (local.get $input_len))
    ;; Return success (number of tokens found)
  )

  ;; Test parsing primitive type s32
  (func $test_parse_type_s32 (export "test_parse_type_s32") (result i32)
    (local $token_count i32)
    (local $ast_node i32)
    (local $next_pos i32)
    (local $node_type i32)

    ;; Initialize AST system
    (call $init_memory_manager)

    ;; Setup input "s32"
    (local.set $token_count (call $setup_type_test (i32.const 1000) (i32.const 3)))

    ;; Parse type starting from token position 0
    (call $parse_type (i32.const 0))
    (local.set $next_pos)    ;; second return value
    (local.set $ast_node)    ;; first return value

    ;; Check that parsing succeeded
    (if (i32.eqz (local.get $ast_node))
      (then (return (i32.const 0)))
    )

    ;; Check node type
    (local.set $node_type (call $get_node_type (local.get $ast_node)))
    (if (i32.ne (local.get $node_type) (global.get $TYPE_PRIMITIVE))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test parsing primitive type u64
  (func $test_parse_type_u64 (export "test_parse_type_u64") (result i32)
    (local $token_count i32)
    (local $ast_node i32)
    (local $next_pos i32)
    (local $node_type i32)

    ;; Initialize AST system
    (call $init_memory_manager)

    ;; Setup input "u64"
    (local.set $token_count (call $setup_type_test (i32.const 1010) (i32.const 3)))

    ;; Parse type starting from token position 0
    (call $parse_type (i32.const 0))
    (local.set $next_pos)    ;; second return value
    (local.set $ast_node)    ;; first return value

    ;; Check that parsing succeeded
    (if (i32.eqz (local.get $ast_node))
      (then (return (i32.const 0)))
    )

    ;; Check node type
    (local.set $node_type (call $get_node_type (local.get $ast_node)))
    (if (i32.ne (local.get $node_type) (global.get $TYPE_PRIMITIVE))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test parsing primitive type bool
  (func $test_parse_type_bool (export "test_parse_type_bool") (result i32)
    (local $token_count i32)
    (local $ast_node i32)
    (local $next_pos i32)
    (local $node_type i32)

    ;; Initialize AST system
    (call $init_memory_manager)

    ;; Setup input "bool"
    (local.set $token_count (call $setup_type_test (i32.const 1020) (i32.const 4)))

    ;; Parse type starting from token position 0
    (call $parse_type (i32.const 0))
    (local.set $next_pos)    ;; second return value
    (local.set $ast_node)    ;; first return value

    ;; Check that parsing succeeded
    (if (i32.eqz (local.get $ast_node))
      (then (return (i32.const 0)))
    )

    ;; Check node type
    (local.set $node_type (call $get_node_type (local.get $ast_node)))
    (if (i32.ne (local.get $node_type) (global.get $TYPE_PRIMITIVE))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test parsing primitive type string
  (func $test_parse_type_string (export "test_parse_type_string") (result i32)
    (local $token_count i32)
    (local $ast_node i32)
    (local $next_pos i32)
    (local $node_type i32)

    ;; Initialize AST system
    (call $init_memory_manager)

    ;; Setup input "string"
    (local.set $token_count (call $setup_type_test (i32.const 1030) (i32.const 6)))

    ;; Parse type starting from token position 0
    (call $parse_type (i32.const 0))
    (local.set $next_pos)    ;; second return value
    (local.set $ast_node)    ;; first return value

    ;; Check that parsing succeeded
    (if (i32.eqz (local.get $ast_node))
      (then (return (i32.const 0)))
    )

    ;; Check node type
    (local.set $node_type (call $get_node_type (local.get $ast_node)))
    (if (i32.ne (local.get $node_type) (global.get $TYPE_PRIMITIVE))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test position advancement
  (func $test_parse_type_position_advancement (export "test_parse_type_position_advancement") (result i32)
    (local $token_count i32)
    (local $ast_node i32)
    (local $next_pos i32)

    ;; Initialize AST system
    (call $init_memory_manager)

    ;; Setup input "s32"
    (local.set $token_count (call $setup_type_test (i32.const 1000) (i32.const 3)))

    ;; Parse type starting from token position 0
    (call $parse_type (i32.const 0))
    (local.set $next_pos)    ;; second return value
    (local.set $ast_node)    ;; first return value

    ;; Check that parsing succeeded
    (if (i32.eqz (local.get $ast_node))
      (then (return (i32.const 0)))
    )

    ;; Check that position was advanced (should be at least 1)
    (if (i32.le_u (local.get $next_pos) (i32.const 0))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success
  )

  ;; Test error handling for invalid type
  (func $test_parse_type_error_handling (export "test_parse_type_error_handling") (result i32)
    (local $ast_node i32)
    (local $next_pos i32)

    ;; Initialize AST system
    (call $init_memory_manager)

    ;; Try to parse type at invalid position (should return 0)
    (call $parse_type (i32.const 999))  ;; Invalid token position
    (local.set $next_pos)    ;; second return value
    (local.set $ast_node)    ;; first return value

    ;; Check that parsing failed (returns 0)
    (if (i32.ne (local.get $ast_node) (i32.const 0))
      (then (return (i32.const 0)))
    )

    (i32.const 1)  ;; Success (correctly failed)
  )

  ;; Run all tests
  (func $run_tests (export "run_tests") (result i32)
    (local $result i32)

    ;; Test 1: parse s32 type
    (local.set $result (call $test_parse_type_s32))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 2: parse u64 type
    (local.set $result (call $test_parse_type_u64))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 3: parse bool type
    (local.set $result (call $test_parse_type_bool))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 4: parse string type
    (local.set $result (call $test_parse_type_string))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 5: position advancement
    (local.set $result (call $test_parse_type_position_advancement))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; Test 6: error handling
    (local.set $result (call $test_parse_type_error_handling))
    (if (i32.eqz (local.get $result))
      (then (return (i32.const 0)))
    )

    ;; All tests passed
    (i32.const 1)
  )
)
