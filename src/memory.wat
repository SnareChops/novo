;; WebAssembly Memory Management Module
;; Interface: memory.wit
(module
  ;; Export memory for other modules
  (memory (export "memory") 1)  ;; Initial 1 page (64KB)

  ;; Memory layout constants
  (global $SYSTEM_BASE i32 (i32.const 0x0000))
  (global $LEXER_STATE_BASE i32 (i32.const 0x1000))
  (global $STRING_POOL_BASE i32 (i32.const 0x3000))
  (global $SYMBOL_TABLE_BASE i32 (i32.const 0x4000))
  (global $GENERAL_ALLOC_BASE i32 (i32.const 0x8000))

  ;; Export function to get memory layout
  (func (export "get-memory-layout")
    (result i32 i32 i32 i32 i32)
    (global.get $SYSTEM_BASE)
    (global.get $LEXER_STATE_BASE)
    (global.get $STRING_POOL_BASE)
    (global.get $SYMBOL_TABLE_BASE)
    (global.get $GENERAL_ALLOC_BASE)))
