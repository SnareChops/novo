;; WebAssembly Text Format Keywords Module
;; Interface: keywords.wit
(module
  ;; Import memory from memory module
  (import "memory" "memory" (memory 1))
  (import "memory" "get-memory-layout" (func $get_memory_layout (result i32 i32 i32 i32 i32)))
    ;; Import memory from the memory component
    (import "memory" "memory" (memory 1))

    ;; Keywords table structure:
    ;; Each entry is 8 bytes:
    ;; - 4 bytes: string pointer
    ;; - 2 bytes: string length
    ;; - 2 bytes: reserved/flags

  ;; WAT Keywords (stored in data section)
  (data (i32.const 0x4000)
    "module\00"     ;; 0x4000
    "func\00"       ;; 0x4007
    "param\00"      ;; 0x400C
    "result\00"     ;; 0x4012
    "export\00"     ;; 0x4019
    "import\00"     ;; 0x4020
    "memory\00"     ;; 0x4027
    "table\00"      ;; 0x402E
    "global\00"     ;; 0x4034
    "local\00"      ;; 0x403B
    "type\00"       ;; 0x4041
    "i32\00"        ;; 0x4046
    "i64\00"        ;; 0x404A
    "f32\00"        ;; 0x404E
    "f64\00"        ;; 0x4052
  )

  ;; Keyword table (array of entries)
  (data (i32.const 0x5000)
    ;; module entry
    "\00\40\00\00" ;; ptr: 0x4000
    "\06\00"       ;; len: 6
    "\00\00"       ;; flags

    ;; func entry
    "\07\40\00\00" ;; ptr: 0x4007
    "\04\00"       ;; len: 4
    "\00\00"       ;; flags

    ;; ... additional entries follow same pattern
  )

  (global $KEYWORD_COUNT i32 (i32.const 25))  ;; Number of keywords (including component keywords)

    ;; Check if a string is a keyword
    (func $is_keyword (export "is-keyword")
      (param $str_ptr i32)
      (param $str_len i32)
      (result i32)
    (local $i i32)
    (local $entry_ptr i32)
    (local $kw_ptr i32)
    (local $kw_len i32)

    (local.set $i (i32.const 0))

    (block $search_done
      (loop $search_keywords
        ;; Check if we've checked all keywords
        (br_if $search_done
          (i32.ge_u (local.get $i) (global.get $KEYWORD_COUNT)))

        ;; Get current keyword entry
        (local.set $entry_ptr
          (i32.add
            (i32.const 0x5000)
            (i32.mul (local.get $i) (i32.const 8))))

        ;; Load keyword pointer and length
        (local.set $kw_ptr (i32.load (local.get $entry_ptr)))
        (local.set $kw_len (i32.load16_u (i32.add (local.get $entry_ptr) (i32.const 4))))

        ;; Check length first
        (if (i32.eq (local.get $str_len) (local.get $kw_len))
          (then
            ;; Compare strings
            (if (call $compare_strings
                  (local.get $str_ptr)
                  (local.get $kw_ptr)
                  (local.get $str_len))
              (then
                ;; Found matching keyword
                (return (i32.const 1))))))

        ;; Try next keyword
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $search_keywords)))

    ;; Not found
    (i32.const 0)
  )

  ;; Compare two strings (helper function)
  (func $compare_strings
    (param $s1_ptr i32)
    (param $s2_ptr i32)
    (param $len i32)
    (result i32)
    (local $i i32)

    (local.set $i (i32.const 0))

    (block $compare_done
      (loop $compare_chars
        ;; Check if we've compared all characters
        (br_if $compare_done
          (i32.ge_u (local.get $i) (local.get $len)))

        ;; Compare current characters
        (if (i32.ne
              (i32.load8_u
                (i32.add (local.get $s1_ptr) (local.get $i)))
              (i32.load8_u
                (i32.add (local.get $s2_ptr) (local.get $i))))
          (then
            (return (i32.const 0))))

        ;; Move to next character
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $compare_chars)))

    ;; Strings match
    (i32.const 1)
  )
)
