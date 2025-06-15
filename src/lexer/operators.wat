;; Novo Lexer Operator Handling
;; Functions for scanning and processing operators

(module $novo_lexer_operators
  ;; Import memory from memory module
  (import "memory" "memory" (memory 1))

  ;; Import token constants and character utilities
  (import "tokens" "TOKEN_COLON" (global $TOKEN_COLON i32))
  (import "tokens" "TOKEN_ASSIGN" (global $TOKEN_ASSIGN i32))
  (import "tokens" "TOKEN_META" (global $TOKEN_META i32))
  (import "tokens" "TOKEN_PLUS" (global $TOKEN_PLUS i32))
  (import "tokens" "TOKEN_MINUS" (global $TOKEN_MINUS i32))
  (import "tokens" "TOKEN_MULTIPLY" (global $TOKEN_MULTIPLY i32))
  (import "tokens" "TOKEN_DIVIDE" (global $TOKEN_DIVIDE i32))
  (import "tokens" "TOKEN_MODULO" (global $TOKEN_MODULO i32))
  (import "tokens" "TOKEN_IDENTIFIER" (global $TOKEN_IDENTIFIER i32))
  (import "char_utils" "is_whitespace" (func $is_whitespace (param i32) (result i32)))
  (import "char_utils" "is_operator_char" (func $is_operator_char (param i32) (result i32)))

  ;; Space tracking state
  (global $last_char_was_space (mut i32) (i32.const 1))  ;; Start with true to allow initial token
  (global $space_required (mut i32) (i32.const 0))       ;; Whether next token must have space before

  ;; Track character spacing for operator disambiguation
  (func $update_space_tracking (param $c i32)
    ;; Update last_char_was_space based on current character
    (global.set $last_char_was_space
      (call $is_whitespace (local.get $c))
    )
  )

  ;; Space tracking functions
  (func $require_space (export "require_space")
    (global.set $space_required (i32.const 1))
  )

  (func $check_space_requirement (export "check_space_requirement") (result i32)
    (i32.or
      (i32.eqz (global.get $space_required))
      (global.get $last_char_was_space))
  )

  ;; Export functions and globals
  (export "update_space_tracking" (func $update_space_tracking))
  (export "scan_colon_op" (func $scan_colon_op))
  (export "scan_operator" (func $scan_operator))
  (export "last_char_was_space" (global $last_char_was_space))
  (export "space_required" (global $space_required))

  ;; Scan operator starting with colon
  (func $scan_colon_op (param $pos i32) (result i32 i32)
    (local $next_char i32)
    (local $next_pos i32)

    ;; Get next character
    (local.set $next_pos (i32.add (local.get $pos) (i32.const 1)))
    (local.set $next_char (i32.load8_u (local.get $next_pos)))

    ;; Check for := or ::
    (if (i32.eq (local.get $next_char) (i32.const 0x3d))  ;; =
      (then
        (return (global.get $TOKEN_ASSIGN)
                (i32.add (local.get $pos) (i32.const 2))))
    )
    (if (i32.eq (local.get $next_char) (i32.const 0x3a))  ;; :
      (then
        (return (global.get $TOKEN_META)
                (i32.add (local.get $pos) (i32.const 2))))
    )

    ;; Just a single colon
    (return (global.get $TOKEN_COLON)
            (i32.add (local.get $pos) (i32.const 1)))
  )

  ;; Scan an operator character and determine token type
  (func $scan_operator (param $pos i32) (result i32 i32)
    (local $c i32)
    (local $token_type i32)

    ;; Get the character
    (local.set $c (i32.load8_u (local.get $pos)))

    ;; Check spacing requirements for operators
    (if (i32.and
          (call $is_operator_char (local.get $c))
          (i32.eqz (global.get $last_char_was_space))
        )
      (then
        ;; No space before operator - could be part of kebab-case
        (if (i32.eq (local.get $c) (i32.const 0x2d))  ;; -
          (then
            ;; Return as potential kebab-case continuation
            (return (global.get $TOKEN_IDENTIFIER) (local.get $pos))
          )
        )
      )
    )

    ;; Determine operator token type
    (if (i32.eq (local.get $c) (i32.const 0x2b))  ;; +
      (then
        (local.set $token_type (global.get $TOKEN_PLUS))
      )
    )
    (if (i32.eq (local.get $c) (i32.const 0x2d))  ;; -
      (then
        (local.set $token_type (global.get $TOKEN_MINUS))
      )
    )
    (if (i32.eq (local.get $c) (i32.const 0x2a))  ;; *
      (then
        (local.set $token_type (global.get $TOKEN_MULTIPLY))
      )
    )
    (if (i32.eq (local.get $c) (i32.const 0x2f))  ;; /
      (then
        (local.set $token_type (global.get $TOKEN_DIVIDE))
      )
    )
    (if (i32.eq (local.get $c) (i32.const 0x25))  ;; %
      (then
        (local.set $token_type (global.get $TOKEN_MODULO))
      )
    )

    ;; Set space required after operator
    (global.set $space_required (i32.const 1))

    (return (local.get $token_type) (i32.add (local.get $pos) (i32.const 1)))
  )
)
