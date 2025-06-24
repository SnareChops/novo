;; Novo Lexer Keyword Recognition
;; Handles keyword matching and classification

(module $novo_lexer_keywords
  ;; Import memory from memory module
  (import "memory" "memory" (memory 1))

  ;; Import token constants
  (import "tokens" "TOKEN_IDENTIFIER" (global $TOKEN_IDENTIFIER i32))
  (import "tokens" "TOKEN_KW_FUNC" (global $TOKEN_KW_FUNC i32))
  (import "tokens" "TOKEN_KW_INLINE" (global $TOKEN_KW_INLINE i32))
  (import "tokens" "TOKEN_KW_RETURN" (global $TOKEN_KW_RETURN i32))
  (import "tokens" "TOKEN_KW_IF" (global $TOKEN_KW_IF i32))
  (import "tokens" "TOKEN_KW_ELSE" (global $TOKEN_KW_ELSE i32))
  (import "tokens" "TOKEN_KW_WHILE" (global $TOKEN_KW_WHILE i32))
  (import "tokens" "TOKEN_KW_BREAK" (global $TOKEN_KW_BREAK i32))
  (import "tokens" "TOKEN_KW_CONTINUE" (global $TOKEN_KW_CONTINUE i32))
  (import "tokens" "TOKEN_KW_MATCH" (global $TOKEN_KW_MATCH i32))
  (import "tokens" "TOKEN_KW_BOOL" (global $TOKEN_KW_BOOL i32))
  (import "tokens" "TOKEN_KW_STRING" (global $TOKEN_KW_STRING i32))
  (import "tokens" "TOKEN_KW_TRUE" (global $TOKEN_KW_TRUE i32))
  (import "tokens" "TOKEN_KW_FALSE" (global $TOKEN_KW_FALSE i32))

  ;; Function to check if identifier is a keyword
  (func $is_keyword (param $id_start i32) (param $id_len i32) (result i32)
    ;; Check exact keyword matches by length and content

    ;; Length 2: "if"
    (if (i32.eq (local.get $id_len) (i32.const 2))
      (then
        (if (i32.and
              (i32.eq (i32.load8_u (local.get $id_start)) (i32.const 105))      ;; 'i'
              (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 1))) (i32.const 102))) ;; 'f'
          (then (return (global.get $TOKEN_KW_IF)))
        )
      )
    )

    ;; Length 4: "func", "bool", "else", "true"
    (if (i32.eq (local.get $id_len) (i32.const 4))
      (then
        ;; Check "func"
        (if (i32.and
              (i32.and
                (i32.eq (i32.load8_u (local.get $id_start)) (i32.const 102))      ;; 'f'
                (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 1))) (i32.const 117))) ;; 'u'
              (i32.and
                (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 2))) (i32.const 110))  ;; 'n'
                (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 3))) (i32.const 99))))  ;; 'c'
          (then (return (global.get $TOKEN_KW_FUNC)))
        )

        ;; Check "bool"
        (if (i32.and
              (i32.and
                (i32.eq (i32.load8_u (local.get $id_start)) (i32.const 98))       ;; 'b'
                (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 1))) (i32.const 111))) ;; 'o'
              (i32.and
                (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 2))) (i32.const 111))  ;; 'o'
                (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 3))) (i32.const 108))))  ;; 'l'
          (then (return (global.get $TOKEN_KW_BOOL)))
        )

        ;; Check "else"
        (if (i32.and
              (i32.and
                (i32.eq (i32.load8_u (local.get $id_start)) (i32.const 101))      ;; 'e'
                (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 1))) (i32.const 108))) ;; 'l'
              (i32.and
                (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 2))) (i32.const 115))  ;; 's'
                (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 3))) (i32.const 101))))  ;; 'e'
          (then (return (global.get $TOKEN_KW_ELSE)))
        )

        ;; Check "true"
        (if (i32.and
              (i32.and
                (i32.eq (i32.load8_u (local.get $id_start)) (i32.const 116))      ;; 't'
                (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 1))) (i32.const 114))) ;; 'r'
              (i32.and
                (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 2))) (i32.const 117))  ;; 'u'
                (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 3))) (i32.const 101))))  ;; 'e'
          (then (return (global.get $TOKEN_KW_TRUE)))
        )
      )
    )

    ;; Length 5: "while", "break", "match", "false"
    (if (i32.eq (local.get $id_len) (i32.const 5))
      (then
        ;; Check "while"
        (if (i32.and
              (i32.and
                (i32.and
                  (i32.eq (i32.load8_u (local.get $id_start)) (i32.const 119))      ;; 'w'
                  (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 1))) (i32.const 104))) ;; 'h'
                (i32.and
                  (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 2))) (i32.const 105))  ;; 'i'
                  (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 3))) (i32.const 108))))  ;; 'l'
              (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 4))) (i32.const 101)))   ;; 'e'
          (then (return (global.get $TOKEN_KW_WHILE)))
        )

        ;; Check "break"
        (if (i32.and
              (i32.and
                (i32.and
                  (i32.eq (i32.load8_u (local.get $id_start)) (i32.const 98))       ;; 'b'
                  (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 1))) (i32.const 114))) ;; 'r'
                (i32.and
                  (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 2))) (i32.const 101))  ;; 'e'
                  (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 3))) (i32.const 97))))  ;; 'a'
              (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 4))) (i32.const 107)))   ;; 'k'
          (then (return (global.get $TOKEN_KW_BREAK)))
        )

        ;; Check "match"
        (if (i32.and
              (i32.and
                (i32.and
                  (i32.eq (i32.load8_u (local.get $id_start)) (i32.const 109))      ;; 'm'
                  (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 1))) (i32.const 97))) ;; 'a'
                (i32.and
                  (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 2))) (i32.const 116))  ;; 't'
                  (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 3))) (i32.const 99))))  ;; 'c'
              (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 4))) (i32.const 104)))   ;; 'h'
          (then (return (global.get $TOKEN_KW_MATCH)))
        )

        ;; Check "false"
        (if (i32.and
              (i32.and
                (i32.and
                  (i32.eq (i32.load8_u (local.get $id_start)) (i32.const 102))      ;; 'f'
                  (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 1))) (i32.const 97))) ;; 'a'
                (i32.and
                  (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 2))) (i32.const 108))  ;; 'l'
                  (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 3))) (i32.const 115))))  ;; 's'
              (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 4))) (i32.const 101)))   ;; 'e'
          (then (return (global.get $TOKEN_KW_FALSE)))
        )
      )
    )

    ;; Length 6: "inline", "return", "string"
    (if (i32.eq (local.get $id_len) (i32.const 6))
      (then
        ;; Check "inline"
        (if (i32.and
              (i32.and
                (i32.and
                  (i32.and
                    (i32.eq (i32.load8_u (local.get $id_start)) (i32.const 105))      ;; 'i'
                    (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 1))) (i32.const 110))) ;; 'n'
                  (i32.and
                    (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 2))) (i32.const 108))  ;; 'l'
                    (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 3))) (i32.const 105))))  ;; 'i'
                (i32.and
                  (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 4))) (i32.const 110))   ;; 'n'
                  (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 5))) (i32.const 101))))   ;; 'e'
              (i32.const 1)) ;; Always true if all conditions met
          (then (return (global.get $TOKEN_KW_INLINE)))
        )

        ;; Check "return"
        (if (i32.and
              (i32.and
                (i32.and
                  (i32.and
                    (i32.eq (i32.load8_u (local.get $id_start)) (i32.const 114))      ;; 'r'
                    (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 1))) (i32.const 101))) ;; 'e'
                  (i32.and
                    (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 2))) (i32.const 116))  ;; 't'
                    (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 3))) (i32.const 117))))  ;; 'u'
                (i32.and
                  (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 4))) (i32.const 114))   ;; 'r'
                  (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 5))) (i32.const 110))))   ;; 'n'
              (i32.const 1)) ;; Always true if all conditions met
          (then (return (global.get $TOKEN_KW_RETURN)))
        )

        ;; Check "string"
        (if (i32.and
              (i32.and
                (i32.and
                  (i32.and
                    (i32.eq (i32.load8_u (local.get $id_start)) (i32.const 115))      ;; 's'
                    (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 1))) (i32.const 116))) ;; 't'
                  (i32.and
                    (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 2))) (i32.const 114))  ;; 'r'
                    (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 3))) (i32.const 105))))  ;; 'i'
                (i32.and
                  (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 4))) (i32.const 110))   ;; 'n'
                  (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 5))) (i32.const 103))))   ;; 'g'
              (i32.const 1)) ;; Always true if all conditions met
          (then (return (global.get $TOKEN_KW_STRING)))
        )
      )
    )

    ;; Length 8: "continue"
    (if (i32.eq (local.get $id_len) (i32.const 8))
      (then
        ;; Check "continue"
        (if (i32.and
              (i32.and
                (i32.and
                  (i32.and
                    (i32.and
                      (i32.and
                        (i32.eq (i32.load8_u (local.get $id_start)) (i32.const 99))       ;; 'c'
                        (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 1))) (i32.const 111))) ;; 'o'
                      (i32.and
                        (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 2))) (i32.const 110))  ;; 'n'
                        (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 3))) (i32.const 116))))  ;; 't'
                    (i32.and
                      (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 4))) (i32.const 105))   ;; 'i'
                      (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 5))) (i32.const 110))))   ;; 'n'
                  (i32.and
                    (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 6))) (i32.const 117))     ;; 'u'
                    (i32.eq (i32.load8_u (i32.add (local.get $id_start) (i32.const 7))) (i32.const 101))))     ;; 'e'
                (i32.const 1)) ;; Always true if all conditions met
              (i32.const 1)) ;; Always true if all conditions met
          (then (return (global.get $TOKEN_KW_CONTINUE)))
        )
      )
    )

    ;; Not found - return identifier token type
    (return (global.get $TOKEN_IDENTIFIER))
  )

  ;; Export keyword recognition function
  (export "is_keyword" (func $is_keyword))
)
