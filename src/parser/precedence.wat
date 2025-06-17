;; Novo Parser Operator Precedence
;; Implements PEMDAS precedence rules for mathematical expressions

(module $novo_parser_precedence
  ;; Import token constants
  (import "lexer_tokens" "TOKEN_PLUS" (global $TOKEN_PLUS i32))
  (import "lexer_tokens" "TOKEN_MINUS" (global $TOKEN_MINUS i32))
  (import "lexer_tokens" "TOKEN_MULTIPLY" (global $TOKEN_MULTIPLY i32))
  (import "lexer_tokens" "TOKEN_DIVIDE" (global $TOKEN_DIVIDE i32))
  (import "lexer_tokens" "TOKEN_MODULO" (global $TOKEN_MODULO i32))

  ;; Precedence levels (higher number = higher precedence)
  (global $PRECEDENCE_NONE i32 (i32.const 0))
  (global $PRECEDENCE_ASSIGNMENT i32 (i32.const 1))    ;; :=
  (global $PRECEDENCE_ADDITIVE i32 (i32.const 2))      ;; + -
  (global $PRECEDENCE_MULTIPLICATIVE i32 (i32.const 3)) ;; * / %
  (global $PRECEDENCE_UNARY i32 (i32.const 4))         ;; - (unary)
  (global $PRECEDENCE_CALL i32 (i32.const 5))          ;; func()
  (global $PRECEDENCE_PRIMARY i32 (i32.const 6))       ;; literals, identifiers

  ;; Get precedence level for a token type
  (func $get_precedence (export "get_precedence") (param $token_type i32) (result i32)
    ;; Addition and subtraction
    (if (i32.eq (local.get $token_type) (global.get $TOKEN_PLUS))
      (then (return (global.get $PRECEDENCE_ADDITIVE)))
    )
    (if (i32.eq (local.get $token_type) (global.get $TOKEN_MINUS))
      (then (return (global.get $PRECEDENCE_ADDITIVE)))
    )

    ;; Multiplication, division, and modulo
    (if (i32.eq (local.get $token_type) (global.get $TOKEN_MULTIPLY))
      (then (return (global.get $PRECEDENCE_MULTIPLICATIVE)))
    )
    (if (i32.eq (local.get $token_type) (global.get $TOKEN_DIVIDE))
      (then (return (global.get $PRECEDENCE_MULTIPLICATIVE)))
    )
    (if (i32.eq (local.get $token_type) (global.get $TOKEN_MODULO))
      (then (return (global.get $PRECEDENCE_MULTIPLICATIVE)))
    )

    ;; Default to no precedence
    (global.get $PRECEDENCE_NONE)
  )

  ;; Check if an operator is left-associative (true for all our operators)
  (func $is_left_associative (export "is_left_associative") (param $token_type i32) (result i32)
    ;; All mathematical operators are left-associative
    (if (i32.or
          (i32.or
            (i32.eq (local.get $token_type) (global.get $TOKEN_PLUS))
            (i32.eq (local.get $token_type) (global.get $TOKEN_MINUS))
          )
          (i32.or
            (i32.or
              (i32.eq (local.get $token_type) (global.get $TOKEN_MULTIPLY))
              (i32.eq (local.get $token_type) (global.get $TOKEN_DIVIDE))
            )
            (i32.eq (local.get $token_type) (global.get $TOKEN_MODULO))
          )
        )
      (then (return (i32.const 1)))
    )

    ;; Default to left-associative
    (i32.const 1)
  )

  ;; Check if a token is a binary operator
  (func $is_binary_operator (export "is_binary_operator") (param $token_type i32) (result i32)
    (i32.or
      (i32.or
        (i32.eq (local.get $token_type) (global.get $TOKEN_PLUS))
        (i32.eq (local.get $token_type) (global.get $TOKEN_MINUS))
      )
      (i32.or
        (i32.or
          (i32.eq (local.get $token_type) (global.get $TOKEN_MULTIPLY))
          (i32.eq (local.get $token_type) (global.get $TOKEN_DIVIDE))
        )
        (i32.eq (local.get $token_type) (global.get $TOKEN_MODULO))
      )
    )
  )

  ;; Export precedence constants for use by other modules
  (export "PRECEDENCE_NONE" (global $PRECEDENCE_NONE))
  (export "PRECEDENCE_ASSIGNMENT" (global $PRECEDENCE_ASSIGNMENT))
  (export "PRECEDENCE_ADDITIVE" (global $PRECEDENCE_ADDITIVE))
  (export "PRECEDENCE_MULTIPLICATIVE" (global $PRECEDENCE_MULTIPLICATIVE))
  (export "PRECEDENCE_UNARY" (global $PRECEDENCE_UNARY))
  (export "PRECEDENCE_CALL" (global $PRECEDENCE_CALL))
  (export "PRECEDENCE_PRIMARY" (global $PRECEDENCE_PRIMARY))
)
