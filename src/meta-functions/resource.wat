;; Meta Functions for Resource Types
;; Implements resource-specific meta functions like new() and destroy()

(module $meta_functions_resource
  ;; Import memory
  (import "lexer_memory" "memory" (memory 1))

  ;; Import meta function core
  (import "meta_functions_core" "META_FUNC_NEW" (global $META_FUNC_NEW i32))
  (import "meta_functions_core" "META_FUNC_DESTROY" (global $META_FUNC_DESTROY i32))
  (import "meta_functions_core" "META_FUNC_SIZE" (global $META_FUNC_SIZE i32))

  ;; Import AST for resource structure access
  (import "ast_node_types" "TYPE_RESOURCE" (global $TYPE_RESOURCE i32))
  (import "ast_node_core" "get_node_type" (func $get_node_type (param i32) (result i32)))
  (import "ast_node_core" "get_child_count" (func $get_child_count (param i32) (result i32)))
  (import "ast_node_core" "get_child" (func $get_child (param i32 i32) (result i32)))

  ;; Resource handle table for tracking active resources
  ;; This is a simplified implementation - in a real system you'd want more sophisticated resource management
  (global $resource_table_start i32 (i32.const 2048))
  (global $resource_table_size i32 (i32.const 1024))   ;; 256 resource entries * 4 bytes each
  (global $next_resource_id (mut i32) (i32.const 1))

  ;; Resource entry structure (4 bytes per entry):
  ;; [0-3]: Resource type ID or 0 if free

  ;; Initialize the resource management system
  (func $init_resource_system (export "init_resource_system")
    (local $i i32)
    (local $addr i32)

    ;; Clear the resource table
    (local.set $i (i32.const 0))
    (loop $clear_loop
      (if (i32.lt_u (local.get $i) (global.get $resource_table_size))
        (then
          (local.set $addr (i32.add (global.get $resource_table_start) (local.get $i)))
          (i32.store (local.get $addr) (i32.const 0))
          (local.set $i (i32.add (local.get $i) (i32.const 4)))
          (br $clear_loop))))
  )

  ;; Allocate a new resource handle
  ;; @param resource_type: i32 - Type ID of the resource
  ;; @returns i32 - Resource handle (0 if allocation failed)
  (func $allocate_resource (export "allocate_resource") (param $resource_type i32) (result i32)
    (local $i i32)
    (local $addr i32)
    (local $handle i32)

    ;; Find a free slot in the resource table
    (local.set $i (i32.const 0))
    (loop $find_slot_loop
      (if (i32.lt_u (local.get $i) (global.get $resource_table_size))
        (then
          (local.set $addr (i32.add (global.get $resource_table_start) (local.get $i)))
          ;; Check if slot is free (type ID is 0)
          (if (i32.eqz (i32.load (local.get $addr)))
            (then
              ;; Allocate this slot
              (i32.store (local.get $addr) (local.get $resource_type))
              ;; Calculate handle (slot index + 1)
              (local.set $handle (i32.add (i32.div_u (local.get $i) (i32.const 4)) (i32.const 1)))
              (return (local.get $handle))))
          (local.set $i (i32.add (local.get $i) (i32.const 4)))
          (br $find_slot_loop))))

    ;; No free slots available
    (i32.const 0)
  )

  ;; Deallocate a resource handle
  ;; @param handle: i32 - Resource handle to deallocate
  ;; @returns i32 - 1 if successful, 0 if invalid handle
  (func $deallocate_resource (export "deallocate_resource") (param $handle i32) (result i32)
    (local $slot_index i32)
    (local $addr i32)

    ;; Validate handle
    (if (i32.or (i32.eqz (local.get $handle))
                (i32.ge_u (local.get $handle) (i32.const 257)))
      (then (return (i32.const 0))))

    ;; Calculate slot address
    (local.set $slot_index (i32.sub (local.get $handle) (i32.const 1)))
    (local.set $addr (i32.add (global.get $resource_table_start)
                              (i32.mul (local.get $slot_index) (i32.const 4))))

    ;; Check if slot is actually allocated
    (if (i32.eqz (i32.load (local.get $addr)))
      (then (return (i32.const 0))))

    ;; Free the slot
    (i32.store (local.get $addr) (i32.const 0))
    (i32.const 1)
  )

  ;; Get the type of a resource handle
  ;; @param handle: i32 - Resource handle
  ;; @returns i32 - Resource type ID (0 if invalid handle)
  (func $get_resource_type (export "get_resource_type") (param $handle i32) (result i32)
    (local $slot_index i32)
    (local $addr i32)

    ;; Validate handle
    (if (i32.or (i32.eqz (local.get $handle))
                (i32.ge_u (local.get $handle) (i32.const 257)))
      (then (return (i32.const 0))))

    ;; Calculate slot address
    (local.set $slot_index (i32.sub (local.get $handle) (i32.const 1)))
    (local.set $addr (i32.add (global.get $resource_table_start)
                              (i32.mul (local.get $slot_index) (i32.const 4))))

    ;; Return the resource type
    (i32.load (local.get $addr))
  )

  ;; Create a new resource instance (::new() meta function)
  ;; @param resource_type: i32 - Type ID of the resource to create
  ;; @param constructor_args: i32 - Pointer to constructor arguments (simplified)
  ;; @returns i32 - Resource handle (0 if creation failed)
  (func $resource_new (export "resource_new") (param $resource_type i32) (param $constructor_args i32) (result i32)
    (local $handle i32)

    ;; Allocate a resource handle
    (local.set $handle (call $allocate_resource (local.get $resource_type)))
    (if (i32.eqz (local.get $handle))
      (then (return (i32.const 0))))

    ;; Initialize the resource (simplified)
    ;; In a real implementation, you'd call the resource constructor
    ;; and set up the resource-specific data

    ;; For now, just return the handle
    (local.get $handle)
  )

  ;; Destroy a resource instance (::destroy() meta function)
  ;; @param handle: i32 - Resource handle to destroy
  ;; @returns i32 - 1 if successful, 0 if failed
  (func $resource_destroy (export "resource_destroy") (param $handle i32) (result i32)
    (local $resource_type i32)

    ;; Get resource type before destroying
    (local.set $resource_type (call $get_resource_type (local.get $handle)))
    (if (i32.eqz (local.get $resource_type))
      (then (return (i32.const 0))))

    ;; Perform resource-specific cleanup
    ;; In a real implementation, you'd call the resource destructor
    (call $perform_resource_cleanup (local.get $handle) (local.get $resource_type))

    ;; Deallocate the handle
    (call $deallocate_resource (local.get $handle))
  )

  ;; Perform resource-specific cleanup
  ;; @param handle: i32 - Resource handle
  ;; @param resource_type: i32 - Resource type ID
  (func $perform_resource_cleanup (param $handle i32) (param $resource_type i32)
    ;; This is where you'd implement resource-specific cleanup logic
    ;; For example:
    ;; - Close file handles
    ;; - Free allocated memory
    ;; - Release network connections
    ;; - etc.

    ;; For now, this is a no-op
    ;; In a real implementation, you'd switch on resource_type and call appropriate cleanup
  )

  ;; Get the size of a resource type
  ;; @param resource_type: i32 - Type ID of the resource
  ;; @returns i32 - Size in bytes (including extended resources)
  (func $get_resource_size (export "get_resource_size") (param $resource_type i32) (result i32)
    ;; Base resource handle size
    (local $base_size i32)
    (local.set $base_size (i32.const 4))  ;; Resource handle is 4 bytes

    ;; In a real implementation, you'd calculate the actual size based on:
    ;; - Resource type definition
    ;; - Extended/embedded resources
    ;; - Resource-specific data structures

    ;; For now, return a fixed size
    (local.get $base_size)
  )

  ;; Get the type name of a resource
  ;; @param resource_type: i32 - Type ID of the resource
  ;; @param dest_ptr: i32 - Destination buffer for type name
  ;; @returns i32 - Length of type name
  (func $get_resource_type_name (export "get_resource_type_name") (param $resource_type i32) (param $dest_ptr i32) (result i32)
    ;; For now, just return "resource"
    ;; In a real implementation, you'd return the actual resource type name
    (i32.store8 (local.get $dest_ptr) (i32.const 114))       ;; 'r'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 1)) (i32.const 101))  ;; 'e'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 2)) (i32.const 115))  ;; 's'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 3)) (i32.const 111))  ;; 'o'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 4)) (i32.const 117))  ;; 'u'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 5)) (i32.const 114))  ;; 'r'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 6)) (i32.const 99))   ;; 'c'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 7)) (i32.const 101))  ;; 'e'
    (i32.const 8)
  )

  ;; Convert resource to string representation
  ;; @param handle: i32 - Resource handle
  ;; @param dest_ptr: i32 - Destination buffer for string
  ;; @returns i32 - Length of generated string
  (func $resource_to_string (export "resource_to_string") (param $handle i32) (param $dest_ptr i32) (result i32)
    (local $resource_type i32)

    ;; Get resource type
    (local.set $resource_type (call $get_resource_type (local.get $handle)))
    (if (i32.eqz (local.get $resource_type))
      (then
        ;; Invalid resource
        (i32.store8 (local.get $dest_ptr) (i32.const 105))       ;; 'i'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 1)) (i32.const 110))  ;; 'n'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 2)) (i32.const 118))  ;; 'v'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 3)) (i32.const 97))   ;; 'a'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 4)) (i32.const 108))  ;; 'l'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 5)) (i32.const 105))  ;; 'i'
        (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 6)) (i32.const 100))  ;; 'd'
        (return (i32.const 7))))

    ;; Generate string representation: resource#handle
    (i32.store8 (local.get $dest_ptr) (i32.const 114))       ;; 'r'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 1)) (i32.const 101))  ;; 'e'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 2)) (i32.const 115))  ;; 's'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 3)) (i32.const 35))   ;; '#'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 4)) (i32.const 88))   ;; 'X'
    (i32.store8 (i32.add (local.get $dest_ptr) (i32.const 5)) (i32.const 88))   ;; 'X'
    (i32.const 6)
  )

  ;; Check if a resource supports extension/embedding
  ;; @param resource_type: i32 - Type ID of the resource
  ;; @returns i32 - 1 if supports extension, 0 if not
  (func $resource_supports_extension (export "resource_supports_extension") (param $resource_type i32) (result i32)
    ;; In a real implementation, you'd check the resource type definition
    ;; For now, assume all resources support extension
    (i32.const 1)
  )

  ;; Get the cleanup chain for an extended resource
  ;; @param handle: i32 - Resource handle
  ;; @param cleanup_chain_ptr: i32 - Destination for cleanup chain info
  ;; @returns i32 - Number of cleanup steps
  (func $get_resource_cleanup_chain (export "get_resource_cleanup_chain") (param $handle i32) (param $cleanup_chain_ptr i32) (result i32)
    ;; In a real implementation, you'd traverse the resource extension chain
    ;; and build a list of cleanup functions to call

    ;; For now, return a single cleanup step
    (i32.store (local.get $cleanup_chain_ptr) (local.get $handle))
    (i32.const 1)
  )
)
