;; Lexer test module
;; Interface: lexer_test.wit
(module
    ;; Import memory from memory component
    (import "memory" "memory" (memory 1))

    ;; Import lexer functions
    (import "lexer" "init-lexer" (func $init_lexer (param i32 i32) (result i32)))
    (import "lexer" "next-token" (func $next_token (result i32)))

    ;; Token type constants (matching WIT enum values)
    (global $TOKEN_LPAREN i32 (i32.const 0))   ;; lparen
    (global $TOKEN_RPAREN i32 (i32.const 1))   ;; rparen
    (global $TOKEN_IDENTIFIER i32 (i32.const 2));; identifier
    (global $TOKEN_KEYWORD i32 (i32.const 3))   ;; keyword
    (global $TOKEN_INTEGER i32 (i32.const 4))   ;; integer
    (global $TOKEN_FLOAT i32 (i32.const 5))    ;; float
    (global $TOKEN_STRING i32 (i32.const 6))   ;; string
    (global $TOKEN_EOF i32 (i32.const 7))      ;; eof
    (global $TOKEN_ERROR i32 (i32.const 8))    ;; error
    (global $TOKEN_LBRACE i32 (i32.const 9))   ;; {
    (global $TOKEN_RBRACE i32 (i32.const 10))  ;; }
    (global $TOKEN_COLON i32 (i32.const 11))   ;; :
    (global $TOKEN_DOUBLE_COLON i32 (i32.const 12)) ;; ::
    (global $TOKEN_ASSIGN i32 (i32.const 13))  ;; :=
    (global $TOKEN_ARROW i32 (i32.const 14))   ;; =>
    (global $TOKEN_HYPHEN i32 (i32.const 15))  ;; -

  ;; Test data
  ;; Basic WAT test case
  (data (i32.const 0x0000)
    "(module\n"
    "  (func $add (param $a i32) (param $b i32) (result i32)\n"
    "    (i32.add\n"
    "      (i32.const 42)\n"
    "      (i32.const -123))\n"
    "  )\n"
    "  (export \"add\" (func $add))\n"
    "  (export \"test\\nstring\" (func $add))\n"
    ")\n")

  ;; Novo syntax test case
  (data (i32.const 0x1000)
    "record point {\n"
    "  x-coord: i32,\n"  ;; Tests kebab-case identifier
    "  y-coord: i32\n"
    "}\n"
    "\n"
    "func calculate-distance(p1: point, p2: point) => i32 {\n"  ;; Tests kebab-case func name
    "  distance := p1::x-coord - p2::x-coord\n"  ;; Tests :=, ::, and subtraction
    "  %interface := true\n"  ;; Tests % prefix for reserved word
    "  match distance {\n"    ;; Tests block syntax
    "    x => x * 2,\n"      ;; Tests => syntax
    "    _ => 0\n"
    "  }\n"
    "}\n")

  ;; Test entry point
  (func $test (result i32)
    (local $result i32)
    (local $token_ptr i32)

    ;; Initialize lexer with test data
    (local.set $result
      (call $init_lexer
        (i32.const 0x0000)  ;; source pointer
        (i32.const 146)))   ;; source length

    ;; Verify initialization
    (if (i32.eqz (local.get $result))
      (then
        (call $report_error (i32.const 1))
        (return (i32.const 1))))

    ;; Test token sequence
    (block $test_complete
      (loop $test_tokens
        (local.set $token_ptr (call $next_token))

        ;; Verify token
        (if (i32.eqz (call $verify_token (local.get $token_ptr)))
          (then
            (call $report_error (i32.const 2))
            (return (i32.const 2))))

        ;; Check for EOF
        (if (i32.eq
              (i32.load (local.get $token_ptr))
              (global.get $TOKEN_EOF))
          (then
            (br $test_complete)))

        (br $test_tokens)))

    ;; If we get here, all tests passed
    (i32.const 0)
  )

  ;; Token verification helper
  (func $verify_token
    (param $token_ptr i32)
    (result i32)
    (local $token_type i32)
    (local $token_start i32)
    (local $token_len i32)

    ;; Load token data
    (local.set $token_type (i32.load (local.get $token_ptr)))
    (local.set $token_start
      (i32.load (i32.add (local.get $token_ptr) (i32.const 4))))
    (local.set $token_len
      (i32.load (i32.add (local.get $token_ptr) (i32.const 8))))

    ;; Check for error token
    (if (i32.eq (local.get $token_type) (global.get $TOKEN_ERROR))
      (then
        (return (i32.const 0))))

    ;; Verify token structure
    (if (i32.or
          (i32.lt_s (local.get $token_start) (i32.const 0))
          (i32.lt_s (local.get $token_len) (i32.const 0)))
      (then
        (return (i32.const 0))))

    ;; Token-specific validation
    (block $check_done
      ;; Token type verification branches
      (block ;; String
        (block ;; Number
          (block ;; Identifier/Keyword
            (block ;; Right Paren
              (block ;; Left Paren
                (block ;; Other/Error
                  (br_table 0 1 2 3 4 5
                    (i32.sub (local.get $token_type) (i32.const 1)))
                ) ;; Other/Error
                ;; Left paren check
                (if (i32.ne (local.get $token_len) (i32.const 1))
                  (then (return (i32.const 0))))
                (br $check_done)
              ) ;; Left Paren
              ;; Right paren check
              (if (i32.ne (local.get $token_len) (i32.const 1))
                (then (return (i32.const 0))))
              (br $check_done)
            ) ;; Right Paren
            ;; Identifier/keyword check
            (if (i32.lt_s (local.get $token_len) (i32.const 1))
              (then (return (i32.const 0))))
            (br $check_done)
          ) ;; Identifier/Keyword
          ;; Number check
          (if (i32.lt_s (local.get $token_len) (i32.const 1))
            (then (return (i32.const 0))))
          (br $check_done)
        ) ;; Number
        ;; String check
        (if (i32.lt_s (local.get $token_len) (i32.const 1))
          (then (return (i32.const 0))))

        ;; Verify string content
        (call $verify_string_content
          (local.get $token_start)
          (local.get $token_len))
        (br $check_done)
      ) ;; String
    )

    (i32.const 1)  ;; Token verified successfully
  )

  ;; Error reporting with descriptive messages
  (func $report_error
    (param $error_code i32)
    ;; Error codes:
    ;; 1 - Lexer initialization failed
    ;; 2 - Invalid token found
    ;; Store error code for JavaScript to read
    (i32.store
      (i32.const 0x3000)  ;; Error storage location
      (local.get $error_code))
  )

  ;; Export memory for error handling
  (export "get_error" (func $get_error))
  (func $get_error (result i32)
    (i32.load (i32.const 0x3000))
  )

  ;; String content verification helper
  (func $verify_string_content
    (param $start i32)     ;; Start position of string content
    (param $len i32)       ;; Length of string content
    (result i32)          ;; Returns 1 if valid, 0 if invalid
    (local $pos i32)      ;; Current position
    (local $char i32)     ;; Current character
    (local $end i32)      ;; End position

    (local.set $pos (local.get $start))
    (local.set $end
      (i32.add
        (local.get $start)
        (local.get $len)))

    (block $done
      (loop $check_chars
        ;; Check if we've reached the end
        (if (i32.ge_u (local.get $pos) (local.get $end))
          (then (br $done)))

        ;; Load current character
        (local.set $char (i32.load8_u (local.get $pos)))

        ;; Check for escaped sequence
        (if (i32.eq (local.get $char) (i32.const 0x5C))  ;; '\'
          (then
            ;; Skip escape char and validate next char
            (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
            (if (i32.ge_u (local.get $pos) (local.get $end))
              (then (return (i32.const 0))))  ;; Invalid escape at end
            (local.set $char (i32.load8_u (local.get $pos)))
            ;; Validate escape sequence
            (if (i32.eqz (call $is_valid_escape (local.get $char)))
              (then (return (i32.const 0))))))

        ;; Check for raw control characters (should be escaped)
        (if (i32.lt_u (local.get $char) (i32.const 0x20))
          (then (return (i32.const 0))))

        ;; Move to next character
        (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
        (br $check_chars)))

    (i32.const 1)  ;; String content is valid
  )

  ;; Helper to validate escape sequences
  (func $is_valid_escape
    (param $char i32)
    (result i32)
    (if (i32.eq (local.get $char) (i32.const 0x6E))  ;; 'n'
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $char) (i32.const 0x72))  ;; 'r'
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $char) (i32.const 0x74))  ;; 't'
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $char) (i32.const 0x22))  ;; '"'
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $char) (i32.const 0x5C))  ;; '\'
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $char) (i32.const 0x66))  ;; 'f'
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $char) (i32.const 0x62))  ;; 'b'
      (then (return (i32.const 1))))
    (i32.const 0)  ;; Invalid escape sequence
  )

  ;; Test Novo identifier parsing
  (func $test_novo_identifiers
    (param $token_ptr i32)
    (result i32)
    (local $token_type i32)
    (local $token_start i32)
    (local $token_len i32)

    ;; Initialize lexer with Novo test data
    (call $init_lexer
      (i32.const 0x1000)  ;; source pointer
      (i32.const 250))    ;; approximate source length

    ;; Test kebab-case identifier
    (local.set $token_ptr (call $next_token))
    (local.set $token_type (i32.load (local.get $token_ptr)))
    (if (i32.ne (local.get $token_type) (global.get $TOKEN_IDENTIFIER))
      (then (return (i32.const 0))))

    ;; Test identifier with % prefix
    (loop $find_interface
      (local.set $token_ptr (call $next_token))
      (local.set $token_type (i32.load (local.get $token_ptr)))
      (local.set $token_start (i32.load offset=4 (local.get $token_ptr)))
      (if (i32.eq (i32.load8_u (local.get $token_start)) (i32.const 0x25))  ;; %
        (then (br $find_interface))))

    (if (i32.ne (local.get $token_type) (global.get $TOKEN_IDENTIFIER))
      (then (return (i32.const 0))))

    (i32.const 1)  ;; Success
  )

  ;; Test Novo operator parsing
  (func $test_novo_operators
    (param $token_ptr i32)
    (result i32)
    (local $token_type i32)
    (local $found_assign i32)
    (local $found_arrow i32)
    (local $found_double_colon i32)

    ;; Initialize lexer with Novo test data
    (call $init_lexer
      (i32.const 0x1000)
      (i32.const 250))

    ;; Find and verify all operators
    (loop $find_operators
      (local.set $token_ptr (call $next_token))
      (local.set $token_type (i32.load (local.get $token_ptr)))

      ;; Check for EOF
      (if (i32.eq (local.get $token_type) (global.get $TOKEN_EOF))
        (then (br $find_operators)))

      ;; Track which operators we've found
      (if (i32.eq (local.get $token_type) (global.get $TOKEN_ASSIGN))
        (then (local.set $found_assign (i32.const 1))))
      (if (i32.eq (local.get $token_type) (global.get $TOKEN_ARROW))
        (then (local.set $found_arrow (i32.const 1))))
      (if (i32.eq (local.get $token_type) (global.get $TOKEN_DOUBLE_COLON))
        (then (local.set $found_double_colon (i32.const 1))))

      (br $find_operators)
    )

    ;; Verify we found all operators
    (if (i32.eqz (i32.and
          (i32.and
            (local.get $found_assign)
            (local.get $found_arrow))
          (local.get $found_double_colon)))
      (then (return (i32.const 0))))

    (i32.const 1)  ;; Success
  )

  ;; Test block delimiter parsing
  (func $test_novo_blocks
    (param $token_ptr i32)
    (result i32)
    (local $token_type i32)
    (local $found_lbrace i32)
    (local $found_rbrace i32)

    ;; Initialize lexer with Novo test data
    (call $init_lexer
      (i32.const 0x1000)
      (i32.const 250))

    ;; Find and verify block delimiters
    (loop $find_delimiters
      (local.set $token_ptr (call $next_token))
      (local.set $token_type (i32.load (local.get $token_ptr)))

      ;; Check for EOF
      (if (i32.eq (local.get $token_type) (global.get $TOKEN_EOF))
        (then (br $find_delimiters)))

      ;; Track which delimiters we've found
      (if (i32.eq (local.get $token_type) (global.get $TOKEN_LBRACE))
        (then (local.set $found_lbrace (i32.const 1))))
      (if (i32.eq (local.get $token_type) (global.get $TOKEN_RBRACE))
        (then (local.set $found_rbrace (i32.const 1))))

      (br $find_delimiters)
    )

    ;; Verify we found both delimiters
    (if (i32.eqz (i32.and
          (local.get $found_lbrace)
          (local.get $found_rbrace)))
      (then (return (i32.const 0))))

    (i32.const 1)  ;; Success
  )

  ;; Main test function
  (func $test (export "test") (result i32)
    (local $result i32)
    (local $token_ptr i32)

    ;; Test WAT lexing first (existing test)
    (local.set $result
      (call $init_lexer
        (i32.const 0x0000)  ;; source pointer
        (i32.const 146)))   ;; source length

    ;; Verify initialization
    (if (i32.eqz (local.get $result))
      (then
        (call $report_error (i32.const 1))
        (return (i32.const 1))))

    ;; Test token sequence
    (block $test_complete
      (loop $test_tokens
        (local.set $token_ptr (call $next_token))

        ;; Verify token
        (if (i32.eqz (call $verify_token (local.get $token_ptr)))
          (then
            (call $report_error (i32.const 2))
            (return (i32.const 2))))

        ;; Check for EOF
        (if (i32.eq
              (i32.load (local.get $token_ptr))
              (global.get $TOKEN_EOF))
          (then
            (br $test_complete)))

        (br $test_tokens)))

    ;; If we get here, all tests passed
    (i32.const 0)

    ;; Test Novo syntax
    (if (i32.eqz (call $test_novo_identifiers (local.get $token_ptr)))
      (then
        (call $report_error (i32.const 3))  ;; Identifier test failed
        (return (i32.const 3))))

    (if (i32.eqz (call $test_novo_operators (local.get $token_ptr)))
      (then
        (call $report_error (i32.const 4))  ;; Operator test failed
        (return (i32.const 4))))

    (if (i32.eqz (call $test_novo_blocks (local.get $token_ptr)))
      (then
        (call $report_error (i32.const 5))  ;; Block delimiter test failed
        (return (i32.const 5))))

    (i32.const 0)  ;; All tests passed
  )
