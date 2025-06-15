;; Novo Lexer Keyword Recognition
;; Handles keyword matching and classification

(module $novo_lexer_keywords
  ;; Import memory from memory module
  (import "memory" "memory" (memory 1))

  ;; Import token constants
  (import "tokens" "TOKEN_IDENTIFIER" (global $TOKEN_IDENTIFIER i32))

  ;; Keyword matching data
  (data (i32.const 1024) "func\00inline\00return\00if\00else\00while\00break\00continue\00match\00bool\00s8\00s16\00s32\00s64\00u8\00u16\00u32\00u64\00f32\00f64\00char\00string\00list\00option\00result\00tuple\00record\00variant\00enum\00flags\00type\00resource\00some\00none\00ok\00error\00true\00false\00")

  ;; Function to check if identifier is a keyword
  (func $is_keyword (param $id_start i32) (param $id_len i32) (result i32)
    (local $keyword_ptr i32)
    (local $i i32)
    (local $keyword_start i32)

    ;; Start at beginning of keyword data
    (local.set $keyword_ptr (i32.const 1024))

    ;; For each keyword
    (block $done
      (loop $next_keyword
        ;; Check for end of keywords (double null)
        (br_if $done (i32.eqz (i32.load8_u (local.get $keyword_ptr))))

        ;; Compare keyword
        (local.set $i (i32.const 0))
        (local.set $keyword_start (local.get $keyword_ptr))

        (block $mismatch
          (loop $check_char
            ;; If we've reached end of identifier, check if keyword also ends
            (if (i32.eq (local.get $i) (local.get $id_len))
              (then
                ;; If keyword ends here too, we found a match
                (if (i32.eqz (i32.load8_u (i32.add (local.get $keyword_start) (local.get $i))))
                  (then
                    ;; Calculate keyword token type based on position
                    (return (i32.add
                      (i32.const 11)  ;; Base keyword token type
                      (i32.div_u
                        (i32.sub (local.get $keyword_start) (i32.const 1024))
                        (i32.const 10) ;; Approximate average keyword length
                      )
                    ))
                  )
                )
                (br $mismatch)
              )
            )

            ;; Compare characters
            (if (i32.ne
                  (i32.load8_u (i32.add (local.get $id_start) (local.get $i)))
                  (i32.load8_u (i32.add (local.get $keyword_start) (local.get $i))))
              (then (br $mismatch))
            )

            ;; Next character
            (local.set $i (i32.add (local.get $i) (i32.const 1)))
            (br $check_char)
          )
        )

        ;; Skip to next keyword
        (block $found_null
          (loop $find_null
            (local.set $keyword_ptr (i32.add (local.get $keyword_ptr) (i32.const 1)))
            (br_if $found_null (i32.eqz (i32.load8_u (local.get $keyword_ptr))))
            (br $find_null)
          )
        )
        (local.set $keyword_ptr (i32.add (local.get $keyword_ptr) (i32.const 1)))
        (br $next_keyword)
      )
    )

    ;; Not found - return identifier token type
    (return (global.get $TOKEN_IDENTIFIER))
  )

  ;; Export keyword recognition function
  (export "is_keyword" (func $is_keyword))
)
