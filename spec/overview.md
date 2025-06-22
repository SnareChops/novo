# Novo Language Overview

Novo is a WASM-targeted language designed to directly interface with the WebAssembly Component Model. It provides an alternative way to create WASM components while maintaining full compatibility with existing WASM ecosystems.

## Goals

1. **WIT-Driven Design**: All types and concepts are directly driven from the WIT specification
2. **WAT Instruction Compatibility**: Retain the ability to write raw WASM instructions following WAT conventions while implementing them through novo constructs
3. **Transparent Memory Management**: Follow normal WASM conventions including stack usage without hiding implementation details from developers
4. **Developer Control**: Language usage should reflect stack behavior and provide direct access to underlying WebAssembly mechanics

## Key Features

- **Component Model Native**: Direct support for WASM Component Model interfaces and worlds
- **Type Safety**: Comprehensive type system based on WIT specifications
- **Pattern Matching**: Powerful pattern matching for variant types, options, and results
- **Meta Functions**: Built-in meta function system for type introspection and operations
- **WAT Compatibility**: Syntactic compatibility with WebAssembly Text Format instructions
- **Resource Management**: Explicit resource lifecycle management with automatic cleanup

## Language Philosophy

Novo prioritizes developer understanding and control over automatic optimization. The language exposes the underlying WebAssembly stack-based execution model while providing ergonomic syntax for common operations. This approach ensures predictable performance and enables developers to write performance-critical code when needed.

## Compilation Output

Novo components compile to:
- **Primary Output**: Binary `.wasm` files for execution in any WASM runtime
- **Interface Output**: `.wit` interface files for component interoperability
- **Future Features**: Optional `.wat` text format output for debugging and inspection

## Getting Started

For detailed information on specific language features, see:
- [Basic Types and Syntax](basic-types.md)
- [Complex Types](complex-types.md)
- [Functions and Control Flow](functions-control-flow.md)
- [Pattern Matching](pattern-matching.md)
- [Components and Interfaces](components-interfaces.md)
