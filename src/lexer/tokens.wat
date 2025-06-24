;; Novo Lexer Token Definitions
;; Defines all token types and constants used by the lexer

(module $novo_lexer_tokens
  ;; Token Types (results encoded as i32)
  (global $TOKEN_ERROR i32 (i32.const 0))        ;; Error token
  (global $TOKEN_IDENTIFIER i32 (i32.const 1))   ;; kebab-case identifier
  (global $TOKEN_COLON i32 (i32.const 2))        ;; :
  (global $TOKEN_ASSIGN i32 (i32.const 3))       ;; :=
  (global $TOKEN_ARROW i32 (i32.const 4))        ;; =>
  (global $TOKEN_META i32 (i32.const 5))         ;; ::
  (global $TOKEN_LBRACE i32 (i32.const 6))       ;; {
  (global $TOKEN_RBRACE i32 (i32.const 7))       ;; }
  (global $TOKEN_WAT_INSTR i32 (i32.const 8))    ;; WAT instruction
  (global $TOKEN_WHITESPACE i32 (i32.const 9))   ;; Space, tab, newline
  (global $TOKEN_EOF i32 (i32.const 10))         ;; End of input

  ;; Keywords
  (global $TOKEN_KW_FUNC i32 (i32.const 11))      ;; func
  (global $TOKEN_KW_INLINE i32 (i32.const 12))    ;; inline
  (global $TOKEN_KW_RETURN i32 (i32.const 13))    ;; return
  (global $TOKEN_KW_IF i32 (i32.const 14))        ;; if
  (global $TOKEN_KW_ELSE i32 (i32.const 15))      ;; else
  (global $TOKEN_KW_WHILE i32 (i32.const 16))     ;; while
  (global $TOKEN_KW_BREAK i32 (i32.const 17))     ;; break
  (global $TOKEN_KW_CONTINUE i32 (i32.const 18))  ;; continue
  (global $TOKEN_KW_MATCH i32 (i32.const 19))     ;; match

  ;; Type Keywords
  (global $TOKEN_KW_BOOL i32 (i32.const 20))      ;; bool
  (global $TOKEN_KW_S8 i32 (i32.const 21))        ;; s8
  (global $TOKEN_KW_S16 i32 (i32.const 22))       ;; s16
  (global $TOKEN_KW_S32 i32 (i32.const 23))       ;; s32
  (global $TOKEN_KW_S64 i32 (i32.const 24))       ;; s64
  (global $TOKEN_KW_U8 i32 (i32.const 25))        ;; u8
  (global $TOKEN_KW_U16 i32 (i32.const 26))       ;; u16
  (global $TOKEN_KW_U32 i32 (i32.const 27))       ;; u32
  (global $TOKEN_KW_U64 i32 (i32.const 28))       ;; u64
  (global $TOKEN_KW_F32 i32 (i32.const 29))       ;; f32
  (global $TOKEN_KW_F64 i32 (i32.const 30))       ;; f64
  (global $TOKEN_KW_CHAR i32 (i32.const 31))      ;; char
  (global $TOKEN_KW_STRING i32 (i32.const 32))    ;; string

  ;; Compound Type Keywords
  (global $TOKEN_KW_LIST i32 (i32.const 33))      ;; list
  (global $TOKEN_KW_OPTION i32 (i32.const 34))    ;; option
  (global $TOKEN_KW_RESULT i32 (i32.const 35))    ;; result
  (global $TOKEN_KW_TUPLE i32 (i32.const 36))     ;; tuple
  (global $TOKEN_KW_RECORD i32 (i32.const 37))    ;; record
  (global $TOKEN_KW_VARIANT i32 (i32.const 38))   ;; variant
  (global $TOKEN_KW_ENUM i32 (i32.const 39))      ;; enum
  (global $TOKEN_KW_FLAGS i32 (i32.const 40))     ;; flags
  (global $TOKEN_KW_TYPE i32 (i32.const 41))      ;; type
  (global $TOKEN_KW_RESOURCE i32 (i32.const 42))  ;; resource

  ;; Pattern Matching Keywords
  (global $TOKEN_KW_SOME i32 (i32.const 43))      ;; some
  (global $TOKEN_KW_NONE i32 (i32.const 44))      ;; none
  (global $TOKEN_KW_OK i32 (i32.const 45))        ;; ok
  (global $TOKEN_KW_ERROR i32 (i32.const 46))     ;; error

  ;; Boolean Literals
  (global $TOKEN_KW_TRUE i32 (i32.const 47))      ;; true
  (global $TOKEN_KW_FALSE i32 (i32.const 48))     ;; false

  ;; Component System Keywords
  (global $TOKEN_KW_COMPONENT i32 (i32.const 49)) ;; component
  (global $TOKEN_KW_INTERFACE i32 (i32.const 50)) ;; interface
  (global $TOKEN_KW_WORLD i32 (i32.const 51))     ;; world
  (global $TOKEN_KW_IMPORT i32 (i32.const 52))    ;; import
  (global $TOKEN_KW_EXPORT i32 (i32.const 53))    ;; export
  (global $TOKEN_KW_USE i32 (i32.const 54))       ;; use
  (global $TOKEN_KW_INCLUDE i32 (i32.const 55))   ;; include

  ;; Mathematical Operators
  (global $TOKEN_PLUS i32 (i32.const 56))        ;; +
  (global $TOKEN_MINUS i32 (i32.const 57))       ;; -
  (global $TOKEN_MULTIPLY i32 (i32.const 58))    ;; *
  (global $TOKEN_DIVIDE i32 (i32.const 59))      ;; /
  (global $TOKEN_MODULO i32 (i32.const 60))      ;; %

  ;; Literals
  (global $TOKEN_NUMBER_LITERAL i32 (i32.const 61))  ;; 42, 3.14, etc.
  (global $TOKEN_STRING_LITERAL i32 (i32.const 62))  ;; "hello world"

  ;; Punctuation
  (global $TOKEN_COMMA i32 (i32.const 63))          ;; ,

  ;; WAT-style Function Syntax
  (global $TOKEN_LPAREN i32 (i32.const 64))      ;; (
  (global $TOKEN_RPAREN i32 (i32.const 65))      ;; )

  ;; Export all token constants for use by other modules
  (export "TOKEN_ERROR" (global $TOKEN_ERROR))
  (export "TOKEN_IDENTIFIER" (global $TOKEN_IDENTIFIER))
  (export "TOKEN_COLON" (global $TOKEN_COLON))
  (export "TOKEN_ASSIGN" (global $TOKEN_ASSIGN))
  (export "TOKEN_ARROW" (global $TOKEN_ARROW))
  (export "TOKEN_META" (global $TOKEN_META))
  (export "TOKEN_LBRACE" (global $TOKEN_LBRACE))
  (export "TOKEN_RBRACE" (global $TOKEN_RBRACE))
  (export "TOKEN_WAT_INSTR" (global $TOKEN_WAT_INSTR))
  (export "TOKEN_WHITESPACE" (global $TOKEN_WHITESPACE))
  (export "TOKEN_EOF" (global $TOKEN_EOF))

  ;; Keyword tokens
  (export "TOKEN_KW_FUNC" (global $TOKEN_KW_FUNC))
  (export "TOKEN_KW_INLINE" (global $TOKEN_KW_INLINE))
  (export "TOKEN_KW_RETURN" (global $TOKEN_KW_RETURN))
  (export "TOKEN_KW_IF" (global $TOKEN_KW_IF))
  (export "TOKEN_KW_ELSE" (global $TOKEN_KW_ELSE))
  (export "TOKEN_KW_WHILE" (global $TOKEN_KW_WHILE))
  (export "TOKEN_KW_BREAK" (global $TOKEN_KW_BREAK))
  (export "TOKEN_KW_CONTINUE" (global $TOKEN_KW_CONTINUE))
  (export "TOKEN_KW_MATCH" (global $TOKEN_KW_MATCH))

  ;; Type keyword tokens
  (export "TOKEN_KW_BOOL" (global $TOKEN_KW_BOOL))
  (export "TOKEN_KW_S8" (global $TOKEN_KW_S8))
  (export "TOKEN_KW_S16" (global $TOKEN_KW_S16))
  (export "TOKEN_KW_S32" (global $TOKEN_KW_S32))
  (export "TOKEN_KW_S64" (global $TOKEN_KW_S64))
  (export "TOKEN_KW_U8" (global $TOKEN_KW_U8))
  (export "TOKEN_KW_U16" (global $TOKEN_KW_U16))
  (export "TOKEN_KW_U32" (global $TOKEN_KW_U32))
  (export "TOKEN_KW_U64" (global $TOKEN_KW_U64))
  (export "TOKEN_KW_F32" (global $TOKEN_KW_F32))
  (export "TOKEN_KW_F64" (global $TOKEN_KW_F64))
  (export "TOKEN_KW_CHAR" (global $TOKEN_KW_CHAR))
  (export "TOKEN_KW_STRING" (global $TOKEN_KW_STRING))

  ;; Compound type tokens
  (export "TOKEN_KW_LIST" (global $TOKEN_KW_LIST))
  (export "TOKEN_KW_OPTION" (global $TOKEN_KW_OPTION))
  (export "TOKEN_KW_RESULT" (global $TOKEN_KW_RESULT))
  (export "TOKEN_KW_TUPLE" (global $TOKEN_KW_TUPLE))
  (export "TOKEN_KW_RECORD" (global $TOKEN_KW_RECORD))
  (export "TOKEN_KW_VARIANT" (global $TOKEN_KW_VARIANT))
  (export "TOKEN_KW_ENUM" (global $TOKEN_KW_ENUM))
  (export "TOKEN_KW_FLAGS" (global $TOKEN_KW_FLAGS))
  (export "TOKEN_KW_TYPE" (global $TOKEN_KW_TYPE))
  (export "TOKEN_KW_RESOURCE" (global $TOKEN_KW_RESOURCE))

  ;; Pattern matching tokens
  (export "TOKEN_KW_SOME" (global $TOKEN_KW_SOME))
  (export "TOKEN_KW_NONE" (global $TOKEN_KW_NONE))
  (export "TOKEN_KW_OK" (global $TOKEN_KW_OK))
  (export "TOKEN_KW_ERROR" (global $TOKEN_KW_ERROR))

  ;; Boolean literal tokens
  (export "TOKEN_KW_TRUE" (global $TOKEN_KW_TRUE))
  (export "TOKEN_KW_FALSE" (global $TOKEN_KW_FALSE))

  ;; Component system tokens
  (export "TOKEN_KW_COMPONENT" (global $TOKEN_KW_COMPONENT))
  (export "TOKEN_KW_INTERFACE" (global $TOKEN_KW_INTERFACE))
  (export "TOKEN_KW_WORLD" (global $TOKEN_KW_WORLD))
  (export "TOKEN_KW_IMPORT" (global $TOKEN_KW_IMPORT))
  (export "TOKEN_KW_EXPORT" (global $TOKEN_KW_EXPORT))
  (export "TOKEN_KW_USE" (global $TOKEN_KW_USE))
  (export "TOKEN_KW_INCLUDE" (global $TOKEN_KW_INCLUDE))

  ;; Operator tokens
  (export "TOKEN_PLUS" (global $TOKEN_PLUS))
  (export "TOKEN_MINUS" (global $TOKEN_MINUS))
  (export "TOKEN_MULTIPLY" (global $TOKEN_MULTIPLY))
  (export "TOKEN_DIVIDE" (global $TOKEN_DIVIDE))
  (export "TOKEN_MODULO" (global $TOKEN_MODULO))

  ;; Literal tokens
  (export "TOKEN_NUMBER_LITERAL" (global $TOKEN_NUMBER_LITERAL))
  (export "TOKEN_STRING_LITERAL" (global $TOKEN_STRING_LITERAL))

  ;; Punctuation tokens
  (export "TOKEN_COMMA" (global $TOKEN_COMMA))

  ;; Parenthesis tokens
  (export "TOKEN_LPAREN" (global $TOKEN_LPAREN))
  (export "TOKEN_RPAREN" (global $TOKEN_RPAREN))
)
