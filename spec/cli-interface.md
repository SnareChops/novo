# Novo Compiler CLI Interface

This document specifies the command-line interface for the Novo compiler, including WASI integration for file system operations and console output.

## Overview

The Novo compiler provides a command-line interface for compiling Novo source files to WebAssembly targets. The compiler is implemented as a WebAssembly component using WASI (WebAssembly System Interface) for secure, portable file system and console operations.

## WASI Integration

### Components Used

The Novo compiler integrates the following WASI components:

- **WASI CLI (wasi:cli@0.2.6)**: Command-line interface with stdout/stderr streams
- **WASI I/O (wasi:io@0.2.6)**: Stream abstractions for console output and file I/O
- **WASI Filesystem (wasi:filesystem@0.2.6)**: Capability-based file system operations

### Component World Definition

```wit
package novo:compiler@1.0.0

world novo-compiler {
    // Import WASI capabilities
    import wasi:filesystem/types@0.2.6
    import wasi:filesystem/preopens@0.2.6
    import wasi:cli/stdout@0.2.6
    import wasi:cli/stderr@0.2.6
    import wasi:cli/environment@0.2.6
    import wasi:cli/exit@0.2.6

    // Export compiler commands
    export compile: func(source-path: string, output-path: string) -> result<_, string>
    export wit: func(source-path: string, output-path: string) -> result<_, string>

    // Future feature exports
    // export wat: func(source-path: string, output-path: string) -> result<_, string>
}
```

## Command Structure

The Novo compiler provides commands for different compilation targets, with binary WASM as the primary output format:

### `novo compile`

Compiles Novo source files to WebAssembly binary format (.wasm).

**Syntax:**
```bash
novo compile <source-file> <output-file>
```

**Arguments:**
- `<source-file>`: Path to the main Novo source file (entry point)
- `<output-file>`: Path where the compiled .wasm file will be written

**Example:**
```bash
novo compile src/main.no build/main.wasm
```

**Note**: This is the primary compilation target for Novo, producing executable WebAssembly binary files.

### `novo wat` (Future Feature)

*Note: This feature is planned for future implementation as a debugging and inspection tool.*

Compiles Novo source files to WebAssembly text format (.wat).

**Syntax:**
```bash
novo wat <source-file> <output-file>
```

**Arguments:**
- `<source-file>`: Path to the main Novo source file (entry point)
- `<output-file>`: Path where the compiled .wat file will be written

**Example:**
```bash
novo wat src/main.no build/main.wat
```

**Status**: This command will be implemented in a future release to provide human-readable WAT output for debugging purposes.

### `novo compile-wit`

Generates WebAssembly Interface Type (.wit) files from Novo component definitions.

**Syntax:**
```bash
novo wit <source-file> <output-file>
```

**Arguments:**
- `<source-file>`: Path to the main Novo source file (entry point)
- `<output-file>`: Path where the generated .wit file will be written

**Example:**
```bash
novo wit src/main.no build/main.wit
```

## Multi-file Compilation

### Import Resolution

The compiler discovers and includes all referenced files through the import system:

1. **Entry Point**: Compilation starts with the specified main source file
2. **Import Discovery**: The compiler parses import statements in the main file
3. **Recursive Resolution**: Imported files are recursively parsed for their imports
4. **Relative Paths**: All import paths are resolved relative to the importing file's directory
5. **Dependency Graph**: A complete dependency graph is built before compilation begins

### File Discovery Process

```
main.no
├── import "./utils/helpers.no"     → resolves to src/utils/helpers.no
├── import "../shared/types.no"     → resolves to shared/types.no
└── utils/helpers.no
    └── import "./math.no"          → resolves to src/utils/math.no
```

## File System Operations

### WASI Filesystem Integration

The compiler uses WASI filesystem operations for secure, sandboxed file access:

**Read Operations:**
- Source file reading using `descriptor.read-via-stream()`
- Import resolution using `descriptor.openat()` with relative paths
- UTF-8 text decoding for source file contents

**Write Operations:**
- Output file creation using `descriptor.openat()` with create flags
- Binary or text output using `descriptor.write-via-stream()`
- Atomic write operations with proper error handling

**Permissions:**
- **Source directories**: Read-only access for discovering and reading source files
- **Output location**: Write access for creating compiled output files
- **Sandboxing**: Access limited to explicitly granted directory permissions

### File System Security

Following WASI capability-based security model:

```novo
// Example WASI filesystem usage in compiler
func compile-source(source-path: string, output-path: string) -> result {
    // Open source file for reading
    source-dir := get-directory-from-path(source-path)
    source-file := source-dir.openat(
        at-flags: { follow-symlinks },
        path: get-filename(source-path),
        o-flags: {},
        descriptor-flags: { read },
        mode: {}
    )?

    // Read source content
    content := read-file-content(source-file)?

    // Compile (existing compiler logic)
    compiled := compile-novo(content, source-dir)?

    // Write output
    output-dir := get-directory-from-path(output-path)
    output-file := output-dir.openat(
        at-flags: { follow-symlinks },
        path: get-filename(output-path),
        o-flags: { create, truncate },
        descriptor-flags: { write },
        mode: { readable, writable }
    )?

    write-file-content(output-file, compiled)?

    return ok()
}
```

## Console Output

### WASI CLI Integration

Console output uses WASI CLI streams for portable, standards-compliant output:

**Standard Output (stdout):**
- Compilation success messages
- General information and status

**Standard Error (stderr):**
- Error messages and diagnostics
- Warning messages

### Output Implementation

```novo
// Console output functions using WASI CLI
func print-message(message: string) {
    stdout := wasi:cli/stdout.get-stdout()
    bytes := message.encode-utf8()
    stdout.blocking-write-and-flush(bytes)
}

func print-error(error: string) {
    stderr := wasi:cli/stderr.get-stderr()
    bytes := error.encode-utf8()
    stderr.blocking-write-and-flush(bytes)
}
```

## Error Handling and Reporting

### Error Message Format

Error messages provide detailed information about compilation failures:

**Structure:**
```
Error: <error-type>
  --> <file-path>:<line>:<column>
   |
<line-num> | <source-line-content>
   |         <error-indicator>
   |
   = <detailed-explanation>
   = help: <suggestion-if-applicable>
```

**Example:**
```
Error: Type mismatch
  --> src/utils/math.no:15:8
   |
15 |     let result: u32 = calculate("invalid")
   |                      ^^^^^^^^^^^^^^^^^^^
   |
   = Expected u32, found string
   = help: Convert the string to a number or change the variable type
```

### Error Context

- **File Location**: Exact file path where error occurred
- **Position**: Line and column numbers (1-indexed)
- **Source Context**: Relevant source code lines with error highlighting
- **Error Details**: Clear explanation of what went wrong
- **Suggestions**: Helpful hints for common issues when applicable

### Multi-file Error Handling

When errors occur in imported files:

1. **Error Location**: Reports the exact location in the imported file where the error occurred
2. **No Import Chain**: Focus on the actual error location, not the import path
3. **File Context**: Provides source context from the file containing the error

## Exit Codes

The compiler follows standard Unix exit code conventions:

- **0**: Successful compilation
- **1**: Compilation errors (syntax, type errors, etc.)
- **2**: Invalid command-line arguments
- **3**: File system errors (file not found, permission denied, etc.)
- **4**: Internal compiler errors

## Usage Examples

### Basic Compilation

```bash
# Compile to WebAssembly binary
novo compile src/main.no build/main.wasm

# Compile to WebAssembly text format
novo wat src/main.no debug/main.wat

# Generate WIT interface definitions
novo wit src/api.no interfaces/api.wit
```

### File Organization

```
project/
├── src/
│   ├── main.no              # Entry point
│   ├── utils/
│   │   ├── helpers.no       # Imported by main.no
│   │   └── math.no          # Imported by helpers.no
│   └── types/
│       └── common.no        # Imported by multiple files
├── build/                   # Output directory
└── interfaces/              # WIT output directory
```

### Compilation Commands

```bash
# From project root
novo compile src/main.no build/main.wasm
novo wat src/main.no build/debug.wat
novo wit src/main.no interfaces/main.wit
```

## Runtime Environment

### Wasmtime Integration

The compiler is designed to run in Wasmtime with appropriate WASI permissions:

```bash
# Run with filesystem access to current directory
wasmtime run \
  --dir=. \
  --wasi-modules=experimental-wasi-cli \
  novo-compiler.wasm \
  compile src/main.no build/main.wasm
```

### Browser Compatibility

The WASI-based design ensures future browser compatibility:

- **Virtual File Systems**: Works with WASI-compliant virtual file systems
- **Sandboxed Execution**: Natural fit for browser security models
- **Portable Interface**: Same API across all WASI-compliant runtimes

## Future Features

Features planned for future releases:

### Watch Mode
```bash
novo watch src/main.no build/main.wasm  # Recompile on file changes
```

### Debug Output
```bash
novo compile src/main.no build/main.wasm --debug-info  # Include debug symbols
novo compile src/main.no build/main.wasm --emit-ast    # Generate AST dump
```

### Optimization Levels
```bash
novo compile src/main.no build/main.wasm --optimize=release
novo compile src/main.no build/main.wasm --optimize=debug
```

## Implementation Notes

### WASI Compliance

The compiler implementation strictly follows WASI specifications:

- Uses only standardized WASI interfaces (no runtime-specific extensions)
- Implements proper error handling for all WASI operations
- Follows capability-based security model for file system access
- Uses UTF-8 encoding for all text operations

### Performance Considerations

- **Lazy Loading**: Import files are loaded only when needed
- **Efficient I/O**: Uses streaming operations for large files
- **Memory Management**: Minimizes memory usage during compilation
- **Error Fast**: Fails quickly on the first error encountered

### Cross-Platform Compatibility

The WASI foundation ensures the compiler works identically across:

- **Operating Systems**: Windows, macOS, Linux
- **Architectures**: x86_64, ARM64, others supported by WASI runtimes
- **Runtimes**: Wasmtime, WAMR, WasmEdge, and other WASI-compliant runtimes
