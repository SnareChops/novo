;; Test is_letter function on '4'
(module $is_letter_test
  ;; Import memory
  (import "memory" "memory" (memory 1))
  
  ;; Import is_letter
  (import "char_utils" "is_letter" (func $is_letter (param i32) (result i32)))
  
  ;; Test function 
  (func $test_is_letter (export "_start")
    (local $char i32)
    (local $result i32)
    
    ;; Write test input: "4"
    (i32.store8 (i32.const 0) (i32.const 0x34))  ;; '4'
    
    ;; Load character
    (local.set $char (i32.load8_u (i32.const 0)))
    
    ;; Test is_letter
    (local.set $result (call $is_letter (local.get $char)))
    
    ;; If is_letter returns true (non-zero) for '4', that's wrong
    (if (local.get $result)
      (then
        (unreachable)  ;; Fail - '4' should not be a letter
      )
    )
    
    ;; Test passed
  )
)
