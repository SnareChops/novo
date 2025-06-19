;; Novo Parser Expression Utilities
;; Helper functions and utilities for expression parsing

(module $novo_parser_expression_utilities
  ;; Import memory from lexer
  (import "lexer_memory" "memory" (memory 1))

  ;; Import token constants
  (import "lexer_tokens" "TOKEN_IDENTIFIER" (global $TOKEN_IDENTIFIER i32))

  ;; Import helper functions
  (import "parser_utils" "get_token_type" (func $get_token_type (param i32) (result i32)))
  (import "parser_utils" "get_token_start" (func $get_token_start (param i32) (result i32)))
  (import "parser_utils" "get_token_length" (func $get_token_length (param i32) (result i32)))

  ;; Memory layout constants
  (global $TOKEN_ARRAY_START (export "TOKEN_ARRAY_START") i32 (i32.const 2048))
  (global $TOKEN_RECORD_SIZE (export "TOKEN_RECORD_SIZE") i32 (i32.const 16))

  ;; Helper function for string comparison
  ;; @param $str1_start i32 - Start of first string
  ;; @param $str1_len i32 - Length of first string
  ;; @param $str2_start i32 - Start of second string
  ;; @param $str2_len i32 - Length of second string
  ;; @returns i32 - 1 if strings are equal, 0 otherwise
  (func $string_equals (export "string_equals") (param $str1_start i32) (param $str1_len i32) (param $str2_start i32) (param $str2_len i32) (result i32)
    (local $i i32)

    ;; Different lengths means not equal
    (if (i32.ne (local.get $str1_len) (local.get $str2_len))
      (then (return (i32.const 0)))
    )

    ;; Compare character by character
    (local.set $i (i32.const 0))
    (loop $compare_loop
      (if (i32.ge_u (local.get $i) (local.get $str1_len))
        (then (return (i32.const 1))) ;; All characters matched
      )

      (if (i32.ne
            (i32.load8_u (i32.add (local.get $str1_start) (local.get $i)))
            (i32.load8_u (i32.add (local.get $str2_start) (local.get $i)))
          )
        (then (return (i32.const 0))) ;; Characters don't match
      )

      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $compare_loop)
    )

    (i32.const 1) ;; Should not reach here
  )

  ;; Check if identifier is a supported meta-function
  ;; @param $name_start i32 - Start of function name string
  ;; @param $name_len i32 - Length of function name string
  ;; @returns i32 - 1 if supported, 0 otherwise
  (func $is_supported_meta_function (export "is_supported_meta_function") (param $name_start i32) (param $name_len i32) (result i32)
    ;; For now, support "size" and "type"
    ;; TODO: Add string literals for comparison

    ;; Simplified check - just return true for now
    ;; In a real implementation, we'd compare against known meta-function names
    (i32.const 1)
  )

  ;; Validate if a token is a valid function name
  ;; @param $token_idx i32 - Token index to validate
  ;; @returns i32 - 1 if valid function name, 0 otherwise
  (func $is_valid_function_name (export "is_valid_function_name") (param $token_idx i32) (result i32)
    (local $token_type i32)

    (local.set $token_type (call $get_token_type (local.get $token_idx)))
    (i32.eq (local.get $token_type) (global.get $TOKEN_IDENTIFIER))
  )

  ;; Get the length of a token's text content
  ;; @param $token_idx i32 - Token index
  ;; @returns i32 - Length of token text
  (func $get_token_text_length (export "get_token_text_length") (param $token_idx i32) (result i32)
    (call $get_token_length (local.get $token_idx))
  )

  ;; Get the start position of a token's text content
  ;; @param $token_idx i32 - Token index
  ;; @returns i32 - Start position of token text
  (func $get_token_text_start (export "get_token_text_start") (param $token_idx i32) (result i32)
    (call $get_token_start (local.get $token_idx))
  )
)
