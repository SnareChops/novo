# GitHub Copilot Instructions for WebAssembly Text Format (.wat) Project

## Project Overview
This is a WebAssembly Text Format (.wat) project that compiles to WebAssembly binary format (.wasm) for execution in web browsers, Node.js, or other WebAssembly runtimes. While the compiler supports the WebAssembly Component Model, our implementation currently uses core WebAssembly syntax due to tooling limitations.

### Component Model Support
- .wit files define component interfaces that document our module boundaries
- Implementation uses core WebAssembly modules (.wat files)
- Runtime linking handled through explicit imports/exports
- Component composition handled by the host environment

### Implementation Guidelines
- Use core WebAssembly syntax in .wat files
- Follow interface definitions in .wit files for module boundaries
- Maintain clear separation between modules
- Document component relationships in comments

## Code Style and Conventions

### WebAssembly Text Format (.wat)
- Use consistent indentation (2 spaces recommended)
- Add meaningful comments to explain complex operations
- Use descriptive names for functions, locals, and globals
- Group related functions together
- Document memory layout and data structures in comments

### Function Naming
- Use snake_case for function names (e.g., `calculate_fibonacci`, `process_array`)
- Prefix exported functions with descriptive names
- Use clear parameter and return type annotations

### File Organization
- Files exceeding 300 lines of code should be considered for refactoring into smaller files
- Keep related functionality together when splitting files
- Maintain clear module boundaries and logical separation
- This is a guideline, not a hard requirement, but should always be evaluated as files grow

### Memory Management
- Document memory regions and their purposes
- Use consistent patterns for memory allocation/deallocation
- Comment on memory alignment requirements
- Clearly mark shared vs. local memory usage

## WebAssembly Specific Guidelines

### Module Structure
- Always include module declaration: `(module ...)`
- Group imports at the top of the module
- Follow with type definitions, then functions, memory, and exports
- Use meaningful section comments

### Type Definitions
- Define function types explicitly when used multiple times
- Use descriptive type names
- Document complex type signatures

### Import/Export Patterns
- Clearly document all imports and their expected behavior
- Export functions with intuitive names for JavaScript interop
- Include type annotations for better tooling support

### Performance Considerations
- Prefer local variables over globals when possible
- Use appropriate numeric types (i32, i64, f32, f64)
- Comment on performance-critical sections
- Consider SIMD instructions for parallel operations when appropriate

## Build and Testing

### Build Tools
- Use `wasmtime` for compilation
- Include optimization flags in comments
- Document any custom build scripts or configurations

### Testing Patterns
- Test WebAssembly modules using `wasmtime`
- Include performance benchmarks for critical functions
- Test edge cases for numeric operations (overflow, underflow, NaN)
- Validate memory bounds and safety

## JavaScript/WebAssembly Interop

### Data Exchange
- Document data serialization/deserialization patterns
- Use consistent patterns for passing complex data structures
- Handle string encoding/decoding explicitly
- Comment on endianness considerations

### Error Handling
- Use WebAssembly traps appropriately
- Document error conditions and recovery strategies
- Provide meaningful error messages through imports

## Documentation Standards

### Inline Comments
- Explain the purpose of each function at the beginning
- Document complex arithmetic or bit manipulation
- Explain memory layout decisions
- Note any WebAssembly-specific optimizations

### Function Documentation
```wat
;; Calculates the nth Fibonacci number using iterative approach
;; @param n: i32 - The position in Fibonacci sequence (0-indexed)
;; @returns i32 - The Fibonacci number at position n
;; @note Handles overflow by wrapping (i32 arithmetic)
(func $fibonacci (param $n i32) (result i32)
  ;; implementation here
)
```

## Security Considerations
- Validate all imported function parameters
- Implement bounds checking for memory access
- Document any unsafe operations clearly
- Consider side-channel attack implications for cryptographic code

## Optimization Guidelines
- Profile memory access patterns
- Use local variables to reduce stack operations
- Consider loop unrolling for small, fixed iterations
- Document any manual optimizations and their trade-offs
- Prefer WebAssembly native operations over emulated ones

## Browser Compatibility
- Document minimum WebAssembly version requirements
- Note any experimental features used
- Test across different JavaScript engines
- Consider polyfills for older environments

## Development Workflow
- Use `.wat` files as source of truth
- Keep `.wasm` files in version control only if necessary
- Include build instructions in README
- Set up continuous integration for multiple platforms

## Common Patterns to Follow
- Initialize memory regions explicitly
- Use consistent error handling patterns
- Implement graceful degradation for optional features
- Follow WASI conventions when applicable
- Use standard WebAssembly calling conventions

## Code Review Guidelines
- Verify memory safety in all operations
- Check for proper resource cleanup
- Validate numeric operation safety
- Ensure consistent coding style
- Review performance implications of changes
