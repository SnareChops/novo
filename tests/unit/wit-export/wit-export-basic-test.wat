;; WIT Export Basic Test
;; Tests basic WIT generation from Novo component AST

(module
  ;; Import shared memory
  (import "memory" "memory" (memory 1))

  ;; Import test framework
  (import "wasi_snapshot_preview1" "proc_exit" (func $proc_exit (param i32)))

  ;; Import AST modules for creating test nodes
  (import "ast_declaration_creators" "create_decl_component"
    (func $create_decl_component (param i32 i32) (result i32)))
  (import "ast_declaration_creators" "create_decl_interface"
    (func $create_decl_interface (param i32 i32) (result i32)))
  (import "ast_declaration_creators" "create_decl_import"
    (func $create_decl_import (param i32 i32 i32 i32) (result i32)))
  (import "ast_declaration_creators" "create_decl_export"
    (func $create_decl_export (param i32 i32 i32 i32) (result i32)))

  ;; Import AST node manipulation
  (import "ast_node_core" "add_child" (func $add_child (param i32 i32) (result i32)))

  ;; Import WIT export functions
  (import "wit_export_main" "init" (func $init_wit_export))
  (import "wit_export_main" "export_component_wit" (func $export_component_wit (param i32) (result i32)))
  (import "wit_export_main" "export_interface_wit" (func $export_interface_wit (param i32) (result i32)))
  (import "wit_export_main" "get_wit_output" (func $get_wit_output (result i32)))
  (import "wit_export_main" "get_wit_length" (func $get_wit_length (result i32)))
  (import "wit_export_main" "reset_wit_output" (func $reset_wit_output))

  ;; Test: Generate WIT for a simple component
  (func $test_simple_component_wit (export "_start")
    (local $component_node i32)
    (local $result i32)
    (local $output_ptr i32)
    (local $output_len i32)

    ;; Initialize WIT export system
    (call $init_wit_export)

    ;; Create a simple component node
    ;; Component name: "test-component"
    (local.set $component_node
      (call $create_decl_component
        (i32.const 1000)    ;; name pointer
        (i32.const 14)))    ;; name length

    ;; Test that we got a valid node
    (if (i32.eqz (local.get $component_node))
      (then (call $proc_exit (i32.const 1))))  ;; Fail if node creation failed

    ;; Generate WIT for the component
    (local.set $result
      (call $export_component_wit (local.get $component_node)))

    ;; Test that WIT generation succeeded
    (if (i32.eqz (local.get $result))
      (then (call $proc_exit (i32.const 2))))  ;; Fail if WIT generation failed

    ;; Get the generated output
    (local.set $output_ptr (call $get_wit_output))
    (local.set $output_len (call $get_wit_length))

    ;; Test that we got some output
    (if (i32.eqz (local.get $output_len))
      (then (call $proc_exit (i32.const 3))))  ;; Fail if no output

    ;; Test that output contains expected strings
    ;; Should contain "component test-component {"
    (if (i32.eqz (call $contains_string
                    (local.get $output_ptr)
                    (local.get $output_len)
                    (i32.const 2000)    ;; "component "
                    (i32.const 10)))
      (then (call $proc_exit (i32.const 4))))  ;; Fail if doesn't contain "component "

    ;; Should contain the component name
    (if (i32.eqz (call $contains_string
                    (local.get $output_ptr)
                    (local.get $output_len)
                    (i32.const 1000)    ;; "test-component"
                    (i32.const 14)))
      (then (call $proc_exit (i32.const 5))))  ;; Fail if doesn't contain component name

    ;; Success
    (call $proc_exit (i32.const 0)))

  ;; Helper function to check if a string contains a substring
  ;; @param $haystack_ptr i32 - Pointer to the string to search in
  ;; @param $haystack_len i32 - Length of the string to search in
  ;; @param $needle_ptr i32 - Pointer to the substring to find
  ;; @param $needle_len i32 - Length of the substring to find
  ;; @returns i32 - 1 if found, 0 if not found
  (func $contains_string (param $haystack_ptr i32) (param $haystack_len i32)
                         (param $needle_ptr i32) (param $needle_len i32) (result i32)
    (local $i i32)
    (local $j i32)
    (local $match i32)

    ;; If needle is longer than haystack, it can't be contained
    (if (i32.gt_u (local.get $needle_len) (local.get $haystack_len))
      (then (return (i32.const 0))))

    ;; Search for the needle in the haystack
    (local.set $i (i32.const 0))
    (loop $search_loop
      ;; Check if we've reached the end
      (if (i32.gt_u
            (i32.add (local.get $i) (local.get $needle_len))
            (local.get $haystack_len))
        (then (return (i32.const 0))))  ;; Not found

      ;; Check if needle matches at current position
      (local.set $match (i32.const 1))
      (local.set $j (i32.const 0))
      (loop $compare_loop
        (if (i32.lt_u (local.get $j) (local.get $needle_len))
          (then
            ;; Compare characters
            (if (i32.ne
                  (i32.load8_u
                    (i32.add (local.get $haystack_ptr)
                             (i32.add (local.get $i) (local.get $j))))
                  (i32.load8_u
                    (i32.add (local.get $needle_ptr) (local.get $j))))
              (then
                (local.set $match (i32.const 0))
                (br $compare_loop)))  ;; Break out of compare loop

            (local.set $j (i32.add (local.get $j) (i32.const 1)))
            (br $compare_loop))))

      ;; If we found a match, return success
      (if (local.get $match)
        (then (return (i32.const 1))))

      ;; Move to next position
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $search_loop))

    ;; Not found
    (i32.const 0))

  ;; Test data stored in memory
  (data (i32.const 1000) "test-component")  ;; Component name
  (data (i32.const 2000) "component ")      ;; Expected WIT keyword
)
