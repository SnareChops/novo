;; Test scan_number function directly
(module $scan_number_test
  ;; Import memory
  (import "memory" "memory" (memory 1))
  
  ;; Import char utils
  (import "char_utils" "is_digit" (func $is_digit (param i32) (result i32)))
  
  ;; Test scan_number logic (copied from lexer)
  (func $scan_number (param $pos i32) (result i32)
    (local $current_pos i32)
    (local $char i32)

    (local.set $current_pos (local.get $pos))

    ;; Skip digits
    (loop $scan_digits
      (local.set $char (i32.load8_u (local.get $current_pos)))

      (if (call $is_digit (local.get $char))
        (then
          (local.set $current_pos (i32.add (local.get $current_pos) (i32.const 1)))
          (br $scan_digits)
        )
      )
    )

    (local.get $current_pos)
  )
  
  ;; Test function 
  (func $test_scan_number (export "_start")
    (local $start_pos i32)
    (local $end_pos i32)
    
    ;; Write test input: "4"
    (i32.store8 (i32.const 0) (i32.const 0x34))  ;; '4'
    (i32.store8 (i32.const 1) (i32.const 0x00))  ;; null terminator
    
    (local.set $start_pos (i32.const 0))
    
    ;; Call scan_number
    (local.set $end_pos (call $scan_number (local.get $start_pos)))
    
    ;; Should advance by 1 (from position 0 to position 1)
    (if (i32.ne (local.get $end_pos) (i32.const 1))
      (then
        (unreachable)  ;; Fail - scan_number didn't advance correctly
      )
    )
    
    ;; Test passed
  )
)
