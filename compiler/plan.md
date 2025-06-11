# Novo Compiler Implementation Plan

This document outlines a step-by-step implementation plan for the Novo programming language compiler. The implementation will be done in WebAssembly Text Format (WAT) to bootstrap the language until it can self-host.

## Implementation Scope

**INCLUDED** (Core Novo Features):
- WIT-compliant type system (primitives, lists, options, results, tuples, records, variants, enums, resources, flags)
- Pattern matching with `match` statements
- Control flow (if/else, while loops, break/continue, block expressions)
- Function system with default values and inline functions
- Interfaces and components
- WAT instruction compatibility
- Meta functions system
- Basic error handling through pattern matching

**EXCLUDED** (Future Features):
- Generic types and functions
- Function overloading
- Advanced pattern matching (ranges, array patterns)
- For loops and iterators
- Async/await
- Const expressions
- IDE tooling beyond basic compilation

## Phase 1: Foundation and Lexical Analysis (Weeks 1-2)

### Step 1.1: Enhanced Lexer for Novo Syntax
**Estimated Time**: 3 days
**Deliverable**: `src/novo_lexer.wat`

Extend the existing WAT lexer to support Novo-specific tokens:
- Kebab-case identifiers (WIT compliance)
- Assignment operator `:=`
- Type annotation operator `:`
- Pattern matching arrow `=>`
- Match keyword and pattern syntax
- Block delimiters `{` and `}`
- Mathematical operators with required spacing
- Meta function operator `::`

**Test**: Create `tests/unit/novo_lexer_test.wat` with comprehensive token recognition tests.

### Step 1.2: Novo Keywords and Reserved Words
**Estimated Time**: 2 days
**Deliverable**: `src/novo_keywords.wat`

Implement keyword recognition for:
- Type keywords: `bool`, `s8`-`s64`, `u8`-`u64`, `f32`, `f64`, `char`, `string`, `list`, `option`, `result`, `tuple`
- Structure keywords: `record`, `variant`, `enum`, `flags`, `type`, `resource`
- Function keywords: `func`, `inline`, `return`
- Component keywords: `component`, `world`, `interface`, `package`, `import`, `export`, `include`, `use`
- Control flow keywords: `if`, `else`, `while`, `break`, `continue`, `match`
- Pattern keywords: `some`, `none`, `ok`, `error`
- Literals: `true`, `false`

**Test**: Verify keyword vs identifier disambiguation, especially with kebab-case.

### Step 1.3: Syntax Disambiguation Rules
**Estimated Time**: 2 days
**Deliverable**: Enhanced lexer with disambiguation logic

Implement parsing rules for:
- Kebab-case identifiers vs subtraction operations (space-separated operators)
- WAT-style function calls vs mathematical expressions
- Mathematical operator precedence with PEMDAS rules

**Test**: Create edge case tests for ambiguous syntax patterns.

## Phase 2: Basic Parser Infrastructure (Weeks 3-4)

### Step 2.1: Novo AST Node Types
**Estimated Time**: 3 days
**Deliverable**: `src/novo_ast.wat`

Define AST node types for Novo constructs:
- Type nodes: primitive types, compound types (list, option, result, tuple)
- Declaration nodes: record, variant, enum, flags, resource definitions
- Expression nodes: literals, identifiers, function calls, mathematical operations
- Pattern nodes: literal patterns, variable bindings, destructuring patterns
- Statement nodes: assignments, control flow, match statements
- Component nodes: component, interface, import/export declarations

**Test**: AST node creation and relationship management tests.

### Step 2.2: Expression Parser
**Estimated Time**: 4 days
**Deliverable**: Expression parsing in `src/novo_parser.wat`

Implement parsing for:
- Mathematical expressions with PEMDAS precedence
- Function calls (both traditional and WAT-style parentheses-free)
- Variable references and literals
- Meta function calls (`value::size()`, `type::new()`)
- Type annotations

**Test**: Expression parsing accuracy and precedence rule enforcement.

### Step 2.3: Type System Parser
**Estimated Time**: 3 days
**Deliverable**: Type parsing in `src/novo_parser.wat`

Implement parsing for:
- Primitive type declarations
- Compound type declarations (`list<T>`, `option<T>`, `result<T,E>`, `tuple<...>`)
- Record, variant, enum, flags definitions
- Resource declarations with methods and properties
- Type aliases

**Test**: Type declaration parsing and validation.

## Phase 3: Core Language Constructs (Weeks 5-6)

### Step 3.1: Function Declaration Parser
**Estimated Time**: 4 days
**Deliverable**: Function parsing in `src/novo_parser.wat`

Implement parsing for:
- Function signatures with parameters and return types
- Default parameter values (compile-time constants and function calls)
- Inline function declarations
- Function bodies with statement parsing
- Multiple return values

**Test**: Function declaration parsing including default values and inline functions.

### Step 3.2: Control Flow Parser
**Estimated Time**: 3 days
**Deliverable**: Control flow parsing in `src/novo_parser.wat`

Implement parsing for:
- If/else statements and expressions
- While loops with break/continue
- Block expressions
- Early return statements

**Test**: Control flow parsing and nesting validation.

### Step 3.3: Pattern Matching Parser
**Estimated Time**: 4 days
**Deliverable**: Pattern matching in `src/novo_parser.wat`

Implement parsing for:
- Match statements with pattern arms
- Literal patterns, variable binding patterns
- Destructuring patterns for records and tuples
- Pattern guards with boolean expressions
- Wildcard patterns
- Exhaustiveness checking framework

**Test**: Pattern matching syntax validation and exhaustiveness checking.

## Phase 4: Type System Implementation (Weeks 7-8)

### Step 4.1: Type Checker Infrastructure
**Estimated Time**: 4 days
**Deliverable**: `src/novo_typechecker.wat`

Implement:
- Type representation and storage
- Type equality and compatibility checking
- Symbol table management for variables and functions
- Scope management for nested blocks

**Test**: Basic type checking operations and symbol resolution.

### Step 4.2: Expression Type Checking
**Estimated Time**: 3 days
**Deliverable**: Expression type checking in typechecker

Implement:
- Type inference for untyped number literals
- Mathematical operation type checking with explicit conversion requirements
- Function call type checking including default parameters
- Meta function type checking

**Test**: Expression type validation including error cases.

### Step 4.3: Pattern Matching Type Checking
**Estimated Time**: 4 days
**Deliverable**: Pattern type checking in typechecker

Implement:
- Pattern type compatibility checking
- Exhaustiveness checking for match statements
- Variable binding type validation
- Pattern guard type checking (boolean expressions only)

**Test**: Pattern matching type safety and exhaustiveness validation.

## Phase 5: Meta Functions System (Week 9)

### Step 5.1: Meta Function Infrastructure
**Estimated Time**: 3 days
**Deliverable**: `src/novo_meta_functions.wat`

Implement meta function system:
- Universal meta functions (`::type()`)
- Numeric type meta functions (`::size()`, type conversions)
- String/character meta functions
- Record meta functions
- Resource meta functions (`::new()`, `::destroy()`)

**Test**: Meta function availability and correct return types.

### Step 5.2: Resource Extension Meta Functions
**Estimated Time**: 2 days
**Deliverable**: Resource inheritance meta functions

Implement:
- Resource extension/embedding detection
- Cleanup chain management for `::destroy()`
- Size calculation including extended resources
- Type name resolution for extended resources

**Test**: Resource inheritance and cleanup chain validation.

## Phase 6: Code Generation Foundation (Weeks 10-11)

### Step 6.1: WASM Code Generator Infrastructure
**Estimated Time**: 4 days
**Deliverable**: `src/novo_codegen.wat`

Implement:
- WASM module structure generation
- Function signature generation
- Local variable management
- Stack management for expressions

**Test**: Basic WASM module generation and validation.

### Step 6.2: Expression Code Generation
**Estimated Time**: 3 days
**Deliverable**: Expression code generation

Implement:
- Mathematical operation code generation with proper type handling
- Function call code generation (both traditional and WAT-style)
- Variable access and literal value generation
- Type conversion code generation for meta functions

**Test**: Generated WASM expression evaluation correctness.

### Step 6.3: Control Flow Code Generation
**Estimated Time**: 4 days
**Deliverable**: Control flow code generation

Implement:
- If/else block generation
- While loop generation with break/continue support
- Block expression code generation
- Structured control flow validation

**Test**: Control flow WASM generation and execution.

## Phase 7: Pattern Matching Implementation (Week 12)

### Step 7.1: Pattern Matching Code Generation
**Estimated Time**: 5 days
**Deliverable**: Pattern matching code generation

Implement:
- Match statement compilation to WASM conditionals
- Pattern testing and variable binding
- Exhaustiveness checking enforcement
- Pattern guard evaluation

**Test**: Pattern matching execution correctness and exhaustiveness.

### Step 7.2: Error Propagation through Pattern Matching
**Estimated Time**: 2 days
**Deliverable**: Error handling code generation

Implement:
- Result type pattern matching
- Option type pattern matching
- Explicit error propagation patterns
- Error path validation

**Test**: Error handling through pattern matching validation.

## Phase 8: Component System (Weeks 13-14)

### Step 8.1: Component Declaration Processing
**Estimated Time**: 4 days
**Deliverable**: Component system in parser and typechecker

Implement:
- Component, interface, world declarations
- Import/export processing
- Package system basics
- Component entry points (`_start` function)

**Test**: Component declaration parsing and validation.

### Step 8.2: WIT Export Generation
**Estimated Time**: 3 days
**Deliverable**: WIT format output in `src/novo_wit_export.wat`

Implement:
- WIT interface generation from Novo components
- Default value documentation in comments
- Type mapping from Novo to WIT
- Component interface compatibility

**Test**: WIT export correctness and WIT compliance.

### Step 8.3: Component Code Generation
**Estimated Time**: 4 days
**Deliverable**: Component WASM generation

Implement:
- Component-compatible WASM generation
- Import/export wiring
- Entry point generation
- Component initialization

**Test**: Component WASM generation and execution.

## Phase 9: Default Values and Inline Functions (Week 15)

### Step 9.1: Default Value Implementation
**Estimated Time**: 3 days
**Deliverable**: Default value code generation

Implement:
- Function parameter default value evaluation at call sites
- Record field default value evaluation at construction
- Function call defaults with fresh evaluation

**Test**: Default value behavior validation.

### Step 9.2: Inline Function Implementation
**Estimated Time**: 4 days
**Deliverable**: Inline function code generation

Implement:
- Inline function body substitution
- Nested inline function flattening
- Performance optimization through inlining
- Inline vs normal function call generation

**Test**: Inline function behavior and performance validation.

## Phase 10: Integration and Testing (Week 16)

### Step 10.1: End-to-End Compiler Integration
**Estimated Time**: 3 days
**Deliverable**: Complete compiler pipeline

Integrate all components:
- Lexer → Parser → Type Checker → Code Generator
- Error handling and reporting
- File I/O and compilation workflow

**Test**: Complete Novo program compilation from source to WASM.

### Step 10.2: Comprehensive Testing and Validation
**Estimated Time**: 3 days
**Deliverable**: Test suite and validation

Create comprehensive tests:
- Language feature tests
- Error condition tests
- Performance benchmarks
- WIT compliance validation

**Test**: Full language feature coverage and regression prevention.

### Step 10.3: Documentation and Examples
**Estimated Time**: 1 day
**Deliverable**: Usage documentation and examples

Create:
- Compiler usage documentation
- Language feature examples
- Migration guide from prototype to self-hosting

## Implementation Guidelines

### Testing Strategy
- Each step must include unit tests before proceeding
- Integration tests after each phase
- WAT validation using standard WASM tools
- Performance regression testing

### Development Practices
- Small, incremental changes with frequent testing
- Clear error messages with helpful context
- Memory layout documentation for debugging
- Modular design for maintainability

### Quality Gates
- All tests must pass before proceeding to next step
- Generated WASM must validate with standard tools
- WIT exports must comply with Component Model specification
- Performance must not regress significantly between phases

## Risk Mitigation

### Technical Risks
- **Memory management complexity**: Use existing memory management patterns from WAT compiler
- **Pattern matching complexity**: Start with simple patterns, add complexity incrementally
- **Type system complexity**: Implement core types first, add advanced features later

### Schedule Risks
- **Buffer time**: Each phase includes 20% buffer for unexpected complexity
- **Parallel development**: Some steps can be developed in parallel after dependencies are clear
- **Scope creep**: Strictly exclude future features to maintain focus

## Success Criteria

At completion, the Novo compiler should:
1. Compile valid Novo programs to working WASM components
2. Generate compliant WIT interfaces
3. Support all core language features defined in specification
4. Pass comprehensive test suite
5. Provide clear error messages for invalid programs
6. Maintain compatibility with WASM Component Model
7. Demonstrate readiness for self-hosting transition

This plan provides a solid foundation for implementing the Novo programming language while maintaining focus on the core features and ensuring each step is thoroughly tested before proceeding.
