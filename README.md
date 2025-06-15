# Novo Language Specification

Novo is a WebAssembly-targeted programming language designed to directly interface with the WebAssembly Component Model. It provides a modern, type-safe way to create WASM components that can run on any WASM-compliant runtime.

## Quick Overview

Novo is a compiled language that:
- Compiles directly to binary `.wasm` files and outputs `.wit` interface definitions
- Supports all WebAssembly Component Model types and concepts from the WIT specification
- Maintains compatibility with core WASM when needed
- Provides modern language features like pattern matching, type inference, and memory safety
- Integrates seamlessly with WASI and other WASM ecosystem components

## Language Goals

1. **WIT-First Design**: All types and concepts are directly driven from the WIT specification
2. **WebAssembly Integration**: Retain the ability to write raw WASM instructions following WAT conventions
3. **Transparent Memory Management**: Memory management follows WASM conventions with clear stack usage
4. **Developer Control**: Stack function details are not hidden from developers

## Quick Examples

### Basic Function and Types

```novo
// Simple function with type inference
func greet(name: string) -> string {
    return "Hello, " + name + "!"
}

// Working with complex types
record person {
    name: string
    age: u32
    email: option<string>
}

func create-person(name: string, age: u32) -> person {
    return person {
        name: name
        age: age
        email: none
    }
}
```

### Pattern Matching

```novo
func process-result(result: result<string, error>) -> string {
    match result {
        ok(value) => "Success: " + value
        err(e) => "Error: " + e.message
    }
}

func handle-option(data: option<string>) -> string {
    match data {
        some(value) => value
        none => "No data available"
    }
}
```

### Component Definition

```novo
component web-service {
    import wasi:http/incoming-handler
    export wasi:http/outgoing-handler

    func handle-request(request: http-request) -> http-response {
        // Process the request
        return http-response {
            status: 200
            headers: []
            body: "Hello from novo!"
        }
    }
}
```

### Interface Definition

```novo
interface calculator {
    func add(x: s32, y: s32) -> s32
    func multiply(x: s32, y: s32) -> s32
    func divide(x: f64, y: f64) -> result<f64, math-error>
}
```

## Documentation Structure

The novo language specification is organized into focused documents covering different aspects of the language:

### Core Language

- **[Overview](spec/overview.md)** - Language philosophy, goals, and compilation model
- **[Basic Types](spec/basic-types.md)** - Primitive types, identifiers, variables, and type system fundamentals
- **[Complex Types](spec/complex-types.md)** - Records, variants, lists, options, results, and other WIT-compatible types
- **[Functions and Control Flow](spec/functions-control-flow.md)** - Function definition, parameters, control structures, and flow control
- **[Pattern Matching](spec/pattern-matching.md)** - Match expressions, destructuring, guards, and exhaustiveness checking

### Component System

- **[Components and Interfaces](spec/components-interfaces.md)** - Component definition, interfaces, imports/exports, and the component model
- **[WAT Compatibility](spec/wat-compatibility.md)** - WebAssembly integration, compilation targets, and low-level details

### Advanced Features

- **[Meta Functions](spec/meta-functions.md)** - Meta-functions and property tags
- **[Future Features](spec/future-features.md)** - Planned language extensions and research directions

## Getting Started

1. **Read the [Overview](spec/overview.md)** to understand novo's design philosophy and goals
2. **Explore [Basic Types](spec/basic-types.md)** to learn the type system fundamentals
3. **Study [Functions and Control Flow](spec/functions-control-flow.md)** for control structures and function definition
4. **Learn [Pattern Matching](spec/pattern-matching.md)** for powerful data destructuring capabilities
5. **Understand [Components and Interfaces](spec/components-interfaces.md)** for building modular WASM applications

## Language Characteristics

### Type Safety
- Strong static typing with type inference
- No null pointer exceptions (uses `option<T>` instead)
- Exhaustive pattern matching ensures all cases are handled

### WebAssembly Native
- Direct compilation to WASM Component Model
- Full WIT specification compliance
- Seamless WASI integration
- Full control over memory layout and performance

### Modern Language Features
- Pattern matching with guards and destructuring

### Developer Experience
- Clear error messages with suggestions
- Comprehensive tooling and IDE support
- Excellent debugging capabilities
- Strong ecosystem integration

## Example Applications

Novo is well-suited for:
- **Microservices and APIs** using WASI HTTP interfaces
- **Plugin systems** with sandboxed component isolation
- **Edge computing** with fast startup and small binary sizes
- **Data processing pipelines** with type-safe transformations
- **System utilities** with safe memory management
- **Cross-platform libraries** targeting multiple WASM runtimes

## Community

- **Specification**: This repository contains the complete language specification
- **Implementation**: Compiler and tooling implementation details
- **Examples**: Sample projects and tutorials
- **RFC Process**: Language evolution through community proposals

---

For detailed information about any aspect of the novo language, please refer to the specific documentation files linked above. Each document provides comprehensive coverage of its topic with examples and cross-references to related concepts.
