;; Novo Lexer Character Utilities
;; Functions for character classification and validation

(module $novo_lexer_char_utils
  ;; Import memory from memory module
  (import "memory" "memory" (memory 1))

  ;; Utility Functions
  (func $is_letter (param $c i32) (result i32)
    (i32.or
      (i32.and
        (i32.ge_s (local.get $c) (i32.const 97))  ;; >= 'a'
        (i32.le_s (local.get $c) (i32.const 122)) ;; <= 'z'
      )
      (i32.and
        (i32.ge_s (local.get $c) (i32.const 65))  ;; >= 'A'
        (i32.le_s (local.get $c) (i32.const 90))  ;; <= 'Z'
      )
    )
  )

  (func $is_digit (param $c i32) (result i32)
    (i32.and
      (i32.ge_s (local.get $c) (i32.const 48))  ;; >= '0'
      (i32.le_s (local.get $c) (i32.const 57))  ;; <= '9'
    )
  )

  (func $is_kebab_char (param $c i32) (result i32)
    (i32.or
      (i32.or
        ;; Only lowercase letters for kebab-case
        (i32.and
          (i32.ge_u (local.get $c) (i32.const 97))   ;; >= 'a'
          (i32.le_u (local.get $c) (i32.const 122))  ;; <= 'z'
        )
        (call $is_digit (local.get $c))
      )
      (i32.eq (local.get $c) (i32.const 45))    ;; '-'
    )
  )

  ;; Check for valid identifier rules
  (func $is_valid_identifier_start (param $c i32) (result i32)
    (i32.or
      ;; Only lowercase letters for identifier start
      (i32.and
        (i32.ge_u (local.get $c) (i32.const 97))   ;; >= 'a'
        (i32.le_u (local.get $c) (i32.const 122))  ;; <= 'z'
      )
      (i32.eq (local.get $c) (i32.const 0x25))  ;; Or % sign (0x25)
    )
  )

  ;; Helper function for whitespace detection
  (func $is_whitespace (param $c i32) (result i32)
    (i32.or
      (i32.or
        (i32.eq (local.get $c) (i32.const 32))  ;; space
        (i32.eq (local.get $c) (i32.const 9))   ;; tab
      )
      (i32.eq (local.get $c) (i32.const 10))    ;; newline
    )
  )

  ;; Function to check if a character is an operator
  (func $is_operator_char (param $c i32) (result i32)
    (if (i32.eq (local.get $c) (i32.const 0x2b))  ;; +
      (then (return (i32.const 1)))
    )
    (if (i32.eq (local.get $c) (i32.const 0x2d))  ;; -
      (then (return (i32.const 1)))
    )
    (if (i32.eq (local.get $c) (i32.const 0x2a))  ;; *
      (then (return (i32.const 1)))
    )
    (if (i32.eq (local.get $c) (i32.const 0x2f))  ;; /
      (then (return (i32.const 1)))
    )
    (if (i32.eq (local.get $c) (i32.const 0x25))  ;; %
      (then (return (i32.const 1)))
    )
    (i32.const 0)
  )

  ;; Validate kebab-case word rules
  (func $is_valid_word (param $start i32) (param $end i32) (result i32)
    (local $pos i32)
    (local $c i32)
    (local $had_uppercase i32)
    (local $had_lowercase i32)

    ;; Can't be empty
    (if (i32.le_s (local.get $end) (local.get $start))
      (then (return (i32.const 0)))
    )

    (local.set $pos (local.get $start))
    (local.set $had_uppercase (i32.const 0))
    (local.set $had_lowercase (i32.const 0))

    ;; First char must be letter
    (local.set $c (i32.load8_u (local.get $pos)))
    (if (i32.eqz (call $is_letter (local.get $c)))
      (then (return (i32.const 0)))
    )

    ;; Track case of first character
    (if (i32.and
          (call $is_letter (local.get $c))
          (i32.and
            (i32.ge_s (local.get $c) (i32.const 65))  ;; >= 'A'
            (i32.le_s (local.get $c) (i32.const 90)))) ;; <= 'Z'
      (then (local.set $had_uppercase (i32.const 1)))
      (else (local.set $had_lowercase (i32.const 1)))
    )

    ;; Check remaining characters
    (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
    (block $done
      (loop $check_chars
        (br_if $done (i32.ge_s (local.get $pos) (local.get $end)))

        (local.set $c (i32.load8_u (local.get $pos)))

        ;; Must be letter or digit
        (if (i32.eqz
          (i32.or
            (call $is_letter (local.get $c))
            (call $is_digit (local.get $c))
          ))
          (then (return (i32.const 0)))
        )

        ;; Track case for consistency check
        (if (call $is_letter (local.get $c))
          (then
            ;; Only check case for letters, not digits
            (if (i32.and
                  (i32.ge_s (local.get $c) (i32.const 65))  ;; >= 'A'
                  (i32.le_s (local.get $c) (i32.const 90))) ;; <= 'Z'
              (then
                ;; Uppercase letter
                (if (local.get $had_lowercase)
                  (then (return (i32.const 0))) ;; Mixed case in word
                )
                (local.set $had_uppercase (i32.const 1))
              )
              (else
                ;; Lowercase letter
                (if (local.get $had_uppercase)
                  (then (return (i32.const 0))) ;; Mixed case in word
                )
                (local.set $had_lowercase (i32.const 1))
              )
            )
          )
        )

        (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
        (br $check_chars)
      )
    )

    ;; Valid word
    (i32.const 1)
  )

  ;; Helper function to skip whitespace
  (func $skip_whitespace (param $pos i32) (result i32)
    (local $current_pos i32)
    (local.set $current_pos (local.get $pos))

    (loop $whitespace_loop
      ;; Continue looping while current character IS whitespace
      (if (call $is_whitespace (i32.load8_u (local.get $current_pos)))
        (then
          (local.set $current_pos
            (i32.add (local.get $current_pos) (i32.const 1))
          )
          (br $whitespace_loop)
        )
      )
    )

    (local.get $current_pos)
  )

  ;; Export character utility functions
  (export "is_letter" (func $is_letter))
  (export "is_digit" (func $is_digit))
  (export "is_kebab_char" (func $is_kebab_char))
  (export "is_valid_identifier_start" (func $is_valid_identifier_start))
  (export "is_whitespace" (func $is_whitespace))
  (export "is_operator_char" (func $is_operator_char))
  (export "is_valid_word" (func $is_valid_word))
  (export "skip_whitespace" (func $skip_whitespace))
)
