;; Novo Lexer Identifier Scanning
;; Functions for scanning and validating identifiers

(module $novo_lexer_identifiers
  ;; Import memory from memory module
  (import "memory" "memory" (memory 1))

  ;; Import token constants and utility functions
  (import "tokens" "TOKEN_ERROR" (global $TOKEN_ERROR i32))
  (import "tokens" "TOKEN_IDENTIFIER" (global $TOKEN_IDENTIFIER i32))
  (import "char_utils" "is_letter" (func $is_letter (param i32) (result i32)))
  (import "char_utils" "is_kebab_char" (func $is_kebab_char (param i32) (result i32)))
  (import "char_utils" "is_valid_word" (func $is_valid_word (param i32 i32) (result i32)))
  (import "keywords" "is_keyword" (func $is_keyword (param i32 i32) (result i32)))
  (import "lexer_token_storage" "store_identifier" (func $store_identifier (param i32 i32) (result i32)))

  ;; Scan an identifier or keyword
  (func $scan_identifier (param $pos i32) (result i32 i32)
    (local $current_pos i32)
    (local $start_pos i32)
    (local $word_start i32)
    (local $len i32)
    (local $token_type i32)
    (local $is_prefixed i32)

    (local.set $current_pos (local.get $pos))
    (local.set $start_pos (local.get $pos))

    ;; Check for % prefix
    (if (i32.eq
          (i32.load8_u (local.get $current_pos))
          (i32.const 0x25) ;; %
        )
      (then
        (local.set $is_prefixed (i32.const 1))
        (local.set $current_pos (i32.add (local.get $current_pos) (i32.const 1)))
      )
      (else
        (local.set $is_prefixed (i32.const 0))
      )
    )

    ;; First character must be a letter
    (if (i32.eqz (call $is_letter (i32.load8_u (local.get $current_pos))))
      (then
        ;; Invalid identifier start
        (return (global.get $TOKEN_ERROR) (local.get $current_pos))
      )
    )

    ;; Scan the identifier
    (local.set $word_start (local.get $current_pos))
    (block $done
      (loop $scan_loop
        (local.set $current_pos (i32.add (local.get $current_pos) (i32.const 1)))
        (block $end_word
          ;; Check for hyphen
          (if (i32.eq (i32.load8_u (local.get $current_pos)) (i32.const 0x2d)) ;; -
            (then
              ;; Validate previous word
              (if (i32.eqz (call $is_valid_word
                  (local.get $word_start)
                  (local.get $current_pos)))
                (then
                  ;; Invalid word format
                  (return (global.get $TOKEN_ERROR) (local.get $current_pos))
                )
              )
              ;; Start new word after hyphen
              (local.set $current_pos (i32.add (local.get $current_pos) (i32.const 1)))
              (local.set $word_start (local.get $current_pos))
              (br $scan_loop)
            )
          )

          ;; Continue if valid identifier character
          (br_if $scan_loop (call $is_kebab_char (i32.load8_u (local.get $current_pos))))

          ;; End of identifier
          (br $done)
        )
      )
    )

    ;; Validate final word
    (if (i32.eqz (call $is_valid_word
        (local.get $word_start)
        (local.get $current_pos)))
      (then
        ;; Invalid word format
        (return (global.get $TOKEN_ERROR) (local.get $current_pos))
      )
    )

    ;; Calculate length excluding %
    (local.set $len (i32.sub
      (local.get $current_pos)
      (local.get $start_pos))
    )

    ;; If not prefixed, check if it's a keyword
    (if (i32.eqz (local.get $is_prefixed))
      (then
        (local.set $token_type
          (call $is_keyword
            (local.get $start_pos)
            (local.get $len)
          )
        )
      )
      (else
        (local.set $token_type (global.get $TOKEN_IDENTIFIER))
      )
    )

    ;; Store the identifier
    (call $store_identifier (local.get $start_pos) (local.get $len))

    ;; Return token type and next position
    (return (local.get $token_type) (local.get $current_pos))
  )

  ;; Export identifier scanning function
  (export "scan_identifier" (func $scan_identifier))
)
