# WAT to WASM Compiler Specification

## Project Overview

This specification defines a WebAssembly Text Format (.wat) to WebAssembly Binary Format (.wasm) compiler that is itself implemented in WebAssembly Text Format. This meta-compiler demonstrates the self-hosting capabilities of WebAssembly and provides a lightweight, embeddable compiler for .wat files.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Input/Output Specification](#inputoutput-specification)
- [Lexical Analysis](#lexical-analysis)
- [Parsing](#parsing)
- [Code Generation](#code-generation)
- [Memory Layout](#memory-layout)
- [Error Handling](#error-handling)
- [Performance Requirements](#performance-requirements)
- [API Interface](#api-interface)
- [Testing Requirements](#testing-requirements)
- [Implementation Phases](#implementation-phases)

## Architecture Overview

### High-Level Design

The compiler follows a traditional multi-pass architecture:

```
WAT Source → Lexer → Parser → AST → Code Generator → WASM Binary
```

### Core Components

1. **Lexical Analyzer (Lexer)**
   - Tokenizes WAT source code
   - Handles S-expressions, identifiers, literals, and keywords
   - Provides error recovery and position tracking

2. **Parser**
   - Builds Abstract Syntax Tree (AST) from token stream
   - Validates syntax according to WAT grammar
   - Handles nested S-expressions and type checking

3. **Code Generator**
   - Traverses AST to generate WASM binary format
   - Handles instruction encoding and section generation
   - Optimizes output size and structure

4. **Memory Manager**
   - Manages compiler internal data structures
   - Handles string interning and symbol tables
   - Provides garbage collection for temporary objects

## Input/Output Specification

### Input Format

- **Source**: Valid WebAssembly Text Format (.wat) files
- **Encoding**: UTF-8 text
- **Size Limit**: Maximum 1MB source file (configurable)
- **Features**: WebAssembly 1.0 core specification + selected 2.0 features

### Output Format

- **Target**: WebAssembly Component Model Binary Format (.wasm)
- **Version**: WebAssembly Component Model 1.0 compatible
- **Optimization**: Size-optimized output with optional debug information
- **Validation**: Self-validating output format in accordance with Component Model specification
- **Interface**: Generates component interface types and canonical ABI adapters
- **Exports**: All modules are wrapped as components with explicit interfaces

### Supported WAT Features

#### Core Features (Phase 1)
- Component structure (`component`, `interface`, `world`, `export`, `import`)
- Interface types and canonical ABI
- Basic data types (`string`, `record`, `variant`, `list`, `option`, plus core wasm types)
- Component imports and exports
- Resource types and management
- Function interface types
- Local and global state management
- Component instantiation and linking

#### Extended Features (Phase 2)
- Tables and references
- Multiple memories
- SIMD instructions (if supported by target)
- Exception handling
- Bulk memory operations

#### Advanced Features (Phase 3)
- Custom sections
- Name section generation
- Source maps
- Optimization passes

## Lexical Analysis

### Token Types

```wat
;; Token enumeration
(global $TOKEN_LPAREN i32 (i32.const 1))
(global $TOKEN_RPAREN i32 (i32.const 2))
(global $TOKEN_IDENTIFIER i32 (i32.const 3))
(global $TOKEN_KEYWORD i32 (i32.const 4))
(global $TOKEN_INTEGER i32 (i32.const 5))
(global $TOKEN_FLOAT i32 (i32.const 6))
(global $TOKEN_STRING i32 (i32.const 7))
(global $TOKEN_EOF i32 (i32.const 8))
(global $TOKEN_ERROR i32 (i32.const 9))
```

### Component-Specific Token Types

```wat
;; Component-related token types
(global $TOKEN_COMPONENT i32 (i32.const 10))
(global $TOKEN_INTERFACE i32 (i32.const 11))
(global $TOKEN_WORLD i32 (i32.const 12))
(global $TOKEN_RESOURCE i32 (i32.const 13))
(global $TOKEN_VARIANT i32 (i32.const 14))
(global $TOKEN_RECORD i32 (i32.const 15))
(global $TOKEN_FLAGS i32 (i32.const 16))
(global $TOKEN_ENUM i32 (i32.const 17))
(global $TOKEN_USE i32 (i32.const 18))
(global $TOKEN_TYPE i32 (i32.const 19))

;; Component-specific keywords (in keywords.wat)
(data (i32.const 0x4100)
  "component\00"    ;; 0x4100
  "interface\00"    ;; 0x410A
  "world\00"        ;; 0x4114
  "resource\00"     ;; 0x411A
  "variant\00"      ;; 0x4123
  "record\00"       ;; 0x412B
  "flags\00"        ;; 0x4132
  "enum\00"         ;; 0x4138
  "use\00"          ;; 0x413D
  "type\00"         ;; 0x4142
)
```

### Lexer State Machine

The lexer implements a finite state automaton with states for:
- Initial state
- Identifier scanning
- Number parsing (integer/float)
- String literal processing
- Comment handling (`;; line comments`)
- Block comment processing `(; block comments ;)`

### Character Classification

```wat
;; Character type checking functions
(func $is_whitespace (param $char i32) (result i32)
  ;; Returns 1 if character is whitespace, 0 otherwise
)

(func $is_alpha (param $char i32) (result i32)
  ;; Returns 1 if character is alphabetic, 0 otherwise
)

(func $is_digit (param $char i32) (result i32)
  ;; Returns 1 if character is numeric, 0 otherwise
)

(func $is_identifier_char (param $char i32) (result i32)
  ;; Returns 1 if character is valid in identifier, 0 otherwise
)
```

## Parsing

### Grammar Definition

The parser implements the official WebAssembly Text Format grammar using recursive descent parsing.

### AST Node Types

```wat
;; AST Node type enumeration
(global $AST_MODULE i32 (i32.const 10))
(global $AST_COMPONENT i32 (i32.const 11))
(global $AST_INTERFACE i32 (i32.const 12))
(global $AST_WORLD i32 (i32.const 13))
(global $AST_FUNC i32 (i32.const 14))
(global $AST_PARAM i32 (i32.const 15))
(global $AST_RESULT i32 (i32.const 16))
(global $AST_LOCAL i32 (i32.const 17))
(global $AST_INSTR i32 (i32.const 18))
(global $AST_BLOCK i32 (i32.const 19))
(global $AST_LOOP i32 (i32.const 20))
(global $AST_IF i32 (i32.const 21))
(global $AST_RESOURCE i32 (i32.const 22))
(global $AST_VARIANT i32 (i32.const 23))
(global $AST_RECORD i32 (i32.const 24))
(global $AST_FLAGS i32 (i32.const 25))
(global $AST_ENUM i32 (i32.const 26))
(global $AST_IMPORT i32 (i32.const 27))
(global $AST_EXPORT i32 (i32.const 28))
(global $AST_TYPE i32 (i32.const 29))
```

### AST Node Structure

Each AST node contains:
- Node type (4 bytes)
- Parent pointer (4 bytes)
- First child pointer (4 bytes)
- Next sibling pointer (4 bytes)
- Node-specific data (variable size)

### Parsing Functions

```wat
;; Main parsing entry points
(func $parse_module (param $tokens_ptr i32) (result i32)
  ;; Returns pointer to module AST node or 0 on error
)

(func $parse_component (param $tokens_ptr i32) (result i32)
  ;; Returns pointer to component AST node or 0 on error
)

;; Parse individual constructs
(func $parse_function (param $parser_state i32) (result i32))
(func $parse_interface (param $parser_state i32) (result i32))
(func $parse_world (param $parser_state i32) (result i32))
(func $parse_resource (param $parser_state i32) (result i32))
(func $parse_type (param $parser_state i32) (result i32))
(func $parse_variant (param $parser_state i32) (result i32))
(func $parse_record (param $parser_state i32) (result i32))
(func $parse_flags (param $parser_state i32) (result i32))
(func $parse_enum (param $parser_state i32) (result i32))
(func $parse_instruction (param $parser_state i32) (result i32))
(func $parse_expression (param $parser_state i32) (result i32))
```

## Code Generation

### Binary Format Structure

The code generator produces either core WebAssembly modules or WebAssembly components following their respective specifications:

1. **Core Module Format**:
   - Magic Number: `0x00 0x61 0x73 0x6D`
   - Version: `0x01 0x00 0x00 0x00`
   - Core Sections: Type, Import, Function, Table, Memory, Global, Export, Start, Element, Code, Data, Custom

2. **Component Format**:
   - Magic Number: `0x00 0x63 0x6D 0x70`
   - Version: `0x01 0x00 0x00 0x00`
   - Component Sections:
     - Component Types
     - Core Module Instances
     - Component Imports/Exports
     - Component Runtime Types
     - Component Resource Management
     - Canonical Functions
     - Interface Types

### Section Generation

```wat
;; Section type enumeration
(global $SECTION_TYPE i32 (i32.const 1))
(global $SECTION_IMPORT i32 (i32.const 2))
(global $SECTION_FUNCTION i32 (i32.const 3))
(global $SECTION_TABLE i32 (i32.const 4))
(global $SECTION_MEMORY i32 (i32.const 5))
(global $SECTION_GLOBAL i32 (i32.const 6))
(global $SECTION_EXPORT i32 (i32.const 7))
(global $SECTION_START i32 (i32.const 8))
(global $SECTION_ELEMENT i32 (i32.const 9))
(global $SECTION_CODE i32 (i32.const 10))
(global $SECTION_DATA i32 (i32.const 11))
```

### Instruction Encoding

The compiler maps WAT instructions to their binary opcodes:

```wat
;; Instruction opcode mapping
(global $OP_UNREACHABLE i32 (i32.const 0x00))
(global $OP_NOP i32 (i32.const 0x01))
(global $OP_BLOCK i32 (i32.const 0x02))
(global $OP_LOOP i32 (i32.const 0x03))
(global $OP_IF i32 (i32.const 0x04))
(global $OP_ELSE i32 (i32.const 0x05))
;; ... additional opcodes
```

## Memory Layout

### Compiler Memory Organization

```
Memory Layout (64KB initial, growable):
0x0000 - 0x0FFF: Compiler runtime and stack
0x1000 - 0x2FFF: Token buffer and lexer state
0x3000 - 0x7FFF: AST nodes and parser state
0x8000 - 0xBFFF: Symbol table and string pool
0xC000 - 0xEFFF: Output buffer for WASM binary
0xF000 - 0xFFFF: Error handling and debugging info
```

### Data Structures

```wat
;; Token structure (16 bytes)
;; [type:4][value_ptr:4][length:4][line:2][column:2]

;; AST Node structure (20+ bytes)
;; [type:4][parent:4][first_child:4][next_sibling:4][data:variable]

;; Symbol table entry (16 bytes)
;; [name_ptr:4][name_len:4][type:4][value:4]
```

## Error Handling

### Error Types

```wat
;; Error code enumeration
(global $ERROR_NONE i32 (i32.const 0))
(global $ERROR_LEXICAL i32 (i32.const 1))
(global $ERROR_SYNTAX i32 (i32.const 2))
(global $ERROR_SEMANTIC i32 (i32.const 3))
(global $ERROR_MEMORY i32 (i32.const 4))
(global $ERROR_INTERNAL i32 (i32.const 5))
```

### Error Recovery

- **Lexical Errors**: Skip invalid characters, continue tokenization
- **Syntax Errors**: Panic mode recovery to next synchronization point
- **Semantic Errors**: Continue compilation, collect multiple errors
- **Memory Errors**: Graceful degradation with error reporting

### Error Reporting Format

```wat
;; Error structure (24 bytes)
;; [error_code:4][line:4][column:4][message_ptr:4][message_len:4][next_error:4]
```

## Performance Requirements

### Compilation Speed
- **Target**: < 100ms for typical WAT files (< 10KB)
- **Memory**: Maximum 1MB working memory
- **Throughput**: > 100KB/s source processing rate

### Output Quality
- **Size**: Generated WASM should be within 5% of reference compilers
- **Correctness**: 100% compatibility with WAT specification
- **Validation**: Self-validating output format

## API Interface

### Main Compilation Function

```wat
;; Primary compiler entry points
;; @param source_ptr: Pointer to WAT source text
;; @param source_len: Length of source text in bytes
;; @param output_ptr: Pointer to output buffer
;; @param output_len: Maximum output buffer size
;; @param options: Compilation options (includes target format)
;; @returns: Number of bytes written, or negative error code
(func $compile_wat_to_wasm
  (param $source_ptr i32)
  (param $source_len i32)
  (param $output_ptr i32)
  (param $output_len i32)
  (param $options i32)
  (result i32)
  (export "compile")
)

;; Options flags
(global $COMPILE_OPTION_CORE_MODULE i32 (i32.const 1))    ;; Generate core module
(global $COMPILE_OPTION_COMPONENT i32 (i32.const 2))      ;; Generate component
(global $COMPILE_OPTION_AUTO_DETECT i32 (i32.const 4))    ;; Auto-detect from source
(global $COMPILE_OPTION_INTERFACE_TYPES i32 (i32.const 8));; Include interface types
```

### Utility Functions

```wat
;; Get last error information
(func $get_last_error (result i32) (export "get_last_error"))

;; Get compiler version
(func $get_version (result i32) (export "get_version"))

;; Reset compiler state
(func $reset_compiler (export "reset"))

;; Set compilation options
(func $set_options (param $options i32) (export "set_options"))
```

### JavaScript Integration

```javascript
// Example usage from JavaScript
const wasmModule = await WebAssembly.instantiateStreaming(
  fetch('wat-compiler.wasm')
);

function compileWat(watSource) {
  const encoder = new TextEncoder();
  const sourceBytes = encoder.encode(watSource);

  // Allocate memory for source and output
  const sourcePtr = wasmModule.instance.exports.alloc(sourceBytes.length);
  const outputPtr = wasmModule.instance.exports.alloc(65536); // 64KB output buffer

  // Copy source to WASM memory
  const memory = new Uint8Array(wasmModule.instance.exports.memory.buffer);
  memory.set(sourceBytes, sourcePtr);

  // Compile
  const result = wasmModule.instance.exports.compile(
    sourcePtr, sourceBytes.length, outputPtr, 65536
  );

  if (result < 0) {
    throw new Error(`Compilation failed with error code: ${result}`);
  }

  // Extract compiled WASM
  return memory.slice(outputPtr, outputPtr + result);
}
```

## Testing Requirements

### Unit Tests
- Lexer token recognition accuracy
- Parser AST generation correctness
- Code generator binary format compliance
- Memory management leak detection

### Integration Tests
- Complete WAT file compilation
- Error handling and recovery
- Performance benchmarks
- Cross-platform compatibility

### Validation Tests
- Output WASM validation using wabt
- Comparison with reference implementations
- Edge case handling
- Large file processing

### Test WAT Examples

```wat
;; Simple test case
(module
  (func $add (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.add
  )
  (export "add" (func $add))
)
```

## Implementation Phases

### Phase 1: Core Compiler (Weeks 1-4)
- Basic lexer implementation
- Simple recursive descent parser
- Minimal code generator for core instructions
- Basic memory management

### Phase 2: Complete WAT Support (Weeks 5-8)
- Full WAT grammar support
- All instruction types
- Import/export handling
- Error recovery and reporting

### Phase 3: Optimization and Polish (Weeks 9-12)
- Performance optimization
- Memory usage improvements
- Comprehensive testing
- Documentation and examples

### Phase 4: Advanced Features (Weeks 13-16)
- WASM 2.0 feature support
- Custom sections
- Debug information generation
- Integration tools and utilities

## File Structure

```
src/
├── lexer.wat          # Lexical analysis implementation
├── parser.wat         # Parser and AST generation
├── codegen.wat        # Code generation and binary output
├── memory.wat         # Memory management utilities
├── errors.wat         # Error handling and reporting
├── main.wat           # Main compiler entry point
└── utils.wat          # Utility functions and helpers

tests/
├── unit/              # Unit test WAT files
├── integration/       # Full compilation tests
├── examples/          # Example WAT files for testing
└── benchmarks/        # Performance test cases

tools/
├── build.sh           # Build script for compiler
├── test.sh            # Test runner script
└── validate.js        # Output validation utilities

docs/
├── API.md             # API documentation
├── EXAMPLES.md        # Usage examples
└── PERFORMANCE.md     # Performance analysis
```

## Dependencies

### Build Dependencies
- `wat2wasm` (WABT) for compiling the compiler itself
- `wasm-validate` for output validation
- Node.js for JavaScript integration testing

### Runtime Dependencies
- WebAssembly runtime environment (browser, Node.js, or standalone)
- Minimum 1MB available memory
- WebAssembly 1.0 support required

## Success Criteria

1. **Functionality**: Successfully compiles all valid WAT input according to specification
2. **Performance**: Meets or exceeds performance requirements
3. **Reliability**: Handles all error conditions gracefully
4. **Compatibility**: Output validates and runs on all major WASM runtimes
5. **Maintainability**: Code is well-documented and testable
6. **Self-hosting**: Compiler can compile itself (meta-compilation)

## Future Enhancements

- Advanced component composition patterns
- Multi-language component bindings generation
- Component-model aware optimization passes
- IDE integration and language server protocol
- Browser-based compilation service
- Incremental compilation support
- WASI integration with component model adapters

---

*This specification is a living document and will be updated as the implementation progresses and requirements evolve.*

## WebAssembly Component Model Implementation

The compiler generates WebAssembly components following the Component Model specification:

1. **Component Structure**
   - Each module is compiled into a component
   - Interfaces are explicitly defined using the component interface type system
   - Imports and exports follow canonical ABI conventions
   - Resource types are properly managed and isolated

2. **Interface Types**
   - Generates interface definitions in wit format
   - Supports all component model types including handles, resources, and variants
   - Automatically converts between core and interface types
   - Implements canonical ABI lifting and lowering

3. **Component Linking**
   - Supports component imports with version constraints
   - Enables composition of multiple components
   - Handles component instantiation requirements
   - Manages resource scoping and cleanup

4. **Component ABI**
   - Implements the canonical ABI for function calls
   - Handles memory management according to component specifications
   - Supports bidirectional interface type conversions
   - Manages component instance lifecycles
