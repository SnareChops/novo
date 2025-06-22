;; WebAssembly Binary Instruction Encoding
;; Implements binary encoding for WebAssembly instructions

(module $instruction_encoder
  ;; Import memory for binary data storage
  (import "lexer_memory" "memory" (memory 1))

  ;; Import LEB128 encoding utilities
  (import "leb128_encoder" "encode_uleb128_u32" (func $encode_uleb128_u32 (param i32 i32) (result i32)))
  (import "leb128_encoder" "encode_sleb128_i32" (func $encode_sleb128_i32 (param i32 i32) (result i32)))

  ;; WebAssembly instruction opcodes (core instructions)
  (global $OPCODE_UNREACHABLE i32 (i32.const 0x00))
  (global $OPCODE_NOP i32 (i32.const 0x01))
  (global $OPCODE_BLOCK i32 (i32.const 0x02))
  (global $OPCODE_LOOP i32 (i32.const 0x03))
  (global $OPCODE_IF i32 (i32.const 0x04))
  (global $OPCODE_ELSE i32 (i32.const 0x05))
  (global $OPCODE_END i32 (i32.const 0x0B))
  (global $OPCODE_BR i32 (i32.const 0x0C))
  (global $OPCODE_BR_IF i32 (i32.const 0x0D))
  (global $OPCODE_RETURN i32 (i32.const 0x0F))
  (global $OPCODE_CALL i32 (i32.const 0x10))

  ;; Local variable instructions
  (global $OPCODE_LOCAL_GET i32 (i32.const 0x20))
  (global $OPCODE_LOCAL_SET i32 (i32.const 0x21))
  (global $OPCODE_LOCAL_TEE i32 (i32.const 0x22))

  ;; Global variable instructions
  (global $OPCODE_GLOBAL_GET i32 (i32.const 0x23))
  (global $OPCODE_GLOBAL_SET i32 (i32.const 0x24))

  ;; Memory instructions
  (global $OPCODE_I32_LOAD i32 (i32.const 0x28))
  (global $OPCODE_I32_STORE i32 (i32.const 0x36))

  ;; i32 constant and arithmetic
  (global $OPCODE_I32_CONST i32 (i32.const 0x41))
  (global $OPCODE_I32_EQZ i32 (i32.const 0x45))
  (global $OPCODE_I32_EQ i32 (i32.const 0x46))
  (global $OPCODE_I32_NE i32 (i32.const 0x47))
  (global $OPCODE_I32_ADD i32 (i32.const 0x6A))
  (global $OPCODE_I32_SUB i32 (i32.const 0x6B))
  (global $OPCODE_I32_MUL i32 (i32.const 0x6C))
  (global $OPCODE_I32_DIV_S i32 (i32.const 0x6D))
  (global $OPCODE_I32_DIV_U i32 (i32.const 0x6E))

  ;; f32 instructions
  (global $OPCODE_F32_CONST i32 (i32.const 0x43))
  (global $OPCODE_F32_ADD i32 (i32.const 0x92))
  (global $OPCODE_F32_SUB i32 (i32.const 0x93))
  (global $OPCODE_F32_MUL i32 (i32.const 0x94))
  (global $OPCODE_F32_DIV i32 (i32.const 0x95))

  ;; Instruction encoding workspace
  (global $INSTRUCTION_BUFFER_START i32 (i32.const 13312))  ;; 13KB offset
  (global $INSTRUCTION_BUFFER_SIZE i32 (i32.const 4096))
  (global $instruction_pos (mut i32) (i32.const 0))

  ;; Initialize instruction encoder
  (func $init_instruction_encoder (export "init_instruction_encoder")
    (global.set $instruction_pos (i32.const 0))
  )

  ;; Write a single opcode byte
  ;; @param output_ptr: i32 - Pointer to output buffer
  ;; @param opcode: i32 - Instruction opcode
  ;; @returns i32 - Number of bytes written (always 1)
  (func $write_opcode (export "write_opcode") (param $output_ptr i32) (param $opcode i32) (result i32)
    (i32.store8 (local.get $output_ptr) (local.get $opcode))
    (i32.const 1)
  )

  ;; Encode i32.const instruction
  ;; @param value: i32 - Constant value
  ;; @param output_ptr: i32 - Pointer to output buffer
  ;; @returns i32 - Number of bytes written
  (func $encode_i32_const (export "encode_i32_const") (param $value i32) (param $output_ptr i32) (result i32)
    (local $bytes_written i32)

    ;; Write opcode
    (local.set $bytes_written (call $write_opcode (local.get $output_ptr) (global.get $OPCODE_I32_CONST)))

    ;; Write value as SLEB128
    (local.set $bytes_written
      (i32.add (local.get $bytes_written)
        (call $encode_sleb128_i32 (local.get $value)
          (i32.add (local.get $output_ptr) (local.get $bytes_written)))))

    (local.get $bytes_written)
  )

  ;; Encode f32.const instruction
  ;; @param value: f32 - Constant value (as i32 bits)
  ;; @param output_ptr: i32 - Pointer to output buffer
  ;; @returns i32 - Number of bytes written
  (func $encode_f32_const (export "encode_f32_const") (param $value i32) (param $output_ptr i32) (result i32)
    (local $bytes_written i32)

    ;; Write opcode
    (local.set $bytes_written (call $write_opcode (local.get $output_ptr) (global.get $OPCODE_F32_CONST)))

    ;; Write 4 bytes of f32 value in little-endian format
    (i32.store8 offset=1 (local.get $output_ptr) (i32.and (local.get $value) (i32.const 0xFF)))
    (i32.store8 offset=2 (local.get $output_ptr) (i32.and (i32.shr_u (local.get $value) (i32.const 8)) (i32.const 0xFF)))
    (i32.store8 offset=3 (local.get $output_ptr) (i32.and (i32.shr_u (local.get $value) (i32.const 16)) (i32.const 0xFF)))
    (i32.store8 offset=4 (local.get $output_ptr) (i32.and (i32.shr_u (local.get $value) (i32.const 24)) (i32.const 0xFF)))

    (i32.const 5)  ;; opcode + 4 bytes
  )

  ;; Encode local.get instruction
  ;; @param local_index: i32 - Local variable index
  ;; @param output_ptr: i32 - Pointer to output buffer
  ;; @returns i32 - Number of bytes written
  (func $encode_local_get (export "encode_local_get") (param $local_index i32) (param $output_ptr i32) (result i32)
    (local $bytes_written i32)

    ;; Write opcode
    (local.set $bytes_written (call $write_opcode (local.get $output_ptr) (global.get $OPCODE_LOCAL_GET)))

    ;; Write local index as ULEB128
    (local.set $bytes_written
      (i32.add (local.get $bytes_written)
        (call $encode_uleb128_u32 (local.get $local_index)
          (i32.add (local.get $output_ptr) (local.get $bytes_written)))))

    (local.get $bytes_written)
  )

  ;; Encode local.set instruction
  ;; @param local_index: i32 - Local variable index
  ;; @param output_ptr: i32 - Pointer to output buffer
  ;; @returns i32 - Number of bytes written
  (func $encode_local_set (export "encode_local_set") (param $local_index i32) (param $output_ptr i32) (result i32)
    (local $bytes_written i32)

    ;; Write opcode
    (local.set $bytes_written (call $write_opcode (local.get $output_ptr) (global.get $OPCODE_LOCAL_SET)))

    ;; Write local index as ULEB128
    (local.set $bytes_written
      (i32.add (local.get $bytes_written)
        (call $encode_uleb128_u32 (local.get $local_index)
          (i32.add (local.get $output_ptr) (local.get $bytes_written)))))

    (local.get $bytes_written)
  )

  ;; Encode binary arithmetic instruction
  ;; @param op_type: i32 - Operation type (0=add, 1=sub, 2=mul, 3=div)
  ;; @param value_type: i32 - Value type (0=i32, 1=f32)
  ;; @param output_ptr: i32 - Pointer to output buffer
  ;; @returns i32 - Number of bytes written
  (func $encode_binary_op (export "encode_binary_op") (param $op_type i32) (param $value_type i32) (param $output_ptr i32) (result i32)
    (local $opcode i32)

    ;; Determine opcode based on operation and type
    (if (i32.eq (local.get $value_type) (i32.const 0))  ;; i32
      (then
        (if (i32.eq (local.get $op_type) (i32.const 0))
          (then (local.set $opcode (global.get $OPCODE_I32_ADD)))
          (else (if (i32.eq (local.get $op_type) (i32.const 1))
            (then (local.set $opcode (global.get $OPCODE_I32_SUB)))
            (else (if (i32.eq (local.get $op_type) (i32.const 2))
              (then (local.set $opcode (global.get $OPCODE_I32_MUL)))
              (else (local.set $opcode (global.get $OPCODE_I32_DIV_S))) ;; default to signed div
            ))
          ))
        )
      )
      (else  ;; f32
        (if (i32.eq (local.get $op_type) (i32.const 0))
          (then (local.set $opcode (global.get $OPCODE_F32_ADD)))
          (else (if (i32.eq (local.get $op_type) (i32.const 1))
            (then (local.set $opcode (global.get $OPCODE_F32_SUB)))
            (else (if (i32.eq (local.get $op_type) (i32.const 2))
              (then (local.set $opcode (global.get $OPCODE_F32_MUL)))
              (else (local.set $opcode (global.get $OPCODE_F32_DIV)))
            ))
          ))
        )
      )
    )

    (call $write_opcode (local.get $output_ptr) (local.get $opcode))
  )

  ;; Encode call instruction
  ;; @param func_index: i32 - Function index to call
  ;; @param output_ptr: i32 - Pointer to output buffer
  ;; @returns i32 - Number of bytes written
  (func $encode_call (export "encode_call") (param $func_index i32) (param $output_ptr i32) (result i32)
    (local $bytes_written i32)

    ;; Write opcode
    (local.set $bytes_written (call $write_opcode (local.get $output_ptr) (global.get $OPCODE_CALL)))

    ;; Write function index as ULEB128
    (local.set $bytes_written
      (i32.add (local.get $bytes_written)
        (call $encode_uleb128_u32 (local.get $func_index)
          (i32.add (local.get $output_ptr) (local.get $bytes_written)))))

    (local.get $bytes_written)
  )

  ;; Encode control flow instructions
  ;; @param control_type: i32 - Control type (0=block, 1=loop, 2=if, 3=else, 4=end, 5=br, 6=br_if, 7=return)
  ;; @param label_or_depth: i32 - Label depth for br/br_if, unused for others
  ;; @param output_ptr: i32 - Pointer to output buffer
  ;; @returns i32 - Number of bytes written
  (func $encode_control_flow (export "encode_control_flow") (param $control_type i32) (param $label_or_depth i32) (param $output_ptr i32) (result i32)
    (local $bytes_written i32)
    (local $opcode i32)

    ;; Determine opcode
    (if (i32.eq (local.get $control_type) (i32.const 0))  ;; block
      (then (local.set $opcode (global.get $OPCODE_BLOCK)))
      (else (if (i32.eq (local.get $control_type) (i32.const 1))  ;; loop
        (then (local.set $opcode (global.get $OPCODE_LOOP)))
        (else (if (i32.eq (local.get $control_type) (i32.const 2))  ;; if
          (then (local.set $opcode (global.get $OPCODE_IF)))
          (else (if (i32.eq (local.get $control_type) (i32.const 3))  ;; else
            (then (local.set $opcode (global.get $OPCODE_ELSE)))
            (else (if (i32.eq (local.get $control_type) (i32.const 4))  ;; end
              (then (local.set $opcode (global.get $OPCODE_END)))
              (else (if (i32.eq (local.get $control_type) (i32.const 5))  ;; br
                (then (local.set $opcode (global.get $OPCODE_BR)))
                (else (if (i32.eq (local.get $control_type) (i32.const 6))  ;; br_if
                  (then (local.set $opcode (global.get $OPCODE_BR_IF)))
                  (else (local.set $opcode (global.get $OPCODE_RETURN)))  ;; return
                ))
              ))
            ))
          ))
        ))
      ))
    )

    ;; Write opcode
    (local.set $bytes_written (call $write_opcode (local.get $output_ptr) (local.get $opcode)))

    ;; For block, loop, if: write block type (0x40 for empty)
    (if (i32.le_u (local.get $control_type) (i32.const 2))
      (then
        (i32.store8 (i32.add (local.get $output_ptr) (local.get $bytes_written)) (i32.const 0x40))
        (local.set $bytes_written (i32.add (local.get $bytes_written) (i32.const 1)))
      )
    )

    ;; For br, br_if: write label depth
    (if (i32.or (i32.eq (local.get $control_type) (i32.const 5)) (i32.eq (local.get $control_type) (i32.const 6)))
      (then
        (local.set $bytes_written
          (i32.add (local.get $bytes_written)
            (call $encode_uleb128_u32 (local.get $label_or_depth)
              (i32.add (local.get $output_ptr) (local.get $bytes_written)))))
      )
    )

    (local.get $bytes_written)
  )
)
