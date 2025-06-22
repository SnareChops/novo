;; LEB128 Variable-Length Integer Encoding
;; Implements LEB128 encoding for WebAssembly binary format

(module $leb128_encoder
  ;; Import memory for binary data storage
  (import "lexer_memory" "memory" (memory 1))

  ;; LEB128 encoding workspace
  (global $LEB128_WORKSPACE_START i32 (i32.const 12288))  ;; 12KB offset
  (global $LEB128_WORKSPACE_SIZE i32 (i32.const 1024))
  (global $leb128_pos (mut i32) (i32.const 0))

  ;; Encode unsigned 32-bit integer as LEB128
  ;; @param value: i32 - Value to encode
  ;; @param output_ptr: i32 - Pointer to output buffer
  ;; @returns i32 - Number of bytes written
  (func $encode_uleb128_u32 (export "encode_uleb128_u32") (param $value i32) (param $output_ptr i32) (result i32)
    (local $bytes_written i32)
    (local $current_byte i32)
    (local $remaining i32)

    (local.set $bytes_written (i32.const 0))
    (local.set $remaining (local.get $value))

    (loop $encode_loop
      ;; Get the lower 7 bits
      (local.set $current_byte (i32.and (local.get $remaining) (i32.const 0x7F)))

      ;; Shift remaining value by 7 bits
      (local.set $remaining (i32.shr_u (local.get $remaining) (i32.const 7)))

      ;; If there are more bytes, set the continuation bit
      (if (i32.ne (local.get $remaining) (i32.const 0))
        (then
          (local.set $current_byte (i32.or (local.get $current_byte) (i32.const 0x80)))
        )
      )

      ;; Write the byte
      (i32.store8
        (i32.add (local.get $output_ptr) (local.get $bytes_written))
        (local.get $current_byte)
      )

      (local.set $bytes_written (i32.add (local.get $bytes_written) (i32.const 1)))

      ;; Continue if there are more bytes
      (br_if $encode_loop (i32.ne (local.get $remaining) (i32.const 0)))
    )

    (local.get $bytes_written)
  )

  ;; Encode signed 32-bit integer as LEB128
  ;; @param value: i32 - Value to encode (signed)
  ;; @param output_ptr: i32 - Pointer to output buffer
  ;; @returns i32 - Number of bytes written
  (func $encode_sleb128_i32 (export "encode_sleb128_i32") (param $value i32) (param $output_ptr i32) (result i32)
    (local $bytes_written i32)
    (local $current_byte i32)
    (local $remaining i32)
    (local $sign_bit i32)
    (local $more i32)

    (local.set $bytes_written (i32.const 0))
    (local.set $remaining (local.get $value))
    (local.set $more (i32.const 1))

    (loop $encode_loop
      ;; Get the lower 7 bits
      (local.set $current_byte (i32.and (local.get $remaining) (i32.const 0x7F)))

      ;; Arithmetic shift right by 7 bits (preserves sign)
      (local.set $remaining (i32.shr_s (local.get $remaining) (i32.const 7)))

      ;; Check if this is the last byte
      (local.set $sign_bit (i32.and (local.get $current_byte) (i32.const 0x40)))

      (if (i32.or
            (i32.and (i32.eq (local.get $remaining) (i32.const 0))
                     (i32.eqz (local.get $sign_bit)))
            (i32.and (i32.eq (local.get $remaining) (i32.const -1))
                     (i32.ne (local.get $sign_bit) (i32.const 0))))
        (then (local.set $more (i32.const 0)))
        (else (local.set $current_byte (i32.or (local.get $current_byte) (i32.const 0x80))))
      )

      ;; Write the byte
      (i32.store8
        (i32.add (local.get $output_ptr) (local.get $bytes_written))
        (local.get $current_byte)
      )

      (local.set $bytes_written (i32.add (local.get $bytes_written) (i32.const 1)))

      ;; Continue if there are more bytes
      (br_if $encode_loop (local.get $more))
    )

    (local.get $bytes_written)
  )

  ;; Calculate the size needed for LEB128 encoding of a u32
  ;; @param value: i32 - Value to calculate size for
  ;; @returns i32 - Number of bytes needed
  (func $calculate_uleb128_size (export "calculate_uleb128_size") (param $value i32) (result i32)
    (local $size i32)
    (local $remaining i32)

    (local.set $size (i32.const 0))
    (local.set $remaining (local.get $value))

    (loop $size_loop
      (local.set $size (i32.add (local.get $size) (i32.const 1)))
      (local.set $remaining (i32.shr_u (local.get $remaining) (i32.const 7)))
      (br_if $size_loop (i32.ne (local.get $remaining) (i32.const 0)))
    )

    (local.get $size)
  )

  ;; Write a string with LEB128 length prefix
  ;; @param str_ptr: i32 - Pointer to string data
  ;; @param str_len: i32 - Length of string
  ;; @param output_ptr: i32 - Pointer to output buffer
  ;; @returns i32 - Total bytes written (length prefix + string data)
  (func $write_string_with_length (export "write_string_with_length")
        (param $str_ptr i32) (param $str_len i32) (param $output_ptr i32) (result i32)
    (local $len_bytes i32)
    (local $i i32)

    ;; Write length as LEB128
    (local.set $len_bytes (call $encode_uleb128_u32 (local.get $str_len) (local.get $output_ptr)))

    ;; Copy string data
    (local.set $i (i32.const 0))
    (loop $copy_loop
      (if (i32.lt_u (local.get $i) (local.get $str_len))
        (then
          (i32.store8
            (i32.add (local.get $output_ptr) (i32.add (local.get $len_bytes) (local.get $i)))
            (i32.load8_u (i32.add (local.get $str_ptr) (local.get $i)))
          )
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $copy_loop)
        )
      )
    )

    (i32.add (local.get $len_bytes) (local.get $str_len))
  )
)
