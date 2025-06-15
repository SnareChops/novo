# Basic Types and Syntax

## Identifiers

Novo uses kebab-case for identifiers to maintain WIT compatibility:

```novo
my-variable := 42
my-function()
record my-type { field: string }
```

**Identifier rules:**
- Must start with a letter
- Can contain letters, digits, and hyphens
- Cannot have consecutive hyphens
- Cannot end with a hyphen
- Case-consistent within each word (no mixed case like `myVar-name`)

## Primitive Types

Novo provides comprehensive primitive types with clear size semantics:

### Integer Types

```novo
// Signed integers
a : s8 = -128        // 8-bit signed
b : s16 = -32768     // 16-bit signed
c : s32 = -2000000   // 32-bit signed
d : s64 = -9000000   // 64-bit signed

// Unsigned integers
e : u8 = 255         // 8-bit unsigned
f : u16 = 65535      // 16-bit unsigned
g : u32 = 4000000    // 32-bit unsigned
h : u64 = 18000000   // 64-bit unsigned

// Type aliases for compatibility
i : i8 = -100        // Alias for s8
j : i16 = -1000      // Alias for s16
k : i32 = -100000    // Alias for s32
l : i64 = -1000000   // Alias for s64
```

### Floating Point Types

```novo
x : f32 = 3.14159    // 32-bit float
y : f64 = 2.71828    // 64-bit float
```

### Boolean and Character Types

```novo
flag : bool = true
letter : char = 'A'
text : string = "Hello, world!"
```

## Variable Declaration Syntax

### Explicit Type Declaration

```novo
name : type = value
counter : u32 = 0
message : string = "Hello"
```

### Type Inference with :=

The `:=` operator provides shorthand for type inference:

```novo
x := 42              // Equivalent to: x : u32 = 42 (assuming u32 inference)
name := "Alice"      // Equivalent to: name : string = "Alice"
flag := true         // Equivalent to: flag : bool = true
```

**Type inference rules:**
- Compiler determines type from right-hand side expression
- Cannot be used when explicit type annotation is required for disambiguation
- Untyped number literals adapt to their usage context

### Untyped Number Literals

Novo supports flexible number literals that adapt to context:

```novo
x := 42              // Untyped number literal
y : u32 = 100

result1 := x + y     // x becomes u32 for this operation
result2 : u8 = x     // x becomes u8 for this assignment (if value fits)
```

**Constraints:**
- Value must be compatible with target type (e.g., 256 cannot be used as u8)
- Floating-point literals only compatible with f32/f64 types
- At least one operand in binary operations must be explicitly typed

## Language Syntax

### Statement Termination

Semicolons and newlines are equivalent for statement termination:

```novo
// These are equivalent
x := 42
y := 24

x := 42; y := 24

// Mixed usage allowed
if condition {
    process-data(); log-result()
    cleanup-resources()
}
```

### Comment Syntax

```novo
// Single line comment

/*
 * Multi-line comment
 * spanning multiple lines
 */

func example() {
    // Implementation comment
    x := 42  // End-of-line comment
}
```

### Reserved Words

**Type keywords:** `bool`, `s8`, `s16`, `s32`, `s64`, `i8`, `i16`, `i32`, `i64`, `u8`, `u16`, `u32`, `u64`, `f32`, `f64`, `char`, `string`, `list`, `option`, `result`, `tuple`

**Structure keywords:** `record`, `variant`, `enum`, `flags`, `type`, `resource`

**Function keywords:** `func`, `inline`, `return`

**Component keywords:** `component`, `world`, `interface`, `package`, `import`, `export`, `include`, `use`

**Control flow keywords:** `if`, `else`, `while`, `for`, `break`, `continue`

**Literals:** `true`, `false`

## Mathematical Operations

Novo uses familiar infix notation with standard PEMDAS precedence:

```novo
result := a + b * c        // Equivalent to a + (b * c)
result := (a + b) * c      // Explicit grouping
result := a / b - c        // Left-to-right for same precedence
```

**Operator spacing rules:**
Mathematical operators require spaces to disambiguate from kebab-case identifiers:

```novo
my-var := 42        // Variable name (kebab-case)
result := my - var  // Subtraction between 'my' and 'var' variables
```

## Type Safety and Operations

Operations between different types require explicit conversion:

```novo
a : s8 = 100
b : s32 = 200
result := a::s32() + b   // Valid: explicit conversion using meta function
result := a + b          // Error: explicit conversion required
```

## Error Messages

When type inference fails, novo provides helpful error messages:

```novo
x := 256
y : u8 = x    // Error: "literal 256 cannot fit in u8 (maximum value: 255)"
              // Additional context: "literal 256 is valid for: u16, u32, u64, s16, s32, s64"
```
