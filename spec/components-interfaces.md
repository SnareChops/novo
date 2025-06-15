# Components and Interfaces

This document covers novo's component system, interface definitions, and how they integrate with the WebAssembly Component Model.

## Interfaces

An interface describes a single-focus, composable contract through which components can interact with each other and with hosts. Interfaces describe the types and functions used to carry out that interaction.

### Interface Definition

```novo
interface storage {
    func get(key: string) -> option<string>
    func set(key: string, value: string) -> result
    func delete(key: string) -> result
}

interface http-client {
    record request {
        url: string
        method: string
        headers: list<tuple<string, string>>
        body: option<string>
    }

    record response {
        status: u16
        headers: list<tuple<string, string>>
        body: string
    }

    func send(req: request) -> result<response, error>
}
```

**Interface characteristics:**
- Focused on a single responsibility (storage, HTTP, etc.)
- Self-contained type definitions
- Clear function contracts
- WIT-compatible structure

### Interface Examples

A "receive HTTP requests" interface might have only a single "handle request" function, but contain types representing incoming requests, outgoing responses, HTTP methods and headers, and so on.

A "wall clock" interface might have two functions, one to get the current time and one to get the granularity of the timer. It would also include a type to represent an instant in time.

## Components

A novo component is a higher-level contract that describes capabilities and needs.

> Unlike in WIT, a novo component also encapsulates the concept of a world.

A component describes the shape of your code, as well as its implementation - it says which interfaces the component exposes for other code to call (its exports), and which interfaces the component depends on (its imports).

### Component Definition

A component is defined with the `component` keyword, a name, and its contents enclosed in braces:

```novo
component http-proxy {
    // Import dependencies
    import wasi:http/outgoing-handler
    import logging

    // Export capabilities
    export wasi:http/incoming-handler
    export management

    // Implementation
    func handle-request(req: request) -> response {
        // Proxy logic implementation
        outgoing-req := transform-request(req)
        response := wasi:http/outgoing-handler.send(outgoing-req)
        return transform-response(response)
    }
}
```

**Component characteristics:**
- Provides strong sandboxing - can only interact through imports/exports
- Cannot access anything outside itself except via declared interfaces
- Combines contract definition and implementation
- Compatible with WASM Component Model

### World Keyword Alternative

The `world` keyword can be used in place of `component` if more comfortable:

```novo
world http-proxy {
    export wasi:http/incoming-handler
    import wasi:http/outgoing-handler
}
```

> In WASM they define the contract and implementation respectively, however in novo both contract and implementation are defined together.

## Component Sandboxing

A component cannot interact with anything outside itself except by having its exports called, or by it calling its imports. This provides very strong sandboxing.

For example, if a component does not have an import for a secret store, then it cannot access that secret store, even if the store is running in the same process.

```novo
component secure-processor {
    // This component can only access what it explicitly imports
    import wasi:filesystem/types.{descriptor}
    import logging

    // Cannot access network, secrets, or other system resources
    export func process-file(path: string) -> result<string, error>
}
```

## Import and Export Patterns

### Package/Name Syntax

You can import and export interfaces defined in other packages using package/name syntax:

```novo
component http-proxy {
    export wasi:http/incoming-handler
    import wasi:http/outgoing-handler
    import wasi:filesystem/types
}
```

### Granular Imports and Exports

Following WIT specification patterns, novo supports granular imports and exports:

```novo
component example {
    // Import entire interface
    import wasi:filesystem/types

    // Import specific types from interface
    import wasi:filesystem/types.{descriptor, error-code}

    // Export entire interface
    export storage

    // Export subset of interface functions
    export storage.{get, set}       // Only export get and set functions

    // Export individual functions
    export func process-data(input: string) -> result<string, error>
}
```

Interface and function-level granularity is supported, allowing fine-grained control over component boundaries while maintaining WIT compatibility.

## Component Composition

### Include Statement

You can `include` another world. This causes your world to export all that world's exports, and import all that world's imports:

```novo
world glow-in-the-dark-multi-function-device {
    // The component provides all the same exports, and depends on
    // all the same imports, as a `multi-function-device`...
    include multi-function-device

    // ...but also exports a function to make it glow in the dark
    export func glow(brightness: u8) {
        // implementation
    }
}
```

### Naming Conflicts

When using `include` to compose components, naming conflicts result in compilation errors:

```novo
component base {
    export func process() { /* implementation */ }
}

component extended {
    export func process() { /* different implementation */ }
}

component combined {
    include base      // Exports process()
    include extended  // Error: naming conflict for process()
}
```

**Current behavior:** Naming collisions during component inclusion are compilation errors. Future language iterations may define conflict resolution strategies.

## Use Statements and Imports

The `use` statement creates locally scoped references to imported types and functions:

```novo
use types.{request, response}
// Equivalent to declaring:
// request := types.request
// response := types.response
```

This brings the specified types into the current scope as if they were locally declared variables.

### Use Statement Examples

```novo
interface http-types {
    record request { /* ... */ }
    record response { /* ... */ }
    enum method { get, post, put, delete }
}

component http-server {
    import http-types
    use http-types.{request, response, method}

    export func handle(req: request) -> response {
        match req.method {
            get => handle-get(req)
            post => handle-post(req)
            // ...
        }
    }
}
```

## Interface Implementation

Interface implementation follows WIT specification patterns, adapted for consistency with novo function syntax:

```novo
interface storage {
    func get(key: string) -> option<string>
    func set(key: string, value: string) -> result
}

// Implementation
component my-storage {
    export storage

    func get(key: string) -> option<string> {
        // implementation
    }

    func set(key: string, value: string) -> result {
        // implementation
    }
}
```

## Component Entry Points

Components require well-defined entry points for proper integration with WASM runtimes:

### Main Entry Point

The `_start` function serves as the primary entry point:

```novo
component example {
    // Main entry point (exception to identifier naming rules)
    func _start() {
        // Component initialization logic
        initialize-subsystems()
        setup-resources()
    }

    // Regular exported functions
    export func process-data(input: string) -> result<string, error>
    export func cleanup() -> result
}
```

**Entry point characteristics:**
- `_start` is the **only exception** to novo's kebab-case identifier naming rules
- Called automatically by WASM runtime during component instantiation
- Used for component initialization, resource setup, and configuration
- Optional - components without `_start` are initialized with default behavior

### Multiple Entry Points

Components can export multiple functions as entry points:

```novo
component web-server {
    func _start() {
        // Main initialization
    }

    // Multiple public entry points
    export func handle-request(req: http-request) -> http-response
    export func shutdown() -> result
    export func reload-config() -> result
}
```

## WASI Integration

Novo components can import and export worlds defined by other WASM components, for example any of the WASI (the WebAssembly System Interface) components:

```novo
component file-processor {
    import wasi:filesystem/types.{descriptor, error-code}
    import wasi:filesystem/preopens.{get-directories}
    import wasi:io/streams.{input-stream, output-stream}

    export func process-files() -> result {
        directories := get-directories()
        for dir in directories {
            process-directory(dir)
        }
        return ok()
    }
}
```

## Cross-References

- See [Basic Types](basic-types.md) for fundamental type definitions used in interfaces
- See [Complex Types](complex-types.md) for records, variants, and other interface types
- See [Functions and Control Flow](functions-control-flow.md) for function definition syntax
- See [WAT Compatibility](wat-compatibility.md) for WASM integration details
