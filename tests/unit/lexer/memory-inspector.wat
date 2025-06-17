;; Memory inspector - read values written by debug test
(module $memory_inspector
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Export memory for inspection
  (export "memory" (memory 0))

  ;; Function to read and return memory values
  (func $read_values (export "read_values") (result i32 i32 i32 i32)
    (i32.load (i32.const 100))  ;; Token type
    (i32.load (i32.const 104))  ;; Token index
    (i32.load (i32.const 108))  ;; Next position
    (i32.load (i32.const 112))  ;; Magic number
  )
)
