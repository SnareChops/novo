;; Novo Main Lexer
;; Orchestrates all lexer components to provide tokenization

(module $novo_lexer
  ;; Import all required modules and their functions
  (import "memory" "memory" (memory 1))
  (import "memory" "update_position" (func $update_position (param i32)))
  (import "memory" "token_count" (global $token_count (mut i32)))

  (import "tokens" "TOKEN_ERROR" (global $TOKEN_ERROR i32))
  (import "tokens" "TOKEN_IDENTIFIER" (global $TOKEN_IDENTIFIER i32))
  (import "tokens" "TOKEN_NUMBER_LITERAL" (global $TOKEN_NUMBER_LITERAL i32))
  (import "tokens" "TOKEN_WHITESPACE" (global $TOKEN_WHITESPACE i32))
  (import "tokens" "TOKEN_EOF" (global $TOKEN_EOF i32))
  (import "tokens" "TOKEN_ARROW" (global $TOKEN_ARROW i32))
  (import "tokens" "TOKEN_LBRACE" (global $TOKEN_LBRACE i32))
  (import "tokens" "TOKEN_RBRACE" (global $TOKEN_RBRACE i32))

  (import "char_utils" "is_whitespace" (func $is_whitespace (param i32) (result i32)))
  (import "char_utils" "is_letter" (func $is_letter (param i32) (result i32)))
  (import "char_utils" "is_digit" (func $is_digit (param i32) (result i32)))
  (import "char_utils" "is_operator_char" (func $is_operator_char (param i32) (result i32)))
  (import "char_utils" "skip_whitespace" (func $skip_whitespace (param i32) (result i32)))

  (import "lexer_operators" "update_space_tracking" (func $update_space_tracking (param i32)))
  (import "lexer_operators" "scan_colon_op" (func $scan_colon_op (param i32) (result i32 i32)))
  (import "lexer_operators" "scan_operator" (func $scan_operator (param i32) (result i32 i32)))
  (import "lexer_operators" "space_required" (global $space_required (mut i32)))
  (import "lexer_operators" "last_char_was_space" (global $last_char_was_space (mut i32)))

  (import "lexer_identifiers" "scan_identifier" (func $scan_identifier (param i32) (result i32 i32)))
  (import "lexer_token_storage" "store_token" (func $store_token (param i32 i32) (result i32)))
  (import "memory" "store_identifier" (func $store_identifier (param i32 i32) (result i32)))

  ;; Scan a number literal (integer for now)
  ;; @param pos i32 - Starting position
  ;; @returns i32 - Next position after the number
  (func $scan_number (param $pos i32) (result i32)
    (local $current_pos i32)
    (local $char i32)

    (local.set $current_pos (local.get $pos))

    ;; Skip digits
    (loop $scan_digits
      (local.set $char (i32.load8_u (local.get $current_pos)))

      (if (call $is_digit (local.get $char))
        (then
          (local.set $current_pos (i32.add (local.get $current_pos) (i32.const 1)))
          (br $scan_digits)
        )
      )
    )

    (local.get $current_pos)
  )

  ;; Main lexer function - returns token index and next position
  (func $next_token (param $pos i32) (result i32 i32)
    (local $char i32)
    (local $start_pos i32)
    (local $token_idx i32)
    (local $next_pos i32)
    (local $token_type i32)

    ;; Store starting position
    (local.set $start_pos (local.get $pos))

    ;; Read current character
    (local.set $char (i32.load8_u (local.get $pos)))

    ;; Handle EOF
    (if (i32.eqz (local.get $char))
      (then
        (local.set $token_idx
          (call $store_token
            (global.get $TOKEN_EOF)
            (local.get $pos)
          )
        )
        ;; For EOF, advance position to indicate end of input
        (return (local.get $token_idx) (i32.add (local.get $pos) (i32.const 1)))
      )
    )

    ;; Update position tracking for this character
    (call $update_position (local.get $char))
    (call $update_space_tracking (local.get $char))

    (block $token_handled
      ;; Handle whitespace
      (if (call $is_whitespace (local.get $char))
        (then
          (local.set $next_pos (call $skip_whitespace (local.get $pos)))
          (local.set $token_idx
            (call $store_token
              (global.get $TOKEN_WHITESPACE)
              (local.get $pos)
            )
          )
          (br $token_handled)
        )
      )

      ;; Handle mathematical operators
      (if (call $is_operator_char (local.get $char))
        (then
          ;; Get operator token type and next position
          (call $scan_operator (local.get $pos))
          (local.set $next_pos)
          (local.set $token_type)

          ;; Check for space requirements
          (if (global.get $space_required)
            (then
              (if (i32.eqz (global.get $last_char_was_space))
                (then
                  (local.set $token_idx
                    (call $store_token
                      (global.get $TOKEN_ERROR)
                      (local.get $pos)
                    )
                  )
                  (br $token_handled)
                )
              )
            )
          )

          (local.set $token_idx
            (call $store_token
              (local.get $token_type)
              (local.get $pos)
            )
          )
          (br $token_handled)
        )
      )

      ;; Handle identifiers (kebab-case)
      (if (call $is_letter (local.get $char))
        (then
          ;; scan_identifier returns (token_type, next_pos)
          (call $scan_identifier (local.get $pos))
          (local.set $next_pos)
          (local.set $token_type)

          ;; Store identifier token using the token type from scan_identifier
          (local.set $token_idx
            (call $store_token
              (local.get $token_type)
              (local.get $pos)
            )
          )
          (br $token_handled)
        )
      )

      ;; Handle number literals
      (if (call $is_digit (local.get $char))
        (then
          (local.set $next_pos (call $scan_number (local.get $pos)))
          (local.set $token_idx
            (call $store_token
              (global.get $TOKEN_NUMBER_LITERAL)
              (local.get $pos)
            )
          )
          (br $token_handled)
        )
      )

      ;; Handle operators and braces
      (block $operator_handled
        ;; Check for colon operators
        (if (i32.eq (local.get $char) (i32.const 0x3a))  ;; :
          (then
            ;; Get operator type and next position
            (call $scan_colon_op (local.get $pos))
            (local.set $next_pos)
            (local.set $token_type)
            (local.set $token_idx
              (call $store_token
                (local.get $token_type)
                (local.get $pos)
              )
            )
            (br $operator_handled)
          )
        )

        ;; Check for =>
        (if (i32.eq (local.get $char) (i32.const 0x3d))  ;; =
          (then
            (if (i32.eq
                  (i32.load8_u (i32.add (local.get $pos) (i32.const 1)))
                  (i32.const 0x3e)  ;; >
                )
              (then
                (local.set $token_idx
                  (call $store_token
                    (global.get $TOKEN_ARROW)
                    (local.get $pos)
                  )
                )
                (local.set $next_pos
                  (i32.add (local.get $pos) (i32.const 2))
                )
                (br $operator_handled)
              )
            )
          )
        )

        ;; Check for braces
        (if (i32.eq (local.get $char) (i32.const 0x7b))  ;; {
          (then
            (local.set $token_idx
              (call $store_token
                (global.get $TOKEN_LBRACE)
                (local.get $pos)
              )
            )
            (local.set $next_pos
              (i32.add (local.get $pos) (i32.const 1))
            )
            (br $operator_handled)
          )
        )
        (if (i32.eq (local.get $char) (i32.const 0x7d))  ;; }
          (then
            (local.set $token_idx
              (call $store_token
                (global.get $TOKEN_RBRACE)
                (local.get $pos)
              )
            )
            (local.set $next_pos
              (i32.add (local.get $pos) (i32.const 1))
            )
            (br $operator_handled)
          )
        )
      )

      ;; If we get here, character is unknown
      (local.set $token_idx
        (call $store_token
          (global.get $TOKEN_ERROR)
          (local.get $pos)
        )
      )
      (local.set $next_pos
        (i32.add (local.get $pos) (i32.const 1))
      )
    )

    ;; Return token index and next position
    (return (local.get $token_idx) (local.get $next_pos))
  )

  ;; Scan entire text and tokenize it
  ;; @param text_start i32 - Start position in memory of text to scan
  ;; @param text_len i32 - Length of text to scan
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $scan_text (param $text_start i32) (param $text_len i32) (result i32)
    (local $pos i32)
    (local $end_pos i32)
    (local $token_idx i32)
    (local $next_pos i32)
    (local $result i32)

    ;; Initialize position variables
    (local.set $pos (local.get $text_start))
    (local.set $end_pos (i32.add (local.get $text_start) (local.get $text_len)))

    ;; Reset token count at start of scanning
    (global.set $token_count (i32.const 0))

    ;; Process all characters in the text
    (loop $scan_loop
      ;; Check if we've reached end of text
      (if (i32.ge_u (local.get $pos) (local.get $end_pos))
        (then
          ;; Add EOF token and return success
          (drop (call $store_token (global.get $TOKEN_EOF) (local.get $pos)))
          (return (i32.const 1))
        )
      )

      ;; Get next token
      (call $next_token (local.get $pos))
      (local.set $token_idx)
      (local.set $next_pos)

      ;; Check for error token
      (if (i32.eq (local.get $token_idx) (i32.const -1))
        (then
          ;; Error occurred, return failure
          (return (i32.const 0))
        )
      )

      ;; Safety check: ensure position advances to prevent infinite loops
      (if (i32.le_u (local.get $next_pos) (local.get $pos))
        (then
          ;; Position didn't advance, force advancement to prevent infinite loop
          (local.set $next_pos (i32.add (local.get $pos) (i32.const 1)))
        )
      )

      ;; Move to next position
      (local.set $pos (local.get $next_pos))
      (br $scan_loop)
    )

    ;; Should never reach here
    (i32.const 0)
  )

  ;; Export main lexer functions
  (export "next_token" (func $next_token))
  (export "scan_text" (func $scan_text))
)
