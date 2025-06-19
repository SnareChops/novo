;; Meta Functions for Numeric Types
;; Implements numeric-specific meta functions like size(), type conversions, etc.

(module $meta_functions_numeric
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import meta function core
  (import "meta_functions_core" "META_FUNC_SIZE" (global $META_FUNC_SIZE i32))
  (import "meta_functions_core" "META_FUNC_CONVERT" (global $META_FUNC_CONVERT i32))

  ;; Import type constants
  (import "typechecker_main" "TYPE_I32" (global $TYPE_I32 i32))
  (import "typechecker_main" "TYPE_I64" (global $TYPE_I64 i32))
  (import "typechecker_main" "TYPE_F32" (global $TYPE_F32 i32))
  (import "typechecker_main" "TYPE_F64" (global $TYPE_F64 i32))
  (import "typechecker_main" "TYPE_U8" (global $TYPE_U8 i32))
  (import "typechecker_main" "TYPE_U16" (global $TYPE_U16 i32))
  (import "typechecker_main" "TYPE_U32" (global $TYPE_U32 i32))
  (import "typechecker_main" "TYPE_U64" (global $TYPE_U64 i32))
  (import "typechecker_main" "TYPE_S8" (global $TYPE_S8 i32))
  (import "typechecker_main" "TYPE_S16" (global $TYPE_S16 i32))
  (import "typechecker_main" "TYPE_S32" (global $TYPE_S32 i32))
  (import "typechecker_main" "TYPE_S64" (global $TYPE_S64 i32))

  ;; Get the byte size of a numeric type
  ;; @param type_id: i32 - Type constant
  ;; @returns i32 - Size in bytes
  (func $get_numeric_type_size (export "get_numeric_type_size") (param $type_id i32) (result i32)
    ;; 8-bit types
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U8))
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_S8))
      (then (return (i32.const 1))))

    ;; 16-bit types
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U16))
      (then (return (i32.const 2))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_S16))
      (then (return (i32.const 2))))

    ;; 32-bit types
    (if (i32.eq (local.get $type_id) (global.get $TYPE_I32))
      (then (return (i32.const 4))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U32))
      (then (return (i32.const 4))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_S32))
      (then (return (i32.const 4))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_F32))
      (then (return (i32.const 4))))

    ;; 64-bit types
    (if (i32.eq (local.get $type_id) (global.get $TYPE_I64))
      (then (return (i32.const 8))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U64))
      (then (return (i32.const 8))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_S64))
      (then (return (i32.const 8))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_F64))
      (then (return (i32.const 8))))

    ;; Unknown type - return 0
    (i32.const 0)
  )

  ;; Get the type name as a string for numeric types
  ;; @param type_id: i32 - Type constant
  ;; @param dest_ptr: i32 - Destination pointer for string
  ;; @returns i32 - Length of the string written
  (func $get_numeric_type_name (export "get_numeric_type_name") (param $type_id i32) (param $dest_ptr i32) (result i32)
    ;; i32
    (if (i32.eq (local.get $type_id) (global.get $TYPE_I32))
      (then
        (i32.store8 (local.get $dest_ptr) (i32.const 105))      ;; 'i'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 1)) (i32.const 51))  ;; '3'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 2)) (i32.const 50))  ;; '2'
        (return (i32.const 3))))

    ;; i64
    (if (i32.eq (local.get $type_id) (global.get $TYPE_I64))
      (then
        (i32.store8 (local.get $dest_ptr) (i32.const 105))      ;; 'i'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 1)) (i32.const 54))  ;; '6'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 2)) (i32.const 52))  ;; '4'
        (return (i32.const 3))))

    ;; f32
    (if (i32.eq (local.get $type_id) (global.get $TYPE_F32))
      (then
        (i32.store8 (local.get $dest_ptr) (i32.const 102))      ;; 'f'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 1)) (i32.const 51))  ;; '3'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 2)) (i32.const 50))  ;; '2'
        (return (i32.const 3))))

    ;; f64
    (if (i32.eq (local.get $type_id) (global.get $TYPE_F64))
      (then
        (i32.store8 (local.get $dest_ptr) (i32.const 102))      ;; 'f'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 1)) (i32.const 54))  ;; '6'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 2)) (i32.const 52))  ;; '4'
        (return (i32.const 3))))

    ;; u8
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U8))
      (then
        (i32.store8 (local.get $dest_ptr) (i32.const 117))      ;; 'u'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 1)) (i32.const 56))  ;; '8'
        (return (i32.const 2))))

    ;; u16
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U16))
      (then
        (i32.store8 (local.get $dest_ptr) (i32.const 117))      ;; 'u'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 1)) (i32.const 49))  ;; '1'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 2)) (i32.const 54))  ;; '6'
        (return (i32.const 3))))

    ;; u32
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U32))
      (then
        (i32.store8 (local.get $dest_ptr) (i32.const 117))      ;; 'u'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 1)) (i32.const 51))  ;; '3'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 2)) (i32.const 50))  ;; '2'
        (return (i32.const 3))))

    ;; u64
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U64))
      (then
        (i32.store8 (local.get $dest_ptr) (i32.const 117))      ;; 'u'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 1)) (i32.const 54))  ;; '6'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 2)) (i32.const 52))  ;; '4'
        (return (i32.const 3))))

    ;; s8
    (if (i32.eq (local.get $type_id) (global.get $TYPE_S8))
      (then
        (i32.store8 (local.get $dest_ptr) (i32.const 115))      ;; 's'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 1)) (i32.const 56))  ;; '8'
        (return (i32.const 2))))

    ;; s16
    (if (i32.eq (local.get $type_id) (global.get $TYPE_S16))
      (then
        (i32.store8 (local.get $dest_ptr) (i32.const 115))      ;; 's'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 1)) (i32.const 49))  ;; '1'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 2)) (i32.const 54))  ;; '6'
        (return (i32.const 3))))

    ;; s32
    (if (i32.eq (local.get $type_id) (global.get $TYPE_S32))
      (then
        (i32.store8 (local.get $dest_ptr) (i32.const 115))      ;; 's'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 1)) (i32.const 51))  ;; '3'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 2)) (i32.const 50))  ;; '2'
        (return (i32.const 3))))

    ;; s64
    (if (i32.eq (local.get $type_id) (global.get $TYPE_S64))
      (then
        (i32.store8 (local.get $dest_ptr) (i32.const 115))      ;; 's'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 1)) (i32.const 54))  ;; '6'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 2)) (i32.const 52))  ;; '4'
        (return (i32.const 3))))

    ;; Unknown type
    (i32.const 0)
  )

  ;; Convert a value to string representation
  ;; @param value: i64 - Value to convert (supports both i32 and i64 inputs)
  ;; @param type_id: i32 - Type of the value
  ;; @param dest_ptr: i32 - Destination pointer for string
  ;; @returns i32 - Length of the string written
  (func $numeric_value_to_string (export "numeric_value_to_string") (param $value i64) (param $type_id i32) (param $dest_ptr i32) (result i32)
    (local $temp_i32 i32)
    (local $temp_f32 f32)
    (local $temp_f64 f64)

    ;; For integer types, convert the value to string
    ;; This is a simplified implementation - in a real compiler,
    ;; you'd want more sophisticated number-to-string conversion

    ;; Handle i32 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_I32))
      (then
        (local.set $temp_i32 (i32.wrap_i64 (local.get $value)))
        (return (call $i32_to_string (local.get $temp_i32) (local.get $dest_ptr)))))

    ;; Handle i64 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_I64))
      (then
        (return (call $i64_to_string (local.get $value) (local.get $dest_ptr)))))

    ;; Handle f32 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_F32))
      (then
        (local.set $temp_f32 (f32.demote_f64 (f64.reinterpret_i64 (local.get $value))))
        (return (call $f32_to_string (local.get $temp_f32) (local.get $dest_ptr)))))

    ;; Handle f64 type
    (if (i32.eq (local.get $type_id) (global.get $TYPE_F64))
      (then
        (local.set $temp_f64 (f64.reinterpret_i64 (local.get $value)))
        (return (call $f64_to_string (local.get $temp_f64) (local.get $dest_ptr)))))

    ;; For other numeric types, convert to i32 representation
    (local.set $temp_i32 (i32.wrap_i64 (local.get $value)))
    (call $i32_to_string (local.get $temp_i32) (local.get $dest_ptr))
  )

  ;; Helper function to convert i32 to string
  ;; @param value: i32 - Value to convert
  ;; @param dest_ptr: i32 - Destination pointer
  ;; @returns i32 - Length of string
  (func $i32_to_string (param $value i32) (param $dest_ptr i32) (result i32)
    (local $temp i32)
    (local $len i32)
    (local $is_negative i32)

    ;; Handle negative numbers
    (if (i32.lt_s (local.get $value) (i32.const 0))
      (then
        (local.set $is_negative (i32.const 1))
        (local.set $value (i32.sub (i32.const 0) (local.get $value)))
        (i32.store8 (local.get $dest_ptr) (i32.const 45))  ;; '-'
        (local.set $dest_ptr (i32.add (local.get $dest_ptr) (i32.const 1)))
        (local.set $len (i32.const 1))))

    ;; Handle zero case
    (if (i32.eqz (local.get $value))
      (then
        (i32.store8 (local.get $dest_ptr) (i32.const 48))  ;; '0'
        (return (i32.add (local.get $len) (i32.const 1)))))

    ;; Convert digits (simplified - just handles single digits for now)
    (if (i32.lt_u (local.get $value) (i32.const 10))
      (then
        (i32.store8 (local.get $dest_ptr) (i32.add (local.get $value) (i32.const 48)))
        (return (i32.add (local.get $len) (i32.const 1)))))

    ;; For larger numbers, just return a placeholder for now
    ;; In a full implementation, you'd implement proper decimal conversion
    (i32.store8 (local.get $dest_ptr) (i32.const 88))     ;; 'X'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 1)) (i32.const 88))  ;; 'X'
    (i32.add (local.get $len) (i32.const 2))
  )

  ;; Helper function to convert i64 to string (simplified)
  ;; @param value: i64 - Value to convert
  ;; @param dest_ptr: i32 - Destination pointer
  ;; @returns i32 - Length of string
  (func $i64_to_string (param $value i64) (param $dest_ptr i32) (result i32)
    ;; Simplified implementation - convert to i32 and handle
    (call $i32_to_string (i32.wrap_i64 (local.get $value)) (local.get $dest_ptr))
  )

  ;; Helper function to convert f32 to string (simplified)
  ;; @param value: f32 - Value to convert
  ;; @param dest_ptr: i32 - Destination pointer
  ;; @returns i32 - Length of string
  (func $f32_to_string (param $value f32) (param $dest_ptr i32) (result i32)
    ;; Very simplified - just convert to int part for now
    (call $i32_to_string (i32.trunc_f32_s (local.get $value)) (local.get $dest_ptr))
  )

  ;; Helper function to convert f64 to string (simplified)
  ;; @param value: f64 - Value to convert
  ;; @param dest_ptr: i32 - Destination pointer
  ;; @returns i32 - Length of string
  (func $f64_to_string (param $value f64) (param $dest_ptr i32) (result i32)
    ;; Very simplified - just convert to int part for now
    (call $i32_to_string (i32.trunc_f64_s (local.get $value)) (local.get $dest_ptr))
  )

  ;; Check if a numeric conversion is valid
  ;; @param from_type: i32 - Source type
  ;; @param to_type: i32 - Target type
  ;; @returns i32 - 1 if valid, 0 if not
  (func $is_numeric_conversion_valid (export "is_numeric_conversion_valid") (param $from_type i32) (param $to_type i32) (result i32)
    ;; For now, allow all numeric-to-numeric conversions
    ;; In a real implementation, you might want to check for potential data loss

    ;; Check if both types are numeric
    (if (i32.and (call $is_numeric_type (local.get $from_type)) (call $is_numeric_type (local.get $to_type)))
      (then (return (i32.const 1))))

    (i32.const 0)
  )

  ;; Helper to check if a type is numeric
  (func $is_numeric_type (param $type_id i32) (result i32)
    (if (i32.eq (local.get $type_id) (global.get $TYPE_I32))
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_I64))
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_F32))
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_F64))
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U8))
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U16))
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U32))
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_U64))
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_S8))
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_S16))
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_S32))
      (then (return (i32.const 1))))
    (if (i32.eq (local.get $type_id) (global.get $TYPE_S64))
      (then (return (i32.const 1))))
    (i32.const 0)
  )
)
