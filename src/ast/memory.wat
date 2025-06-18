;; AST Memory Management
;; Handles memory allocation and deallocation for AST nodes
;; Implements a simple free list allocator for efficient memory management

(module $ast_memory
  ;; Import node structure constants
  (import "ast_node_types" "NODE_DATA_OFFSET" (global $NODE_DATA_OFFSET i32))

  ;; Define memory and export it - use 4 pages (256KB) for AST nodes
  (memory (export "memory") 4)

  ;; Memory Management Constants - Start after lexer memory areas
  (global $MEMORY_START i32 (i32.const 60000))      ;; Start at ~59KB to use upper part of memory
  (global $FREE_LIST_HEAD (export "FREE_LIST_HEAD") (mut i32) (i32.const 0))  ;; Head of free block list
  (global $ALLOC_CHUNK_SIZE i32 (i32.const 1024))   ;; 1KB chunks for better allocation
  (global $HEADER_SIZE i32 (i32.const 8))           ;; Size of allocation header

  ;; Initialize memory manager
  ;; Must be called before allocating memory
  (func $init_memory_manager (export "init_memory_manager")
    (local $block i32)
    (local $size i32)
    (local $i i32)

    ;; Initialize multiple chunks to provide more memory
    ;; With 256KB total memory, we can afford to initialize more chunks
    (local.set $i (i32.const 0))
    (local.set $block (global.get $MEMORY_START))
    (local.set $size (global.get $ALLOC_CHUNK_SIZE))

    ;; Initialize 32 chunks (16KB total allocation space)
    (loop $init_chunks
      (call $add_free_block
        (local.get $block)
        (local.get $size))

      ;; Move to next chunk
      (local.set $block
        (i32.add
          (local.get $block)
          (local.get $size)))

      ;; Increment counter
      (local.set $i (i32.add (local.get $i) (i32.const 1)))

      ;; Continue if we haven't reached 32 chunks
      (br_if $init_chunks (i32.lt_u (local.get $i) (i32.const 32)))
    )
  )

  ;; Search for a free block of suitable size
  ;; @param $size i32 - Required block size (excluding header)
  ;; @returns i32 - Pointer to block data, or 0 if no block found
  (func $find_free_block (param $size i32) (result i32)
    (local $curr i32)

    ;; Start at the head of free list
    (local.set $curr (global.get $FREE_LIST_HEAD))

    ;; Loop until suitable block found or end of list
    (block $search_done
      (loop $next_block
        ;; If we hit end of list, return 0
        (if (i32.eqz (local.get $curr))
          (then (br $search_done)))

        ;; Check if block is big enough
        (if (i32.ge_u
            (i32.sub
              (i32.load (local.get $curr))  ;; Block size
              (global.get $HEADER_SIZE))    ;; Header size
            (local.get $size))
          (then
            ;; Return pointer to data area (after header)
            (return (i32.add
              (local.get $curr)
              (global.get $HEADER_SIZE)))))

        ;; Move to next block
        (local.set $curr (i32.load offset=4 (local.get $curr)))
        (br $next_block)
      )
    )

    ;; No suitable block found
    (i32.const 0))

  ;; Add a block to the free list
  ;; @param $block i32 - Address of block to add
  ;; @param $size i32 - Total size of block (including header)
  (func $add_free_block (param $block i32) (param $size i32)
    ;; Store block size (including header)
    (i32.store
      (local.get $block)
      (local.get $size))

    ;; Link into free list
    (i32.store offset=4
      (local.get $block)
      (global.get $FREE_LIST_HEAD))

    ;; Update free list head
    (global.set $FREE_LIST_HEAD
      (local.get $block)))

  ;; Allocate a block of memory
  ;; @param $size i32 - Required size in bytes
  ;; @returns i32 - Pointer to allocated block, or 0 if allocation failed
  (func $allocate (export "allocate") (param $size i32) (result i32)
    (local $block i32)
    (local $total_size i32)

    ;; Add header size to requested size
    (local.set $total_size
      (i32.add
        (local.get $size)
        (global.get $HEADER_SIZE)))

    ;; Round up to allocation chunk size
    (local.set $total_size
      (i32.mul
        (i32.div_u
          (i32.add
            (local.get $total_size)
            (i32.sub
              (global.get $ALLOC_CHUNK_SIZE)
              (i32.const 1)))
          (global.get $ALLOC_CHUNK_SIZE))
        (global.get $ALLOC_CHUNK_SIZE)))

    ;; Find a free block
    (local.set $block
      (call $find_free_block (local.get $size)))

    ;; Return block pointer (0 if allocation failed)
    (local.get $block)
  )

  ;; Free a previously allocated block
  ;; @param $ptr i32 - Pointer to the block to free
  (func $free (export "free") (param $ptr i32)
    (local $block i32)
    (local $size i32)

    ;; Get block header address
    (local.set $block
      (i32.sub
        (local.get $ptr)
        (global.get $HEADER_SIZE)))

    ;; Get block size from header
    (local.set $size
      (i32.load (local.get $block)))

    ;; Add block to free list
    (call $add_free_block
      (local.get $block)
      (local.get $size))
  )
)
