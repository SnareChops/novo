;; WebAssembly Text Format Lexer Module
;; Interface: lexer.wit
(module
    ;; Import memory and keyword checker
    (import "memory" "memory" (memory 1))
    (import "memory" "get-memory-layout" (func $get_memory_layout (result i32 i32 i32 i32 i32)))
    (import "keywords" "is-keyword" (func $kw_is_keyword (param i32 i32) (result i32)))
    ;; Import memory and keyword checker
    (import "memory" "memory" (memory 1))
    (import "keywords" "is-keyword" (func $is_keyword (param i32 i32) (result i32)))

    ;; Token type constants (matching WIT enum values)
    (global $TOKEN_LPAREN (mut i32) (i32.const 0))
    (global $TOKEN_RPAREN (mut i32) (i32.const 1))
    (global $TOKEN_IDENTIFIER (mut i32) (i32.const 2))
    (global $TOKEN_KEYWORD (mut i32) (i32.const 3))
    (global $TOKEN_INTEGER (mut i32) (i32.const 4))
    (global $TOKEN_FLOAT (mut i32) (i32.const 5))
    (global $TOKEN_STRING (mut i32) (i32.const 6))
    (global $TOKEN_EOF (mut i32) (i32.const 7))
    (global $TOKEN_ERROR (mut i32) (i32.const 8))
    (global $TOKEN_LBRACE (mut i32) (i32.const 9))
    (global $TOKEN_RBRACE (mut i32) (i32.const 10))
    (global $TOKEN_COLON (mut i32) (i32.const 11))
    (global $TOKEN_DOUBLE_COLON (mut i32) (i32.const 12))
    (global $TOKEN_ASSIGN (mut i32) (i32.const 13))
    (global $TOKEN_ARROW (mut i32) (i32.const 14))
    (global $TOKEN_HYPHEN (mut i32) (i32.const 15))  ;; For kebab-case

  ;; Lexer state constants
  (global $STATE_INITIAL (mut i32) (i32.const 0))
  (global $STATE_IDENTIFIER (mut i32) (i32.const 1))
  (global $STATE_NUMBER (mut i32) (i32.const 2))
  (global $STATE_STRING (mut i32) (i32.const 3))
  (global $STATE_COMMENT (mut i32) (i32.const 4))
  (global $STATE_BLOCK_COMMENT (mut i32) (i32.const 5))

  ;; Export token constants
  (export "TOKEN_LPAREN" (global $TOKEN_LPAREN))
  (export "TOKEN_RPAREN" (global $TOKEN_RPAREN))
  (export "TOKEN_IDENTIFIER" (global $TOKEN_IDENTIFIER))
  (export "TOKEN_KEYWORD" (global $TOKEN_KEYWORD))
  (export "TOKEN_INTEGER" (global $TOKEN_INTEGER))
  (export "TOKEN_FLOAT" (global $TOKEN_FLOAT))
  (export "TOKEN_STRING" (global $TOKEN_STRING))
  (export "TOKEN_EOF" (global $TOKEN_EOF))
  (export "TOKEN_ERROR" (global $TOKEN_ERROR))

  ;; Character classification functions
  (func $is_whitespace (param $char i32) (result i32)
    (local $result i32)
    (if (i32.eq (local.get $char) (i32.const 0x20))  ;; space
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $char) (i32.const 0x09))  ;; tab
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $char) (i32.const 0x0A))  ;; newline
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $char) (i32.const 0x0D))  ;; carriage return
      (then (return (i32.const 1))))
    (i32.const 0)
  )
  (export "is_whitespace" (func $is_whitespace))

  (func $is_alpha (param $char i32) (result i32)
    ;; Check for A-Z
    (if (i32.and
          (i32.ge_u (local.get $char) (i32.const 0x41))
          (i32.le_u (local.get $char) (i32.const 0x5A)))
      (then (return (i32.const 1))))

    ;; Check for a-z
    (if (i32.and
          (i32.ge_u (local.get $char) (i32.const 0x61))
          (i32.le_u (local.get $char) (i32.const 0x7A)))
      (then (return (i32.const 1))))

    (i32.const 0)
  )
  (export "is_alpha" (func $is_alpha))

  (func $is_digit (export "is_digit") (param $char i32) (result i32)
    (i32.and
      (i32.ge_u (local.get $char) (i32.const 0x30)) ;; '0'
      (i32.le_u (local.get $char) (i32.const 0x39)) ;; '9'
    )
  )

  (func $is_identifier_char (param $char i32) (result i32)
    ;; Check if character is alphanumeric
    (if (call $is_alpha (local.get $char))
      (then (return (i32.const 1))))
    (if (call $is_digit (local.get $char))
      (then (return (i32.const 1))))

    ;; Check for kebab-case hyphen
    (if (i32.eq (local.get $char) (i32.const 0x2D))  ;; '-'
      (then (return (i32.const 1))))

    ;; % prefix for reserved words
    (if (i32.eq (local.get $char) (i32.const 0x25))  ;; '%'
      (then (return (i32.const 1))))

    (i32.const 0)
  )
  (export "is_identifier_char" (func $is_identifier_char))

  ;; Check if current identifier character is valid in its position
  (func $is_valid_identifier_position
    (param $char i32)
    (param $is_first i32)      ;; 1 if first character of word, 0 otherwise
    (param $prev_char i32)     ;; Previous character or 0
    (result i32)

    ;; First character must be % or letter
    (if (local.get $is_first)
      (then
        (if (i32.eq (local.get $char) (i32.const 0x25)) ;; %
          (then (return (i32.const 1))))
        (return (call $is_alpha (local.get $char)))))

    ;; After hyphen, must be a letter
    (if (i32.eq (local.get $prev_char) (i32.const 0x2D))
      (then (return (call $is_alpha (local.get $char)))))

    ;; Otherwise, can be letter, number or hyphen
    (call $is_identifier_char (local.get $char))
  )
  (export "is_valid_identifier_position" (func $is_valid_identifier_position))

  (func $is_number_start (param $char i32) (result i32)
    (local $is_digit i32)
    (local $is_sign i32)
    (local $is_dot i32)

    (local.set $is_digit (call $is_digit (local.get $char)))
    (local.set $is_sign
      (i32.or
        (i32.eq (local.get $char) (i32.const 0x2B))  ;; '+'
        (i32.eq (local.get $char) (i32.const 0x2D))));; '-'
    (local.set $is_dot
      (i32.eq (local.get $char) (i32.const 0x2E)))   ;; '.'

    (i32.or
      (i32.or
        (local.get $is_digit)
        (local.get $is_sign))
      (local.get $is_dot))
  )

  ;; Memory layout for tokens:
  ;; 0x2000-0x2FFF: Token buffer
  ;; Token structure (16 bytes):
  ;; - 0x00: type (i32)
  ;; - 0x04: start position (i32)
  ;; - 0x08: length (i32)
  ;; - 0x0C: value (i32) - for numeric tokens

  ;; Initialize lexer with source text
  (func $init_lexer (export "init_lexer")
    (param $source_ptr i32)    ;; Pointer to source text
    (param $source_len i32)    ;; Length of source text
    (result i32)               ;; Returns 1 on success, 0 on failure

    ;; Initialize lexer state
    (i32.store
      (i32.const 0x1000)      ;; Current state
      (global.get $STATE_INITIAL))

    (i32.store
      (i32.const 0x1004)      ;; Source pointer
      (local.get $source_ptr))

    (i32.store
      (i32.const 0x1008)      ;; Source length
      (local.get $source_len))

    ;; Initialize token buffer pointer
    (i32.store
      (i32.const 0x100C)      ;; Current token buffer position
      (i32.const 0x2000))     ;; Start of token buffer

    (i32.const 1)             ;; Return success
  )

  ;; Get next token from input
  (func $next_token (export "next_token")
    (result i32)              ;; Returns pointer to token structure
    (local $char i32)         ;; Current character
    (local $pos i32)          ;; Current position in source
    (local $state i32)        ;; Current lexer state
    (local $token_ptr i32)    ;; Pointer to current token
    (local $start_pos i32)    ;; Start position of current token
    (local $value i32)        ;; For numeric values
    (local $is_escaped i32)   ;; For string escape sequence tracking

    ;; Get current state and position
    (local.set $state
      (i32.load (i32.const 0x1000)))
    (local.set $pos
      (i32.load (i32.const 0x1004)))
    (local.set $token_ptr
      (i32.load (i32.const 0x100C)))
    (local.set $is_escaped (i32.const 0))

    ;; Check for EOF
    (if (i32.ge_u
          (local.get $pos)
          (i32.add
            (i32.load (i32.const 0x1004))    ;; Source start
            (i32.load (i32.const 0x1008))))   ;; Source length
      (then
        ;; Create EOF token
        (call $create_token
          (local.get $token_ptr)
          (global.get $TOKEN_EOF)
          (local.get $pos)
          (i32.const 0)
          (i32.const 0))
        (return (local.get $token_ptr))))

    ;; Get current character
    (local.set $char
      (i32.load8_u (local.get $pos)))

    ;; Main lexer state machine
    (block $done
      (loop $process_char
        (block $next_char
          (block $state_machine
            (block ;; Initial state
              (block ;; Identifier state
                (block ;; Number state
                  (block ;; String state
                    (br_table 0 1 2 3
                      (local.get $state))
                  ) ;; String state

                  ;; String state handling
                  (block $handle_string
                    ;; Check for end of input (unclosed string)
                    (if (i32.ge_u
                          (local.get $pos)
                          (i32.add
                            (i32.load (i32.const 0x1004))
                            (i32.load (i32.const 0x1008))))
                      (then
                        ;; Create error token for unclosed string
                        (call $create_token
                          (local.get $token_ptr)
                          (global.get $TOKEN_ERROR)
                          (local.get $start_pos)
                          (i32.sub (local.get $pos) (local.get $start_pos))
                          (i32.const 0))
                        (br $done)))

                    ;; Handle escape sequences
                    (if (local.get $is_escaped)
                      (then
                        (local.set $char (call $get_escape_char (local.get $char)))
                        (local.set $is_escaped (i32.const 0))
                        (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
                        (br $next_char)))

                    (if (call $is_string_escape (local.get $char))
                      (then
                        (local.set $is_escaped (i32.const 1))
                        (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
                        (br $next_char)))

                    ;; Check for end of string
                    (if (call $is_string_quote (local.get $char))
                      (then
                        ;; Create string token excluding quotes
                        (call $create_token
                          (local.get $token_ptr)
                          (global.get $TOKEN_STRING)
                          (i32.add (local.get $start_pos) (i32.const 1))  ;; Skip opening quote
                          (i32.sub
                            (i32.sub (local.get $pos) (local.get $start_pos))
                            (i32.const 1))  ;; Exclude quotes from length
                          (i32.const 0))
                        (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
                        (br $done)))

                    ;; Validate string character
                    (if (i32.eqz (call $is_valid_string_char (local.get $char)))
                      (then
                        ;; Create error token for invalid character
                        (call $create_token
                          (local.get $token_ptr)
                          (global.get $TOKEN_ERROR)
                          (local.get $start_pos)
                          (i32.sub (local.get $pos) (local.get $start_pos))
                          (i32.const 0))
                        (br $done)))

                    ;; Continue string
                    (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
                    (br $next_char)
                  )
                ) ;; Number state

                ;; Identifier state
                ;; Continue identifier
                (if (call $is_identifier_char (local.get $char))
                  (then
                    (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
                    (br $next_char)))

                ;; End of identifier
                (call $create_identifier_token
                  (local.get $token_ptr)
                  (local.get $start_pos)
                  (i32.sub (local.get $pos) (local.get $start_pos)))
                (br $done)
              ) ;; Identifier state

              ;; Initial state
              ;; Skip whitespace
              (if (call $is_whitespace (local.get $char))
                (then
                  (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
                  (br $next_char)))

              ;; Handle special characters
              (if (i32.eq (local.get $char) (i32.const 0x28))  ;; '('
                (then
                  (call $create_token
                    (local.get $token_ptr)
                    (global.get $TOKEN_LPAREN)
                    (local.get $pos)
                    (i32.const 1)
                    (i32.const 0))
                  (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
                  (br $done)))

              (if (i32.eq (local.get $char) (i32.const 0x29))  ;; ')'
                (then
                  (call $create_token
                    (local.get $token_ptr)
                    (global.get $TOKEN_RPAREN)
                    (local.get $pos)
                    (i32.const 1)
                    (i32.const 0))
                  (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
                  (br $done)))

              (if (i32.eq (local.get $char) (i32.const 0x7B))  ;; '{'
                (then
                  (call $create_token
                    (local.get $token_ptr)
                    (global.get $TOKEN_LBRACE)
                    (local.get $pos)
                    (i32.const 1)
                    (i32.const 0))
                  (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
                  (br $done)))

              (if (i32.eq (local.get $char) (i32.const 0x7D))  ;; '}'
                (then
                  (call $create_token
                    (local.get $token_ptr)
                    (global.get $TOKEN_RBRACE)
                    (local.get $pos)
                    (i32.const 1)
                    (i32.const 0))
                  (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
                  (br $done)))

              ;; Handle operators that can be part of compounds
              (block $operator_done
                ;; Check for colon
                (if (i32.eq (local.get $char) (i32.const 0x3A))  ;; ':'
                  (then
                    ;; Look ahead for second character
                    (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
                    (local.set $next_char (i32.load8_u (local.get $pos)))

                    ;; Handle :=
                    (if (i32.eq (local.get $next_char) (i32.const 0x3D))  ;; '='
                      (then
                        (call $create_token
                          (local.get $token_ptr)
                          (global.get $TOKEN_ASSIGN)
                          (i32.sub (local.get $pos) (i32.const 1))
                          (i32.const 2)
                          (i32.const 0))
                        (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
                        (br $operator_done)))

                    ;; Handle ::
                    (if (i32.eq (local.get $next_char) (i32.const 0x3A))  ;; ':'
                      (then
                        (call $create_token
                          (local.get $token_ptr)
                          (global.get $TOKEN_DOUBLE_COLON)
                          (i32.sub (local.get $pos) (i32.const 1))
                          (i32.const 2)
                          (i32.const 0))
                        (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
                        (br $operator_done)))

                    ;; Single colon
                    (call $create_token
                      (local.get $token_ptr)
                      (global.get $TOKEN_COLON)
                      (i32.sub (local.get $pos) (i32.const 1))
                      (i32.const 1)
                      (i32.const 0))
                    (br $operator_done)))

                ;; Check for =>
                (if (i32.eq (local.get $char) (i32.const 0x3D))  ;; '='
                  (then
                    (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
                    (if (i32.eq (i32.load8_u (local.get $pos)) (i32.const 0x3E))  ;; '>'
                      (then
                        (call $create_token
                          (local.get $token_ptr)
                          (global.get $TOKEN_ARROW)
                          (i32.sub (local.get $pos) (i32.const 1))
                          (i32.const 2)
                          (i32.const 0))
                        (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
                        (br $operator_done)))))

                ;; Check for - (only tokenize as operator if not part of identifier)
                (if (i32.eq (local.get $char) (i32.const 0x2D))  ;; '-'
                  (then
                    ;; Only create hyphen token if not in identifier context
                    (if (i32.eqz (call $is_identifier_char (i32.load8_u (i32.add (local.get $pos) (i32.const 1)))))
                      (then
                        (call $create_token
                          (local.get $token_ptr)
                          (global.get $TOKEN_HYPHEN)
                          (local.get $pos)
                          (i32.const 1)
                          (i32.const 0))
                        (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
                        (br $operator_done)))))

                (br $done))  ;; Exit operator handling

              ;; Start of identifier
              (if (call $is_identifier_char (local.get $char))
                (then
                  (local.set $start_pos (local.get $pos))
                  (local.set $state (global.get $STATE_IDENTIFIER))
                  (br $next_char)))

              ;; Start of string
              (if (call $is_string_quote (local.get $char))
                (then
                  (local.set $start_pos (local.get $pos))
                  (local.set $state (global.get $STATE_STRING))
                  (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
                  (br $next_char)))

              ;; Start of number
              (if (call $is_number_start (local.get $char))
                (then
                  (local.set $start_pos (local.get $pos))
                  (local.set $state (global.get $STATE_NUMBER))
                  (br $next_char)))
