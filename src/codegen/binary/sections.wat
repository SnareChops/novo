;; WebAssembly Binary Section Generation
;; Implements WASM binary format sections (type, import, function, memory, export, code)

(module $section_generator
  ;; Import memory for binary data storage
  (import "lexer_memory" "memory" (memory 1))

  ;; Import LEB128 encoding utilities
  (import "leb128_encoder" "encode_uleb128_u32" (func $encode_uleb128_u32 (param i32 i32) (result i32)))
  (import "leb128_encoder" "write_string_with_length" (func $write_string_with_length (param i32 i32 i32) (result i32)))
  (import "leb128_encoder" "calculate_uleb128_size" (func $calculate_uleb128_size (param i32) (result i32)))

  ;; WebAssembly section IDs
  (global $SECTION_TYPE i32 (i32.const 1))
  (global $SECTION_IMPORT i32 (i32.const 2))
  (global $SECTION_FUNCTION i32 (i32.const 3))
  (global $SECTION_MEMORY i32 (i32.const 5))
  (global $SECTION_GLOBAL i32 (i32.const 6))
  (global $SECTION_EXPORT i32 (i32.const 7))
  (global $SECTION_CODE i32 (i32.const 10))

  ;; Value types
  (global $TYPE_I32 i32 (i32.const 0x7F))
  (global $TYPE_I64 i32 (i32.const 0x7E))
  (global $TYPE_F32 i32 (i32.const 0x7D))
  (global $TYPE_F64 i32 (i32.const 0x7C))

  ;; External kinds
  (global $EXTERNAL_FUNC i32 (i32.const 0x00))
  (global $EXTERNAL_TABLE i32 (i32.const 0x01))
  (global $EXTERNAL_MEMORY i32 (i32.const 0x02))
  (global $EXTERNAL_GLOBAL i32 (i32.const 0x03))

  ;; Section generation workspace
  (global $SECTION_BUFFER_START i32 (i32.const 17408))  ;; 17KB offset
  (global $SECTION_BUFFER_SIZE i32 (i32.const 8192))
  (global $section_pos (mut i32) (i32.const 0))

  ;; Initialize section generator
  (func $init_section_generator (export "init_section_generator")
    (global.set $section_pos (i32.const 0))
  )

  ;; Write WASM magic number and version
  ;; @param output_ptr: i32 - Pointer to output buffer
  ;; @returns i32 - Number of bytes written (8)
  (func $write_wasm_header (export "write_wasm_header") (param $output_ptr i32) (result i32)
    ;; WASM magic number: 0x6d736100 ("\0asm")
    (i32.store8 offset=0 (local.get $output_ptr) (i32.const 0x00))
    (i32.store8 offset=1 (local.get $output_ptr) (i32.const 0x61))
    (i32.store8 offset=2 (local.get $output_ptr) (i32.const 0x73))
    (i32.store8 offset=3 (local.get $output_ptr) (i32.const 0x6d))

    ;; WASM version: 0x01000000 (version 1)
    (i32.store8 offset=4 (local.get $output_ptr) (i32.const 0x01))
    (i32.store8 offset=5 (local.get $output_ptr) (i32.const 0x00))
    (i32.store8 offset=6 (local.get $output_ptr) (i32.const 0x00))
    (i32.store8 offset=7 (local.get $output_ptr) (i32.const 0x00))

    (i32.const 8)
  )

  ;; Write section header (section ID + size)
  ;; @param section_id: i32 - Section ID
  ;; @param content_size: i32 - Size of section content
  ;; @param output_ptr: i32 - Pointer to output buffer
  ;; @returns i32 - Number of bytes written
  (func $write_section_header (export "write_section_header") (param $section_id i32) (param $content_size i32) (param $output_ptr i32) (result i32)
    (local $bytes_written i32)

    ;; Write section ID
    (i32.store8 (local.get $output_ptr) (local.get $section_id))
    (local.set $bytes_written (i32.const 1))

    ;; Write section size as ULEB128
    (local.set $bytes_written
      (i32.add (local.get $bytes_written)
        (call $encode_uleb128_u32 (local.get $content_size)
          (i32.add (local.get $output_ptr) (local.get $bytes_written)))))

    (local.get $bytes_written)
  )

  ;; Generate type section
  ;; @param func_types: i32 - Pointer to function type data
  ;; @param func_type_count: i32 - Number of function types
  ;; @param output_ptr: i32 - Pointer to output buffer
  ;; @returns i32 - Number of bytes written
  (func $generate_type_section (export "generate_type_section") (param $func_types i32) (param $func_type_count i32) (param $output_ptr i32) (result i32)
    (local $content_start i32)
    (local $content_size i32)
    (local $bytes_written i32)
    (local $header_bytes i32)

    ;; Calculate content start (after header)
    (local.set $content_start (i32.add (local.get $output_ptr) (i32.const 10))) ;; Reserve space for header

    ;; Write function type count
    (local.set $content_size (call $encode_uleb128_u32 (local.get $func_type_count) (local.get $content_start)))

    ;; For now, write a simple function type: () -> ()
    ;; Function type format: 0x60 (func), param_count, [param_types], result_count, [result_types]
    (if (i32.gt_u (local.get $func_type_count) (i32.const 0))
      (then
        ;; Write function type marker
        (i32.store8 (i32.add (local.get $content_start) (local.get $content_size)) (i32.const 0x60))
        (local.set $content_size (i32.add (local.get $content_size) (i32.const 1)))

        ;; Write parameter count (0)
        (local.set $content_size
          (i32.add (local.get $content_size)
            (call $encode_uleb128_u32 (i32.const 0)
              (i32.add (local.get $content_start) (local.get $content_size)))))

        ;; Write result count (0)
        (local.set $content_size
          (i32.add (local.get $content_size)
            (call $encode_uleb128_u32 (i32.const 0)
              (i32.add (local.get $content_start) (local.get $content_size)))))
      )
    )

    ;; Write section header
    (local.set $header_bytes (call $write_section_header (global.get $SECTION_TYPE) (local.get $content_size) (local.get $output_ptr)))

    ;; Move content to correct position
    (call $memmove
      (i32.add (local.get $output_ptr) (local.get $header_bytes))
      (local.get $content_start)
      (local.get $content_size))

    (i32.add (local.get $header_bytes) (local.get $content_size))
  )

  ;; Generate import section
  ;; @param module_name_ptr: i32 - Module name
  ;; @param module_name_len: i32 - Module name length
  ;; @param import_name_ptr: i32 - Import name
  ;; @param import_name_len: i32 - Import name length
  ;; @param import_kind: i32 - Import kind (0=func, 2=memory)
  ;; @param type_index: i32 - Type index for functions, limits for memory
  ;; @param output_ptr: i32 - Pointer to output buffer
  ;; @returns i32 - Number of bytes written
  (func $generate_import_section (export "generate_import_section")
        (param $module_name_ptr i32) (param $module_name_len i32)
        (param $import_name_ptr i32) (param $import_name_len i32)
        (param $import_kind i32) (param $type_index i32)
        (param $output_ptr i32) (result i32)
    (local $content_start i32)
    (local $content_size i32)
    (local $header_bytes i32)

    ;; Calculate content start (after header)
    (local.set $content_start (i32.add (local.get $output_ptr) (i32.const 10))) ;; Reserve space for header

    ;; Write import count (1)
    (local.set $content_size (call $encode_uleb128_u32 (i32.const 1) (local.get $content_start)))

    ;; Write module name with length
    (local.set $content_size
      (i32.add (local.get $content_size)
        (call $write_string_with_length
          (local.get $module_name_ptr) (local.get $module_name_len)
          (i32.add (local.get $content_start) (local.get $content_size)))))

    ;; Write import name with length
    (local.set $content_size
      (i32.add (local.get $content_size)
        (call $write_string_with_length
          (local.get $import_name_ptr) (local.get $import_name_len)
          (i32.add (local.get $content_start) (local.get $content_size)))))

    ;; Write import kind
    (i32.store8 (i32.add (local.get $content_start) (local.get $content_size)) (local.get $import_kind))
    (local.set $content_size (i32.add (local.get $content_size) (i32.const 1)))

    ;; Write type index or memory limits
    (if (i32.eq (local.get $import_kind) (global.get $EXTERNAL_MEMORY))
      (then
        ;; Memory limits: has_max=0, initial_pages
        (i32.store8 (i32.add (local.get $content_start) (local.get $content_size)) (i32.const 0x00))
        (local.set $content_size (i32.add (local.get $content_size) (i32.const 1)))
        (local.set $content_size
          (i32.add (local.get $content_size)
            (call $encode_uleb128_u32 (local.get $type_index)
              (i32.add (local.get $content_start) (local.get $content_size)))))
      )
      (else
        ;; Function type index
        (local.set $content_size
          (i32.add (local.get $content_size)
            (call $encode_uleb128_u32 (local.get $type_index)
              (i32.add (local.get $content_start) (local.get $content_size)))))
      )
    )

    ;; Write section header
    (local.set $header_bytes (call $write_section_header (global.get $SECTION_IMPORT) (local.get $content_size) (local.get $output_ptr)))

    ;; Move content to correct position
    (call $memmove
      (i32.add (local.get $output_ptr) (local.get $header_bytes))
      (local.get $content_start)
      (local.get $content_size))

    (i32.add (local.get $header_bytes) (local.get $content_size))
  )

  ;; Generate function section (function type indices)
  ;; @param func_count: i32 - Number of functions
  ;; @param type_indices: i32 - Pointer to type indices
  ;; @param output_ptr: i32 - Pointer to output buffer
  ;; @returns i32 - Number of bytes written
  (func $generate_function_section (export "generate_function_section") (param $func_count i32) (param $type_indices i32) (param $output_ptr i32) (result i32)
    (local $content_start i32)
    (local $content_size i32)
    (local $header_bytes i32)
    (local $i i32)

    ;; Calculate content start (after header)
    (local.set $content_start (i32.add (local.get $output_ptr) (i32.const 10)))

    ;; Write function count
    (local.set $content_size (call $encode_uleb128_u32 (local.get $func_count) (local.get $content_start)))

    ;; Write type indices
    (local.set $i (i32.const 0))
    (loop $write_indices
      (if (i32.lt_u (local.get $i) (local.get $func_count))
        (then
          (local.set $content_size
            (i32.add (local.get $content_size)
              (call $encode_uleb128_u32
                (i32.load (i32.add (local.get $type_indices) (i32.mul (local.get $i) (i32.const 4))))
                (i32.add (local.get $content_start) (local.get $content_size)))))
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $write_indices)
        )
      )
    )

    ;; Write section header
    (local.set $header_bytes (call $write_section_header (global.get $SECTION_FUNCTION) (local.get $content_size) (local.get $output_ptr)))

    ;; Move content to correct position
    (call $memmove
      (i32.add (local.get $output_ptr) (local.get $header_bytes))
      (local.get $content_start)
      (local.get $content_size))

    (i32.add (local.get $header_bytes) (local.get $content_size))
  )

  ;; Generate export section
  ;; @param export_name_ptr: i32 - Export name
  ;; @param export_name_len: i32 - Export name length
  ;; @param export_kind: i32 - Export kind (0=func)
  ;; @param export_index: i32 - Export index
  ;; @param output_ptr: i32 - Pointer to output buffer
  ;; @returns i32 - Number of bytes written
  (func $generate_export_section (export "generate_export_section")
        (param $export_name_ptr i32) (param $export_name_len i32)
        (param $export_kind i32) (param $export_index i32)
        (param $output_ptr i32) (result i32)
    (local $content_start i32)
    (local $content_size i32)
    (local $header_bytes i32)

    ;; Calculate content start (after header)
    (local.set $content_start (i32.add (local.get $output_ptr) (i32.const 10)))

    ;; Write export count (1)
    (local.set $content_size (call $encode_uleb128_u32 (i32.const 1) (local.get $content_start)))

    ;; Write export name with length
    (local.set $content_size
      (i32.add (local.get $content_size)
        (call $write_string_with_length
          (local.get $export_name_ptr) (local.get $export_name_len)
          (i32.add (local.get $content_start) (local.get $content_size)))))

    ;; Write export kind
    (i32.store8 (i32.add (local.get $content_start) (local.get $content_size)) (local.get $export_kind))
    (local.set $content_size (i32.add (local.get $content_size) (i32.const 1)))

    ;; Write export index
    (local.set $content_size
      (i32.add (local.get $content_size)
        (call $encode_uleb128_u32 (local.get $export_index)
          (i32.add (local.get $content_start) (local.get $content_size)))))

    ;; Write section header
    (local.set $header_bytes (call $write_section_header (global.get $SECTION_EXPORT) (local.get $content_size) (local.get $output_ptr)))

    ;; Move content to correct position
    (call $memmove
      (i32.add (local.get $output_ptr) (local.get $header_bytes))
      (local.get $content_start)
      (local.get $content_size))

    (i32.add (local.get $header_bytes) (local.get $content_size))
  )

  ;; Generate code section
  ;; @param func_count: i32 - Number of functions
  ;; @param func_bodies: i32 - Pointer to function body data
  ;; @param output_ptr: i32 - Pointer to output buffer
  ;; @returns i32 - Number of bytes written
  (func $generate_code_section (export "generate_code_section") (param $func_count i32) (param $func_bodies i32) (param $output_ptr i32) (result i32)
    (local $content_start i32)
    (local $content_size i32)
    (local $header_bytes i32)

    ;; Calculate content start (after header)
    (local.set $content_start (i32.add (local.get $output_ptr) (i32.const 10)))

    ;; Write function count
    (local.set $content_size (call $encode_uleb128_u32 (local.get $func_count) (local.get $content_start)))

    ;; For now, write a simple function body: no locals, single instruction (end)
    (if (i32.gt_u (local.get $func_count) (i32.const 0))
      (then
        ;; Function body size (2 bytes: local count + end instruction)
        (local.set $content_size
          (i32.add (local.get $content_size)
            (call $encode_uleb128_u32 (i32.const 2)
              (i32.add (local.get $content_start) (local.get $content_size)))))

        ;; Local variable count (0)
        (local.set $content_size
          (i32.add (local.get $content_size)
            (call $encode_uleb128_u32 (i32.const 0)
              (i32.add (local.get $content_start) (local.get $content_size)))))

        ;; End instruction (0x0B)
        (i32.store8 (i32.add (local.get $content_start) (local.get $content_size)) (i32.const 0x0B))
        (local.set $content_size (i32.add (local.get $content_size) (i32.const 1)))
      )
    )

    ;; Write section header
    (local.set $header_bytes (call $write_section_header (global.get $SECTION_CODE) (local.get $content_size) (local.get $output_ptr)))

    ;; Move content to correct position
    (call $memmove
      (i32.add (local.get $output_ptr) (local.get $header_bytes))
      (local.get $content_start)
      (local.get $content_size))

    (i32.add (local.get $header_bytes) (local.get $content_size))
  )

  ;; Memory copy utility (memmove equivalent)
  ;; @param dest: i32 - Destination pointer
  ;; @param src: i32 - Source pointer
  ;; @param size: i32 - Number of bytes to copy
  (func $memmove (param $dest i32) (param $src i32) (param $size i32)
    (local $i i32)
    (local.set $i (i32.const 0))
    (loop $copy_loop
      (if (i32.lt_u (local.get $i) (local.get $size))
        (then
          (i32.store8
            (i32.add (local.get $dest) (local.get $i))
            (i32.load8_u (i32.add (local.get $src) (local.get $i))))
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $copy_loop)
        )
      )
    )
  )
)
