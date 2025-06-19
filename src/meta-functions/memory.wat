;; Meta Functions for Memory Access Operations
;; Implements memory access meta functions: load(), store(), load_offset(), store_offset()

(module $meta_functions_memory
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import meta function core
  (import "meta_functions_core" "META_FUNC_LOAD" (global $META_FUNC_LOAD i32))
  (import "meta_functions_core" "META_FUNC_STORE" (global $META_FUNC_STORE i32))
  (import "meta_functions_core" "META_FUNC_LOAD_OFFSET" (global $META_FUNC_LOAD_OFFSET i32))
  (import "meta_functions_core" "META_FUNC_STORE_OFFSET" (global $META_FUNC_STORE_OFFSET i32))

  ;; Import type constants
  (import "typechecker_main" "TYPE_I32" (global $TYPE_I32 i32))
  (import "typechecker_main" "TYPE_I64" (global $TYPE_I64 i32))
  (import "typechecker_main" "TYPE_F32" (global $TYPE_F32 i32))
  (import "typechecker_main" "TYPE_F64" (global $TYPE_F64 i32))
  (import "typechecker_main" "TYPE_U8" (global $TYPE_U8 i32))
  (import "typechecker_main" "TYPE_U16" (global $TYPE_U16 i32))
  (import "typechecker_main" "TYPE_U32" (global $TYPE_U32 i32))
  (import "typechecker_main" "TYPE_U64" (global $TYPE_U64 i32))

  ;; Get default alignment for a type (log2 encoding)
  ;; @param type_id: i32 - Type constant
  ;; @returns i32 - Alignment value (log2: 0=1-byte, 1=2-byte, 2=4-byte, 3=8-byte)
  (func $get_default_alignment (export "get_default_alignment") (param $type_id i32) (result i32)
    ;; 1-byte types (align=0)
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U8))
      (then (return (i32.const 0))))

    ;; 2-byte types (align=1)
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U16))
      (then (return (i32.const 1))))

    ;; 4-byte types (align=2)
    (if (i32.eq (local.get $type_id) (global.get $TYPE_I32))
      (then (return (i32.const 2))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U32))
      (then (return (i32.const 2))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_F32))
      (then (return (i32.const 2))))

    ;; 8-byte types (align=3)
    (if (i32.eq (local.get $type_id) (global.get $TYPE_I64))
      (then (return (i32.const 3))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U64))
      (then (return (i32.const 3))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_F64))
      (then (return (i32.const 3))))

    ;; Default to 4-byte alignment
    (i32.const 2)
  )

  ;; Load value from memory with specified type
  ;; @param addr: i32 - Memory address
  ;; @param type_id: i32 - Type to load
  ;; @returns i64 - Loaded value (all types fit in i64)
  (func $load_memory_value (export "load_memory_value") (param $addr i32) (param $type_id i32) (result i64)
    ;; i32 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_I32))
      (then (return (i64.extend_i32_s (i32.load (local.get $addr))))))

    ;; i64 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_I64))
      (then (return (i64.load (local.get $addr)))))

    ;; f32 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_F32))
      (then (return (i64.reinterpret_f64 (f64.promote_f32 (f32.load (local.get $addr)))))))

    ;; f64 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_F64))
      (then (return (i64.reinterpret_f64 (f64.load (local.get $addr))))))

    ;; u8 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U8))
      (then (return (i64.extend_i32_u (i32.load8_u (local.get $addr))))))

    ;; u16 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U16))
      (then (return (i64.extend_i32_u (i32.load16_u (local.get $addr))))))

    ;; u32 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U32))
      (then (return (i64.extend_i32_u (i32.load (local.get $addr))))))

    ;; u64 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U64))
      (then (return (i64.load (local.get $addr)))))

    ;; Default to i32 load
    (i64.extend_i32_s (i32.load (local.get $addr)))
  )

  ;; Load value from memory with offset and alignment
  ;; @param addr: i32 - Base memory address
  ;; @param offset: i32 - Offset from base address
  ;; @param align: i32 - Alignment (log2 encoding)
  ;; @param type_id: i32 - Type to load
  ;; @returns i64 - Loaded value
  (func $load_memory_value_offset (export "load_memory_value_offset") (param $addr i32) (param $offset i32) (param $align i32) (param $type_id i32) (result i64)
    (local $effective_addr i32)

    ;; Calculate effective address
    (local.set $effective_addr (i32.add (local.get $addr) (local.get $offset)))

    ;; Load based on type with alignment
    ;; i32 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_I32))
      (then (return (i64.extend_i32_s (i32.load align=4 (local.get $effective_addr))))))

    ;; i64 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_I64))
      (then (return (i64.load align=8 (local.get $effective_addr)))))

    ;; f32 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_F32))
      (then (return (i64.reinterpret_f64 (f64.promote_f32 (f32.load align=4 (local.get $effective_addr)))))))

    ;; f64 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_F64))
      (then (return (i64.reinterpret_f64 (f64.load align=8 (local.get $effective_addr))))))

    ;; u8 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U8))
      (then (return (i64.extend_i32_u (i32.load8_u (local.get $effective_addr))))))

    ;; u16 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U16))
      (then (return (i64.extend_i32_u (i32.load16_u align=2 (local.get $effective_addr))))))

    ;; u32 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U32))
      (then (return (i64.extend_i32_u (i32.load align=4 (local.get $effective_addr))))))

    ;; u64 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U64))
      (then (return (i64.load align=8 (local.get $effective_addr)))))

    ;; Default to i32 load
    (i64.extend_i32_s (i32.load (local.get $effective_addr)))
  )

  ;; Store value to memory with specified type
  ;; @param addr: i32 - Memory address
  ;; @param value: i64 - Value to store (all types fit in i64)
  ;; @param type_id: i32 - Type to store
  (func $store_memory_value (export "store_memory_value") (param $addr i32) (param $value i64) (param $type_id i32)
    ;; i32 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_I32))
      (then
        (i32.store (local.get $addr) (i32.wrap_i64 (local.get $value)))
        (return)))

    ;; i64 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_I64))
      (then
        (i64.store (local.get $addr) (local.get $value))
        (return)))

    ;; f32 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_F32))
      (then
        (f32.store (local.get $addr) (f32.demote_f64 (f64.reinterpret_i64 (local.get $value))))
        (return)))

    ;; f64 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_F64))
      (then
        (f64.store (local.get $addr) (f64.reinterpret_i64 (local.get $value)))
        (return)))

    ;; u8 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U8))
      (then
        (i32.store8 (local.get $addr) (i32.wrap_i64 (local.get $value)))
        (return)))

    ;; u16 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U16))
      (then
        (i32.store16 (local.get $addr) (i32.wrap_i64 (local.get $value)))
        (return)))

    ;; u32 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U32))
      (then
        (i32.store (local.get $addr) (i32.wrap_i64 (local.get $value)))
        (return)))

    ;; u64 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U64))
      (then
        (i64.store (local.get $addr) (local.get $value))
        (return)))

    ;; Default to i32 store
    (i32.store (local.get $addr) (i32.wrap_i64 (local.get $value)))
  )

  ;; Store value to memory with offset and alignment
  ;; @param addr: i32 - Base memory address
  ;; @param value: i64 - Value to store
  ;; @param offset: i32 - Offset from base address
  ;; @param align: i32 - Alignment (log2 encoding)
  ;; @param type_id: i32 - Type to store
  (func $store_memory_value_offset (export "store_memory_value_offset") (param $addr i32) (param $value i64) (param $offset i32) (param $align i32) (param $type_id i32)
    (local $effective_addr i32)

    ;; Calculate effective address
    (local.set $effective_addr (i32.add (local.get $addr) (local.get $offset)))

    ;; Store based on type with alignment
    ;; i32 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_I32))
      (then
        (i32.store align=4 (local.get $effective_addr) (i32.wrap_i64 (local.get $value)))
        (return)))

    ;; i64 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_I64))
      (then
        (i64.store align=8 (local.get $effective_addr) (local.get $value))
        (return)))

    ;; f32 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_F32))
      (then
        (f32.store align=4 (local.get $effective_addr) (f32.demote_f64 (f64.reinterpret_i64 (local.get $value))))
        (return)))

    ;; f64 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_F64))
      (then
        (f64.store align=8 (local.get $effective_addr) (f64.reinterpret_i64 (local.get $value)))
        (return)))

    ;; u8 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U8))
      (then
        (i32.store8 (local.get $effective_addr) (i32.wrap_i64 (local.get $value)))
        (return)))

    ;; u16 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U16))
      (then
        (i32.store16 align=2 (local.get $effective_addr) (i32.wrap_i64 (local.get $value)))
        (return)))

    ;; u32 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U32))
      (then
        (i32.store align=4 (local.get $effective_addr) (i32.wrap_i64 (local.get $value)))
        (return)))

    ;; u64 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U64))
      (then
        (i64.store align=8 (local.get $effective_addr) (local.get $value))
        (return)))

    ;; Default to i32 store
    (i32.store (local.get $effective_addr) (i32.wrap_i64 (local.get $value)))
  )

  ;; Validate memory address and alignment
  ;; @param addr: i32 - Memory address
  ;; @param align: i32 - Alignment requirement (log2)
  ;; @returns i32 - 1 if valid, 0 if invalid
  (func $validate_memory_access (export "validate_memory_access") (param $addr i32) (param $align i32) (result i32)
    (local $align_mask i32)

    ;; Calculate alignment mask (2^align - 1)
    (local.set $align_mask (i32.sub (i32.shl (i32.const 1) (local.get $align)) (i32.const 1)))

    ;; Check if address is properly aligned
    (if (i32.eqz (i32.and (local.get $addr) (local.get $align_mask)))
      (then (return (i32.const 1))))

    ;; Invalid alignment
    (i32.const 0)
  )

  ;; Check if memory access is within bounds
  ;; @param addr: i32 - Memory address
  ;; @param size: i32 - Size of access in bytes
  ;; @returns i32 - 1 if within bounds, 0 if out of bounds
  (func $check_memory_bounds (export "check_memory_bounds") (param $addr i32) (param $size i32) (result i32)
    (local $end_addr i32)
    (local $memory_size i32)

    ;; Calculate end address
    (local.set $end_addr (i32.add (local.get $addr) (local.get $size)))

    ;; Get current memory size in bytes
    (local.set $memory_size (i32.mul (memory.size) (i32.const 65536)))

    ;; Check if access is within bounds
    (if (i32.le_u (local.get $end_addr) (local.get $memory_size))
      (then (return (i32.const 1))))

    ;; Out of bounds
    (i32.const 0)
  )
)
