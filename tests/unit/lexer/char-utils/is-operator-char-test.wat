;; Test is_operator_char function on '4'
(module $is_operator_char_test
  ;; Import memory
  (import "memory" "memory" (memory 1))
  
  ;; Import is_operator_char
  (import "char_utils" "is_operator_char" (func $is_operator_char (param i32) (result i32)))
  
  ;; Test function 
  (func $test_is_operator_char (export "_start")
    (local $char i32)
    (local $result i32)
    
    ;; Write test input: "4"
    (i32.store8 (i32.const 0) (i32.const 0x34))  ;; '4'
    
    ;; Load character
    (local.set $char (i32.load8_u (i32.const 0)))
    
    ;; Test is_operator_char
    (local.set $result (call $is_operator_char (local.get $char)))
    
    ;; If is_operator_char returns true (non-zero) for '4', that's wrong
    (if (local.get $result)
      (then
        (unreachable)  ;; Fail - '4' should not be an operator
      )
    )
    
    ;; Test passed
  )
)
