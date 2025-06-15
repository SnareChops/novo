;; Novo Lexer Memory Management
;; Handles memory layout and basic memory management functions

(module $novo_lexer_memory
  ;; Memory Layout:
  ;; 0-1023:      Input text buffer
  ;; 1024-2047:   Filename string
  ;; 2048-32767:  Token array (fixed-size token records, 16 bytes each)
  ;; 32768-65535: Variable-size data (identifier strings)
  (memory (export "memory") 1)  ;; 1 page = 64KB

  ;; Memory section constants
  (global $INPUT_BUFFER_START (export "INPUT_BUFFER_START") i32 (i32.const 0))
  (global $INPUT_BUFFER_SIZE (export "INPUT_BUFFER_SIZE") i32 (i32.const 1024))
  (global $FILENAME_START (export "FILENAME_START") i32 (i32.const 1024))
  (global $FILENAME_SIZE (export "FILENAME_SIZE") i32 (i32.const 1024))
  (global $TOKEN_ARRAY_START (export "TOKEN_ARRAY_START") i32 (i32.const 2048))
  (global $TOKEN_ARRAY_SIZE (export "TOKEN_ARRAY_SIZE") i32 (i32.const 30720))
  (global $VAR_DATA_START (export "VAR_DATA_START") i32 (i32.const 32768))
  (global $VAR_DATA_SIZE (export "VAR_DATA_SIZE") i32 (i32.const 32768))

  ;; Token record offsets
  (global $TOKEN_TYPE_OFFSET (export "TOKEN_TYPE_OFFSET") i32 (i32.const 0))
  (global $TOKEN_START_OFFSET (export "TOKEN_START_OFFSET") i32 (i32.const 4))
  (global $TOKEN_LINE_OFFSET (export "TOKEN_LINE_OFFSET") i32 (i32.const 8))
  (global $TOKEN_COLUMN_OFFSET (export "TOKEN_COLUMN_OFFSET") i32 (i32.const 12))
  (global $TOKEN_RECORD_SIZE (export "TOKEN_RECORD_SIZE") i32 (i32.const 16))

  ;; Lexer state
  (global $current_line (export "current_line") (mut i32) (i32.const 1))
  (global $current_col (export "current_col") (mut i32) (i32.const 0))
  (global $token_count (export "token_count") (mut i32) (i32.const 0))

  ;; Update position based on current character
  (func $update_position (export "update_position") (param $c i32)
    ;; Handle newlines - increment line number and reset column
    (if (i32.eq (local.get $c) (i32.const 10))  ;; '\n'
      (then
        (global.set $current_line (i32.add (global.get $current_line) (i32.const 1)))
        (global.set $current_col (i32.const 0)))
      (else
        ;; Otherwise just increment column
        (global.set $current_col (i32.add (global.get $current_col) (i32.const 1)))))
  )

  ;; Store an identifier string in variable data section and return start offset
  (func $store_identifier (export "store_identifier") (param $start i32) (param $len i32) (result i32)
    (local $data_pos i32)
    (local $i i32)

    ;; Get next available position in var data section
    (local.set $data_pos (global.get $VAR_DATA_START))

    ;; Copy identifier string characters
    (local.set $i (i32.const 0))
    (loop $copy_loop
      (br_if $copy_loop
        (i32.lt_s (local.get $i) (local.get $len))
      )
      (i32.store8
        (i32.add (local.get $data_pos) (local.get $i))
        (i32.load8_u (i32.add (local.get $start) (local.get $i)))
      )
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
    )

    ;; Store null terminator
    (i32.store8
      (i32.add (local.get $data_pos) (local.get $len))
      (i32.const 0)
    )

    ;; Return start position of stored identifier
    (local.get $data_pos)
  )
)
