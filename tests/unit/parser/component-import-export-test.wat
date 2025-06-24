;; Component Complex Parsing Test
;; Tests parsing of components with imports and exports

(module $component_complex_test
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import lexer for tokenization
  (import "novo_lexer" "scan_text" (func $scan_text (param i32 i32) (result i32)))

  ;; Import parser functions
  (import "parser_components" "parse_component_declaration" (func $parse_component_declaration (param i32) (result i32 i32)))

  ;; Import AST utilities
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "ast_node_core" "get_child_count" (func $get_child_count (param i32) (result i32)))
  (import "ast_node_types" "DECL_COMPONENT" (global $DECL_COMPONENT i32))

  ;; Helper function to store string in memory at position 0
  (func $store_test_input (param $str_ptr i32) (param $str_len i32)
    (local $i i32)

    (local.set $i (i32.const 0))
    (loop $copy_loop
      (if (i32.lt_u (local.get $i) (local.get $str_len))
        (then
          (i32.store8
            (local.get $i)
            (i32.load8_u
              (i32.add (local.get $str_ptr) (local.get $i))))
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $copy_loop)))))

  ;; Test component with imports and exports
  (func $test_component_with_imports_exports (export "test_component_with_imports_exports") (result i32)
    (local $input_start i32)
    (local $input_len i32)
    (local $token_count i32)
    (local $ast_node i32)
    (local $next_pos i32)
    (local $node_type i32)
    (local $child_count i32)

    ;; Test input: "component processor { import wasi:io export compute }"
    (local.set $input_start (i32.const 2048))
    (local.set $input_len (i32.const 53))

    ;; Store test string: "component processor { import wasi:io export compute }"
    ;; "component "
    (i32.store8 offset=0 (local.get $input_start) (i32.const 99))   ;; 'c'
    (i32.store8 offset=1 (local.get $input_start) (i32.const 111))  ;; 'o'
    (i32.store8 offset=2 (local.get $input_start) (i32.const 109))  ;; 'm'
    (i32.store8 offset=3 (local.get $input_start) (i32.const 112))  ;; 'p'
    (i32.store8 offset=4 (local.get $input_start) (i32.const 111))  ;; 'o'
    (i32.store8 offset=5 (local.get $input_start) (i32.const 110))  ;; 'n'
    (i32.store8 offset=6 (local.get $input_start) (i32.const 101))  ;; 'e'
    (i32.store8 offset=7 (local.get $input_start) (i32.const 110))  ;; 'n'
    (i32.store8 offset=8 (local.get $input_start) (i32.const 116))  ;; 't'
    (i32.store8 offset=9 (local.get $input_start) (i32.const 32))   ;; ' '
    ;; "processor "
    (i32.store8 offset=10 (local.get $input_start) (i32.const 112)) ;; 'p'
    (i32.store8 offset=11 (local.get $input_start) (i32.const 114)) ;; 'r'
    (i32.store8 offset=12 (local.get $input_start) (i32.const 111)) ;; 'o'
    (i32.store8 offset=13 (local.get $input_start) (i32.const 99))  ;; 'c'
    (i32.store8 offset=14 (local.get $input_start) (i32.const 101)) ;; 'e'
    (i32.store8 offset=15 (local.get $input_start) (i32.const 115)) ;; 's'
    (i32.store8 offset=16 (local.get $input_start) (i32.const 115)) ;; 's'
    (i32.store8 offset=17 (local.get $input_start) (i32.const 111)) ;; 'o'
    (i32.store8 offset=18 (local.get $input_start) (i32.const 114)) ;; 'r'
    (i32.store8 offset=19 (local.get $input_start) (i32.const 32))  ;; ' '
    ;; "{ import wasi:io export compute }"
    (i32.store8 offset=20 (local.get $input_start) (i32.const 123)) ;; '{'
    (i32.store8 offset=21 (local.get $input_start) (i32.const 32))  ;; ' '
    (i32.store8 offset=22 (local.get $input_start) (i32.const 105)) ;; 'i'
    (i32.store8 offset=23 (local.get $input_start) (i32.const 109)) ;; 'm'
    (i32.store8 offset=24 (local.get $input_start) (i32.const 112)) ;; 'p'
    (i32.store8 offset=25 (local.get $input_start) (i32.const 111)) ;; 'o'
    (i32.store8 offset=26 (local.get $input_start) (i32.const 114)) ;; 'r'
    (i32.store8 offset=27 (local.get $input_start) (i32.const 116)) ;; 't'
    (i32.store8 offset=28 (local.get $input_start) (i32.const 32))  ;; ' '
    (i32.store8 offset=29 (local.get $input_start) (i32.const 119)) ;; 'w'
    (i32.store8 offset=30 (local.get $input_start) (i32.const 97))  ;; 'a'
    (i32.store8 offset=31 (local.get $input_start) (i32.const 115)) ;; 's'
    (i32.store8 offset=32 (local.get $input_start) (i32.const 105)) ;; 'i'
    (i32.store8 offset=33 (local.get $input_start) (i32.const 58))  ;; ':'
    (i32.store8 offset=34 (local.get $input_start) (i32.const 105)) ;; 'i'
    (i32.store8 offset=35 (local.get $input_start) (i32.const 111)) ;; 'o'
    (i32.store8 offset=36 (local.get $input_start) (i32.const 32))  ;; ' '
    (i32.store8 offset=37 (local.get $input_start) (i32.const 101)) ;; 'e'
    (i32.store8 offset=38 (local.get $input_start) (i32.const 120)) ;; 'x'
    (i32.store8 offset=39 (local.get $input_start) (i32.const 112)) ;; 'p'
    (i32.store8 offset=40 (local.get $input_start) (i32.const 111)) ;; 'o'
    (i32.store8 offset=41 (local.get $input_start) (i32.const 114)) ;; 'r'
    (i32.store8 offset=42 (local.get $input_start) (i32.const 116)) ;; 't'
    (i32.store8 offset=43 (local.get $input_start) (i32.const 32))  ;; ' '
    (i32.store8 offset=44 (local.get $input_start) (i32.const 99))  ;; 'c'
    (i32.store8 offset=45 (local.get $input_start) (i32.const 111)) ;; 'o'
    (i32.store8 offset=46 (local.get $input_start) (i32.const 109)) ;; 'm'
    (i32.store8 offset=47 (local.get $input_start) (i32.const 112)) ;; 'p'
    (i32.store8 offset=48 (local.get $input_start) (i32.const 117)) ;; 'u'
    (i32.store8 offset=49 (local.get $input_start) (i32.const 116)) ;; 't'
    (i32.store8 offset=50 (local.get $input_start) (i32.const 101)) ;; 'e'
    (i32.store8 offset=51 (local.get $input_start) (i32.const 32))  ;; ' '
    (i32.store8 offset=52 (local.get $input_start) (i32.const 125)) ;; '}'

    ;; Copy to position 0 for lexer
    (call $store_test_input (local.get $input_start) (local.get $input_len))

    ;; Tokenize input
    (local.set $token_count (call $scan_text (i32.const 0) (local.get $input_len)))

    ;; Parse component declaration
    (call $parse_component_declaration (i32.const 0))
    (local.set $next_pos)  ;; Second return value
    (local.set $ast_node)  ;; First return value

    ;; Check if parsing succeeded
    (if (i32.eqz (local.get $ast_node))
      (then (return (i32.const 0))))

    ;; Verify node type
    (local.set $node_type (call $get_node_type (local.get $ast_node)))
    (if (i32.ne (local.get $node_type) (global.get $DECL_COMPONENT))
      (then (return (i32.const 0))))

    ;; Check that the component has children (imports/exports should be parsed)
    (local.set $child_count (call $get_child_count (local.get $ast_node)))
    (if (i32.eqz (local.get $child_count))
      (then (return (i32.const 0))))

    ;; Test passed - component parsed with children
    (i32.const 1))

  ;; Main test runner
  (func $run_tests (export "run_tests") (result i32)
    ;; Run complex component test
    (call $test_component_with_imports_exports))
)
