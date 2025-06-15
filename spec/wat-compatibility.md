# WAT Compatibility

This document covers novo's integration with WebAssembly Text Format (WAT) and its compilation targets.

## Compilation Targets

Novo compiles to WebAssembly Component Model (.wasm) files, but the development toolchain supports the text format for debugging and optimization.

### Primary Target: WASM Component Model

```novo
component example {
    export func calculate(x: s32, y: s32) -> s32 {
        return x + y
    }
}
```

**Compiles to:** WebAssembly Component Model binary with proper type definitions and component interfaces.

### Development Target: WAT Text Format

For debugging and educational purposes, novo can generate WAT text format:

```wat
(component
  (core module $example
    (func $calculate (param $x i32) (param $y i32) (result i32)
      local.get $x
      local.get $y
      i32.add
    )
    (export "calculate" (func $calculate))
  )
  (core instance $example-inst (instantiate $example))
  (func $calculate (param "x" s32) (param "y" s32) (result s32)
    (canon lift (core func $example-inst "calculate"))
  )
  (export "calculate" (func $calculate))
)
```

## Type Mapping

Novo types map directly to WebAssembly Component Model types, which then map to WAT core types:

### Primitive Types

| Novo Type | Component Model | WAT Core |
|-----------|----------------|----------|
| `s8`      | `s8`          | `i32`    |
| `s16`     | `s16`         | `i32`    |
| `s32`     | `s32`         | `i32`    |
| `s64`     | `s64`         | `i64`    |
| `u8`      | `u8`          | `u32`    |
| `u16`     | `u16`         | `u32`    |
| `u32`     | `u32`         | `u32`    |
| `u64`     | `u64`         | `u64`    |
| `f32`     | `float32`     | `f32`    |
| `f64`     | `float64`     | `f64`    |
| `char`    | `char`        | `i32`    |
| `bool`    | `bool`        | `i32`    |
| `string`  | `string`      | pointer + length |

### Complex Type Mappings

```novo
// Novo record
record person {
    name: string
    age: u32
}

// Maps to Component Model record
(type $person (record
  (field "name" string)
  (field "age" u32)
))

// WAT representation uses struct layout in linear memory
```

### Option Type Mapping

```novo
func get-name() -> option<string>
```

**Component Model:**
```wit
get-name: func() -> option<string>
```

**WAT Implementation:**
```wat
;; Option<string> represented as discriminated union
;; Layout: [tag: i32][data: varies]
;; tag = 0: none, tag = 1: some(data)
```

### Result Type Mapping

```novo
func divide(x: f64, y: f64) -> result<f64, string>
```

**Component Model:**
```wit
divide: func(x: float64, y: float64) -> result<float64, string>
```

**WAT Implementation:**
```wat
;; Result<f64, string> as discriminated union
;; tag = 0: ok(f64), tag = 1: err(string)
```

## Memory Management

### Linear Memory Layout

Novo manages WebAssembly linear memory with specific patterns:

```novo
func process-data(input: string) -> string {
    // String operations use WAT memory management
    result := transform(input)
    return result
}
```

**WAT Memory Layout:**
```wat
(memory 1)  ;; Initial memory pages

;; String layout: [length: i32][utf8_bytes...]
;; Allocation uses bump allocator or free list
```

### Stack vs Heap Allocation

```novo
func example() {
    // Stack-allocated (WAT locals)
    x := 42
    y := 3.14

    // Heap-allocated (WAT linear memory)
    data := "hello world"
    numbers := [1, 2, 3, 4, 5]
}
```

**WAT Implementation:**
```wat
(func $example
  (local $x i32)
  (local $y f64)
  ;; Stack values use WAT locals

  ;; Heap allocations use memory operations
  (call $alloc_string)  ;; For "hello world"
  (call $alloc_array)   ;; For [1,2,3,4,5]
)
```

## Function Calling Conventions

### Standard Functions

```novo
func add(x: s32, y: s32) -> s32 {
    return x + y
}
```

**WAT Output:**
```wat
(func $add (param $x i32) (param $y i32) (result i32)
  local.get $x
  local.get $y
  i32.add
)
```

### Functions with Complex Types

```novo
func process-person(p: person) -> result<string, error> {
    // Process person record
}
```

**WAT Implementation:**
```wat
;; Complex types passed by reference through linear memory
(func $process-person (param $person_ptr i32) (result i32)
  ;; Returns pointer to result discriminated union
)
```

## Control Flow Mapping

### Match Statements

```novo
match value {
    some(x) => process(x)
    none => default-value()
}
```

**WAT Implementation:**
```wat
;; Match compiles to conditional branches
local.get $value_tag
i32.const 0
i32.eq
if (result i32)
  ;; none case
  call $default_value
else
  ;; some case - extract data and process
  local.get $value_data
  call $process
end
```

### Loop Constructs

```novo
for item in items {
    process(item)
}
```

**WAT Implementation:**
```wat
;; Iterator pattern with bounds checking
(loop $for_loop
  ;; Check bounds
  local.get $index
  local.get $length
  i32.lt_u
  if
    ;; Process current item
    local.get $items_ptr
    local.get $index
    ;; ... array access and process call

    ;; Increment and continue
    local.get $index
    i32.const 1
    i32.add
    local.set $index
    br $for_loop
  end
)
```

## Component Model Integration

### Interface Exports

```novo
package example:calculator

component calc {
    func add(x: s32, y: s32) -> s32 { return x + y }
    func multiply(x: s32, y: s32) -> s32 { return x * y }
}
```

**Component Model Output:**
```wit
package example:calculator

interface calculator {
  add: func(x: s32, y: s32) -> s32
  multiply: func(x: s32, y: s32) -> s32
}

world calc {
  export calculator
}
```

### Import Resolution

```novo
component app {
    import wasi:filesystem/types.{descriptor}
    import logging

    export func main() {
        // Use imported interfaces
    }
}
```

**WAT Integration:**
```wat
;; Imports become WAT import declarations
(import "wasi:filesystem/types" "descriptor" (func $descriptor ...))
(import "logging" "log" (func $log ...))
```

## Optimization Patterns

### Dead Code Elimination

Novo compiler performs dead code elimination before WAT generation:

```novo
func unused-function() -> s32 {
    return 42  // Not referenced, eliminated in WAT
}

func main() -> s32 {
    return calculate(10, 20)  // Only this path in final WAT
}
```

### Constant Folding

```novo
func example() -> s32 {
    x := 10 + 20  // Folded to 30 at compile time
    return x * 2  // Becomes: return 60
}
```

**WAT Output:**
```wat
(func $example (result i32)
  i32.const 60
)
```

### Inline Function Expansion

```novo
inline func double(x: s32) -> s32 {
    return x * 2
}

func test() -> s32 {
    return double(21)  // Inlined: return 21 * 2
}
```

**WAT Output:**
```wat
(func $test (result i32)
  i32.const 21
  i32.const 2
  i32.mul
)
```

## WASI Integration

### File System Access

```novo
component file-reader {
    import wasi:filesystem/types.{descriptor, error-code}

    export func read-file(path: string) -> result<string, error-code> {
        // WASI filesystem operations
    }
}
```

**WAT Integration:**
```wat
;; WASI imports
(import "wasi:filesystem/types" "descriptor" (type ...))
(import "wasi:filesystem/preopens" "get-directories" (func ...))

;; Component exports with proper type lifting
(export "read-file" (func $read_file))
```

## Performance Considerations

### Memory Access Patterns

- Novo generates aligned memory access when possible
- String operations use efficient UTF-8 handling
- Arrays use contiguous memory layout for cache efficiency

### Call Overhead

- Interface calls use Component Model canonical ABI
- Internal calls compile to direct WAT function calls
- Inline functions eliminate call overhead entirely

## Cross-References

- See [Basic Types](basic-types.md) for type mapping details
- See [Complex Types](complex-types.md) for record and variant layouts
- See [Components and Interfaces](components-interfaces.md) for component compilation
- See [Functions and Control Flow](functions-control-flow.md) for control flow mapping
