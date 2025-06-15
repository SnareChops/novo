# Functions and Control Flow

## Function Declaration

Functions are defined with the `func` keyword, optional parentheses, and flexible syntax:

```novo
// Function with no parameters - parentheses optional
func print-hello {
    log("Hello, world!")
}

// Function with parameters - parentheses optional
func print message:string {
    log(message)
}

// Traditional syntax still supported
func add(a: u64, b: u64) -> u64 {
    return a + b
}

// Optional parentheses with return type
func multiply a:u64 b:u64 -> u64 {
    return a * b
}

// Single parameter without parentheses
func square x:u64 -> u64 {
    return x * x
}
```

### Multiple Return Values

Functions can return multiple values:

```novo
// Multiple returns with optional parentheses
func get-customers-paged cont:continuation-token -> list<customer> continuation-token {
    // implementation
}

// Traditional syntax for multiple returns
func get-customers-paged(cont: continuation-token) -> (list<customer>, continuation-token) {
    // implementation
}
```

### Function Types

Functions can be used as types:

```novo
type add-func = func a:u32 b:u32 -> u32
type processor = func(input: string) -> result<string, error>
```

## Default Values

### Function Parameter Defaults

Functions support default parameter values:

```novo
func log-message(message: string, level: string = "info", timestamp: bool = true) {
    if timestamp {
        current-time := get-current-time()
        log(current-time + " [" + level + "] " + message)
    } else {
        log("[" + level + "] " + message)
    }
}

// Usage examples
log-message("Hello world")                           // Uses defaults
log-message("Debug info", "debug")                   // Uses timestamp default
log-message("Error occurred", "error", false)        // No defaults
```

### Function Call Defaults

Default values can be function calls, evaluated each time:

```novo
func create-temp-file(prefix: string = "temp", suffix: string = generate-uuid()) -> string {
    return prefix + "-" + suffix + ".tmp"
}

// Each call generates a new UUID for the suffix default
file1 := create-temp-file()           // e.g., "temp-abc123.tmp"
file2 := create-temp-file()           // e.g., "temp-def456.tmp"
```

## Inline Functions

Inline functions are expanded at compile time for performance:

```novo
// Definition of inline function
inline func add(a: u32, b: u32) -> u32 {
    result := a + b
    return result
}

// Usage - equivalent to writing a + b directly
func do-something() {
    x := add(2, 3)  // Inlined to: x := 2 + 3
}

// Optionally inline normal functions
func normal-function() {
    // implementation
}

func other-function() {
    inline normal-function()  // Force inline this call
}
```

## Higher-Order Functions

Functions can accept other functions as parameters:

```novo
// Function that accepts a func type
func apply-operation(numbers: list<u32>, operation: func(u32) -> u32) -> list<u32> {
    result := list<u32>()
    for num in numbers {
        transformed := operation(num)
        result.append(transformed)
    }
    return result
}

// Usage with block syntax
doubled := apply-operation(my-numbers) { x: u32 -> u32
    return x * 2
}

// Function with multiple function parameters
func fold initial: u32, items: list<u32>, accumulator: func(u32, u32) -> u32 -> u32 {
    result := initial
    for item in items {
        result = accumulator(result, item)
    }
    return result
}

// Usage
sum := fold(0, numbers) { acc: u32, item: u32 -> u32
    return acc + item
}
```

## Function Currying

Functions support automatic currying with `_` placeholders:

```novo
func add a:u32 b:u32 c:u32 -> u32 {
    return a + b + c
}

// Partial application with currying
add-five := add(5, _, _)           // Returns func(b: u32, c: u32) -> u32
add-five-and-ten := add(5, 10, _)  // Returns func(c: u32) -> u32

// Usage of curried functions
result1 := add-five(3, 7)      // Equivalent to add(5, 3, 7) = 15
result2 := add-five-and-ten(2) // Equivalent to add(5, 10, 2) = 17
```

## Control Flow

### Conditional Statements

#### If Statements

```novo
func check-value(x: s32) {
    if x > 0 {
        log("Positive number")
    }

    if x > 0 {
        log("Positive")
    } else {
        log("Zero or negative")
    }

    if x > 10 {
        log("Large")
    } else if x > 0 {
        log("Small positive")
    } else if x == 0 {
        log("Zero")
    } else {
        log("Negative")
    }
}
```

#### If Expressions

If statements can be used as expressions:

```novo
func get-sign(x: s32) -> string {
    result := if x > 0 {
        "positive"
    } else if x < 0 {
        "negative"
    } else {
        "zero"
    }
    return result
}

// Shorthand return syntax for if expressions
func get-sign-short(x: s32) -> string {
    if x > 0 return "positive"
    if x < 0 return "negative"
    return "zero"
}
```

**Expression validation requirements:**
- All branches must return the same type
- Stack depth must be consistent across all execution paths

### Loops

#### While Loops

```novo
func countdown(start: u32) {
    counter := start
    while counter > 0 {
        log("Count: " + counter.to-string())
        counter = counter - 1
    }
    log("Done!")
}

// Infinite loop with optional condition
func server-loop() {
    while {  // No condition = infinite loop
        request := wait-for-request()
        handle-request(request)
    }
}
```

#### Loop Labels

Loops can be labeled for precise break/continue control:

```novo
func nested-search(matrix: list<list<s32>>, target: s32) -> option<tuple<u32, u32>> {
    row := 0
    while $outer row < matrix.length {
        col := 0
        while $inner col < matrix[row].length {
            if matrix[row][col] == target {
                break $outer  // Exit both loops
            }
            col = col + 1
        }
        row = row + 1
    }
    return none
}
```

**Label syntax:**
- Labels are prefixed with `$` and must be valid identifiers
- `break $label` exits the loop with the specified label
- `continue $label` continues the loop with the specified label
- Unlabeled break/continue target the nearest enclosing loop

### Loop Control

The `break` statement exits loops and `continue` skips to the next iteration:

```novo
func find-value(list: list<s32>, target: s32) -> option<u32> {
    index := 0
    while index < list.length {
        if list[index] == target {
            return some(index)
        }
        index = index + 1
    }
    return none
}

func process-positive-numbers(numbers: list<s32>) {
    index := 0
    while index < numbers.length {
        current := numbers[index]
        index = index + 1

        if current <= 0 {
            continue  // Skip to next iteration
        }

        log("Processing: " + current::string())
        // Process positive number
    }
}
```

### Block Expressions

Blocks can be used as expressions, returning their last expression:

```novo
func complex-calculation(x: f32, y: f32) -> f32 {
    result := {
        temp1 := x * x
        temp2 := y * y
        temp1 + temp2  // This value is returned from the block
    }
    return result
}
```

### Early Return

Functions can return early using the `return` statement:

```novo
func validate-and-process(input: string) -> result<string, error> {
    if input.length == 0 {
        return error("Empty input")
    }

    if input.contains("invalid") {
        return error("Invalid content")
    }

    // Continue with normal processing
    processed := process(input)
    return ok(processed)
}
```

## WAT Compatibility

Control flow constructs compile to WebAssembly's structured control flow:
- `if`/`else` compile to `if`/`else` blocks in WAT
- `while` loops compile to `loop` blocks with conditional `br_if`
- `break` compiles to `br` instructions
- `continue` compiles to `br` to loop start
- Block expressions use WAT block constructs

This ensures predictable performance and maintains the structured nature required by WebAssembly validation.
