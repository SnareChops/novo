# Novo
A WASM targeted language. This language is designed to directly
interface with the WASM component model, and is an alternate way to
create WASM components. This is a compiled language that compiles
directly to binary `.wasm` and can also output `.wit` to allow
other components to interact with these modules. Optionally novo
components can be compiled to core WASM if necessary for
compatibility.

Novo components can then be run directly by any existing WASM
runtime compliant with the WASM specification.

## Goals
1. All types and concepts are directly driven from the WIT
  specification.
2. The language should retain the ability to write raw WASM
  instructions following WAT conventions (including S-folding).
  Only the raw non-control instructions need to remain supported,
  however they can be implemented using novo constructs (like
  functions) as long as they retain their WAT syntax usage. To this
  end, when calling a function the parens and commas for parameters
  can be optionally dropped allowing the calling of a function to
  look similar to WAT instructions.
3. Memory management follows normal WASM conventions including
  stack usage.
4. Details about how the stack functions should not be hidden from
  the developer and language usage should reflect that.

## Identifiers
Identifiers for novo follow the spec for identifiers of WIT. This ensures compliance with the component model and WASM standard, even though the rules are strange and feel unfamiliar / unconventional.

- Identifiers are restricted to ASCII kebab-case - sequences of words, separated by single hyphens.
  - Double hyphens (--) are not allowed.
  - Hyphens aren't allowed at the beginning or end of the sequence, only between words.
- An identifier may be preceded by a single % sign.
  - This is required if the identifier would otherwise be a WIT keyword. For example, interface is not a legal identifier, but %interface is legal.
- Each word in the sequence must begin with an ASCII letter, and may contain only ASCII letters and digits.
  - A word cannot begin with a digit.
  - A word cannot contain a non-ASCII Unicode character.
  - A word cannot contain punctuation, underscores, etc.
- Each word must be either all lowercase or all UPPERCASE.
  - Different words in the identifier may have different cases. For example, WIT-demo is allowed.
- An identifier cannot be a WIT keyword such as interface (unless preceded by a % sign).

## Primitive Types
`bool` - Boolean value `true` or `false`

`s8` - 8 bit signed integer
`s16` - 16 bit signed integer
`s32` - 32 bit signed integer
`s64` - 64 bit signed integer

`u8` - 8 bit unsigned integer
`u16` - 16 bit unsigned integer
`u32` - 32 bit unsigned integer
`u64` - 64 bit unsigned integer

`f32` - IEEE 754 single precision value
`f64` - IEEE 754 double precision value

`char` - Unicode character (specifically a unicode scalar value)
`string` - A unicode string (a finite sequence of characters)

## Lists
`list<T>` for any type `T` denotes an ordered sequence of values of
type `T`. `T` can be any type, built-in or user-defined:

Examples:
`list<u8>`       // byte buffer
`list<customer>` // a list of customers
This is similar to Rust Vec, or Java List.

## Options
`option<T>` for any type `T` may contain a value of type `T`, or
may contain no value. `T` can be any type, built-in or
user-defined. For example, a lookup function might return an
option, allowing for the possibility that the lookup key wasn't
found:

```
option<customer>
```

This is similar to Rust Option, C++ std::optional, or Haskell Maybe.

## Results
result<T, E> for any types T and E may contain a value of type T or
a value of type E (but not both). This is typically used for "value
or error" situations; for example, a HTTP request function might
return a result, with the success case (the T type) representing a
HTTP response, and the error case (the E type) representing the
various kinds of error that might occur:

```
result<http-response, http-error>
```

This is similar to Rust `Result`, or Haskell `Either`.

Sometimes there is no data associated with one or both of the
cases. For example, a print function could return an error code if
it fails, but has nothing to return if it succeeds. In this case,
you can omit the corresponding type as follows:

```
result<u32>     // no data associated with the error case
result<_, u32>  // no data associated with the success case
result          // no data associated with either case
```

## Tuples
A `tuple` type is an ordered _fixed length_ sequence of values of
specified types. It is similar to a record, except that the fields
are identified by their order instead of by names.

```
tuple<u64, string>      // An integer and a string
tuple<u64, string, u64> // An integer, then a string, then an integer
```

This is similar to tuples in Rust or OCaml.

## Records
A `record` type declares a set of named fields, each of the form
`name: type`, separated by commas. A record instance contains a
value for every field. Field types can be built-in or user-defined.
The syntax is as follows:

```
record customer {
    id: u64,
    name: string,
    picture: option<list<u8>>,
    account-manager: employee,
}
```

Records are similar to C or Rust `struct`s.

> User-defined records can't be generic (that is, parameterised by
> type). Only built-in types can be generic.

## Variants
A `variant` type declares one or more cases. Each case has a name
and, optionally, a type of data associated with that case. A
variant instance contains exactly one case. Cases are separated by
commas. The syntax is as follows:

```
variant allowed-destinations {
    none,
    any,
    restricted(list<address>),
}
```
Variants are similar to Rust `enum`s or OCaml discriminated unions.
The closest C equivalent is a tagged union, but novo both takes
care of the "tag" (the case) and enforces the correct data shape
for each tag.

> User-defined variants can't be generic (that is, parameterised by
> type). Only built-in types can be generic.

## Enums
An `enum` type is a variant type where none of the cases have
associated data:

```
enum color {
    hot-pink,
    lime-green,
    navy-blue,
}
```
This can provide a simpler representation than variants. For
example, a novo enum can translate directly to a C++ enum.

## Resources

Resources in novo provide class-like functionality while maintaining compatibility with the WIT specification. A resource represents an abstract handle to some external state, similar to classes in object-oriented languages.

### Resource Declaration

Resources are declared with the `resource` keyword and can contain both methods (as per WIT spec) and properties (novo extension):

```novo
resource file-handle {
    // Properties (novo extension for internal state)
    path: string,
    size: u64,
    is-open: bool,

    // Constructor (optional)
    constructor(path: string) -> result<file-handle, io-error>

    // Methods (WIT-compatible)
    func read(count: u32) -> result<list<u8>, io-error>
    func write(data: list<u8>) -> result<u32, io-error>
    func close() -> result

    // Static methods
    static func exists(path: string) -> bool
}
```

### Resource Usage

Resources are used similar to classes in other languages:

```novo
// Create resource instance
handle := file-handle.constructor("/path/to/file")

// Access properties
file-path := handle.path
file-size := handle.size

// Call methods
data := handle.read(1024)
bytes-written := handle.write(data)

// Static method call
if file-handle.exists("/some/path") {
    // process file
}

// Cleanup
handle.close()
```

### WIT Compatibility

When exporting to WIT format:
- **Properties** are not included in the WIT output (novo-specific feature)
- **Methods** are exported as standard WIT resource methods
- **Constructors** follow WIT resource constructor patterns
- **Static methods** are exported as standalone functions in the interface

This design allows novo to provide familiar class-like syntax while maintaining full WIT compatibility for inter-component communication.

## Flags
A `flags` type is a set of named booleans. In an instance of the
type, each flag will be either `true` or `false`.
```
flags allowed-methods {
    get,
    post,
    put,
    delete,
}
```
> A `flags` type is logically equivalent to a record type where each
> field is of type `bool`, but it is represented more efficiently
> (as a bitfield) at the binary level.

## Type Aliases
You can define a new named type using `type ... = ...`. This can be
useful for giving shorter or more meaningful names to types:
```
type buffer = list<u8>;
type http-result = result<http-response, http-error>;
```

## Pattern Matching

Pattern matching in novo provides a powerful way to destructure and match against variant types, options, results, and other complex data structures. Pattern matching is primarily used with the `match` statement but can also be used in variable declarations and function parameters.

### Match Statements

The `match` statement allows pattern matching against values:

```novo
variant message {
    text(string),
    image(list<u8>),
    audio(list<u8>, u32),  // data, sample-rate
    empty,
}

func process-message(msg: message) {
    match msg {
        text(content) => {
            log("Received text: " + content)
        },
        image(data) => {
            log("Received image, size: " + data.length.to-string())
        },
        audio(data, rate) => {
            log("Received audio: " + data.length.to-string() + " bytes at " + rate.to-string() + "Hz")
        },
        empty => {
            log("Empty message")
        }
    }
}
```

### Pattern Matching with Results and Options

Pattern matching is particularly useful with `result` and `option` types:

```novo
func handle-file-operation() -> result<string, io-error> {
    file-content := read-file("/path/to/file")

    match file-content {
        ok(content) => {
            log("File read successfully")
            return ok(content)
        },
        error(err) => {
            log("Failed to read file: " + err.message)
            return error(err)
        }
    }
}

func process-optional-value(maybe-value: option<u32>) {
    match maybe-value {
        some(value) => {
            log("Got value: " + value.to-string())
        },
        none => {
            log("No value provided")
        }
    }
}
```

### Exhaustiveness Checking

The compiler enforces exhaustive pattern matching - all possible cases must be handled:

```novo
enum status {
    pending,
    running,
    completed,
    failed,
}

func handle-status(s: status) {
    match s {
        pending => log("Waiting to start"),
        running => log("In progress"),
        completed => log("Done"),
        // Error: missing case for 'failed'
    }
}
```

### Pattern Guards

Pattern guards allow additional conditions within patterns:

```novo
func categorize-number(n: s32) -> string {
    match n {
        x if x < 0 => "negative",
        0 => "zero",
        x if x > 0 && x <= 10 => "small positive",
        x if x > 10 => "large positive",
    }
}
```

**Guard limitations:**
- Guards must be boolean expressions
- Guards cannot call functions that may have side effects
- Guards are evaluated in order, first matching guard wins
- If no guard matches, the pattern fails and the next pattern is tried

### Destructuring Patterns

Records and tuples can be destructured in patterns:

```novo
record point {
    x: f32,
    y: f32,
}

func process-point(p: point) {
    match p {
        point { x: 0.0, y: 0.0 } => log("Origin"),
        point { x, y } if x == y => log("Diagonal point"),
        point { x, y } => log("Point at (" + x.to-string() + ", " + y.to-string() + ")"),
    }
}

func process-tuple(t: tuple<string, u32>) {
    match t {
        ("error", code) => log("Error code: " + code.to-string()),
        (message, 0) => log("Success: " + message),
        (message, code) => log("Message: " + message + ", code: " + code.to-string()),
    }
}
```

### Variable Binding in Patterns

Patterns can bind parts of the matched value to variables:

```novo
variant tree {
    leaf(s32),
    branch(tree, tree),
}

func sum-tree(t: tree) -> s32 {
    match t {
        leaf(value) => value,
        branch(left, right) => sum-tree(left) + sum-tree(right),
    }
}
```

### Wildcard Patterns

The `_` wildcard pattern matches anything without binding:

```novo
func handle-result(r: result<string, error>) {
    match r {
        ok(value) => log("Success: " + value),
        error(_) => log("Some error occurred"),  // Don't care about the specific error
    }
}
```

### Pattern Matching in Variable Declarations

Simple pattern matching can be used in variable declarations:

```novo
// Destructuring assignment
point { x, y } := get-point()

// Option unwrapping (must be exhaustive)
some(value) := get-optional-value() else {
    log("No value available")
    return
}
```

### Error Propagation through Pattern Matching

Instead of using a `?` operator, novo encourages explicit error handling through pattern matching:

```novo
func process-data() -> result<string, error> {
    // Read file
    file-content := read-file("/data.txt")
    data := match file-content {
        ok(content) => content,
        error(err) => return error(err),  // Explicit error propagation
    }

    // Process data
    processed := process-string(data)
    result := match processed {
        ok(value) => value,
        error(err) => return error(err),  // Explicit error propagation
    }

    return ok(result)
}
```

This approach ensures all error paths are explicitly handled and visible in the code.

## Control Flow

Novo provides familiar control flow constructs while maintaining compatibility with WebAssembly's structured control flow model.

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

If statements can be used as expressions when all branches return values:

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
```

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
```

#### For Loops (Future Feature)

*For loop syntax is reserved for future implementation*

```novo
// Future syntax (not yet implemented)
for item in list {
    process(item)
}

for i in 0..10 {
    log("Index: " + i.to-string())
}
```

### Loop Control

#### Break Statement

The `break` statement exits the nearest enclosing loop:

```novo
func find-value(list: list<s32>, target: s32) -> option<u32> {
    index := 0
    while index < list.length {
        if list[index] == target {
            return some(index)
            // break is implicit here due to return
        }
        index = index + 1

        if index > 1000 {
            break  // Prevent infinite loops
        }
    }
    return none
}
```

#### Continue Statement

The `continue` statement skips to the next iteration of the loop:

```novo
func process-positive-numbers(numbers: list<s32>) {
    index := 0
    while index < numbers.length {
        current := numbers[index]
        index = index + 1

        if current <= 0 {
            continue  // Skip non-positive numbers
        }

        log("Processing: " + current.to-string())
        // Process positive number
    }
}
```

### Block Expressions

Blocks can be used as expressions, returning the value of their last expression:

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

### WAT Compatibility

Control flow constructs compile to WebAssembly's structured control flow:
- `if`/`else` compile to `if`/`else` blocks in WAT
- `while` loops compile to `loop` blocks with conditional `br_if`
- `break` compiles to `br` instructions
- `continue` compiles to `br` to loop start
- Block expressions use WAT block constructs

This ensures predictable performance and maintains the structured nature required by WebAssembly validation.

## Functions
A function is defined by a name and a function type. Like in record
fields, the name is separated from the type by a colon:

```
func do-nothing(){}
```

The function type is the word `func`, followed by an identifier for
the function, followed by a parenthesised, comma-separated list of
parameters (names and types). If the function returns a value, this
is expressed as an arrow symbol (`->`) followed by the return type:

```
// This function does not return a value
func print(message: string) {
  // implementation
}

// These functions return values
func add(a: u64, b: u64) -> u64 {
  // implementation
}

func lookup(store: kv-store, key: string) -> option<string> {
  // implementation
}
```

A function can have multiple return values. In this case the return
values must be named, similar to the parameter list. All return
values must be populated (in the same way as tuple or record
fields).

```
func get-customers-paged(cont: continuation-token) -> (customers: list<customer>, cont: continuation-token) {
  // implementation
}
```

When used as a type functions are declared without a name or
function body.
```
type add = func(a: u32, b: u32) -> u32;
```

## Default Values

Novo supports default values for function parameters and record fields, enhancing ergonomics while maintaining compile-time determinism.

### Function Parameter Default Values

Functions can specify default values for parameters:

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
log-message("Hello world")                           // Uses defaults: level="info", timestamp=true
log-message("Debug info", "debug")                   // Uses default: timestamp=true
log-message("Error occurred", "error", false)        // No defaults used
```

### Record Field Default Values

Record fields can have default values:

```novo
record config {
    host: string = "localhost",
    port: u16 = 8080,
    ssl-enabled: bool = false,
    timeout-ms: u32 = 5000,
    name: string,  // No default - must be provided
}

// Usage examples
cfg1 := config { name: "my-app" }  // Uses all defaults except name
cfg2 := config {
    name: "web-server",
    port: 3000,      // Override default
    ssl-enabled: true  // Override default
}
```

### Function Call Default Values

Default values can be function calls, evaluated each time the default is used:

```novo
func create-temp-file(prefix: string = "temp", suffix: string = generate-uuid()) -> string {
    return prefix + "-" + suffix + ".tmp"
}

// Each call generates a new UUID for the suffix default
file1 := create-temp-file()           // e.g., "temp-abc123.tmp"
file2 := create-temp-file()           // e.g., "temp-def456.tmp"
file3 := create-temp-file("data")     // e.g., "data-ghi789.tmp"
```

### Compilation Behavior

**Function parameter defaults:**
- Defaults are evaluated at the call site
- Function calls in defaults are executed each time the default is used
- No memoization - each call evaluates the default expression fresh

**Record field defaults:**
- Defaults are applied during record construction
- Function calls in defaults are executed during each record instantiation
- Values are copied/computed at construction time

### WIT Export Comments

When exporting functions with default values to WIT format, defaults are documented in comments:

```wit
// Generated WIT output
interface example {
    // log-message(message: string, level: string = "info", timestamp: bool = true)
    log-message: func(message: string, level: option<string>, timestamp: option<bool>)

    // Record fields with defaults are noted in comments
    record config {
        // host: string = "localhost"
        host: option<string>,
        // port: u16 = 8080
        port: option<u16>,
        // ssl-enabled: bool = false
        ssl-enabled: option<bool>,
        // timeout-ms: u32 = 5000
        timeout-ms: option<u32>,
        name: string,
    }
}
```

The actual WIT interface uses `option<T>` types for parameters/fields with defaults, allowing external components to omit values while novo components internally apply the defaults.

### Constraints and Limitations

**Default value constraints:**
- Default values must be compile-time constant expressions or function calls
- Default expressions cannot reference other parameters in the same function
- Record field defaults cannot reference other fields in the same record
- Recursive default expressions are prohibited

**Type compatibility:**
- Default value type must exactly match the parameter/field type
- No automatic type conversion in default values
- Generic type defaults must be compatible with all possible instantiations

**Example constraints:**
```novo
func invalid-defaults(
    a: u32,
    b: u32 = a,           // Error: cannot reference parameter 'a'
    c: string = 42        // Error: type mismatch, expected string, got u32
) {
    // ...
}

record invalid-record {
    width: u32 = 100,
    height: u32 = width,  // Error: cannot reference field 'width'
}
```
## Inline Functions
Novo includes a special type of function marked with the `inline`
keyword. Any existing function can be used inline, and a function
can be declared as inline when defined.

Inline functions are similar to macros from other languages and
during compilation their function bodies will be inline'd as if the
contents of the function body were included in place.

The resulting WASM binary for the `do-something` and
`do-equivalent` functions would be 100% identical

```
// Definition of inline function
inline func add(a: u32, b: u32) -> u32 {
  result := a b +
  return result
}

// Example function using the inline function
func do-something() {
  x := add(2, 3)
}

// Example of an equivalent function
func do-equivalent() {
  x := 2 3 +
}
```

Functions declared with the `inline` keyword are _always_ inlined
when used. Functions declared normally can be optionally inlined if
used with the `inline` keyword.

```
func normal-function() {
  // implementation
}

func other-function() {
  inline normal-function()
}
```

Nested inline functions are honored and should be inlined as well
(for example if you inline a function that within its body also has
an inlined function). The end result is to flatten all instructions
into the body of the parent function. Non-inlined function calls
are retained like normal resulting in a normal `call` and `return`
pattern.

The end result of this feature is to allow developers to avoid a
`call` and `return` in the resulting WASM. This also allows novo
language features to be implemented using inline function to inject
functionality and ease compilation to WASM native binary.

## Interfaces
An interface describes a single-focus, composable contract, through
which components can interact with each other and with hosts.
Interfaces describe the types and functions used to carry out that
interaction. For example:

- A "receive HTTP requests" interface might have only a single
  "handle request" function, but contain types representing
  incoming requests, outgoing responses, HTTP methods and headers,
  and so on.
- A "wall clock" interface might have two functions, one to get the
  current time and one to get the granularity of the timer. It
  would also include a type to represent an instant in time.

## Components
A novo component is a higher-level contract that describes
capabilities and needs.

> Unlike in WIT, a novo component also encapulates the concept of a
> world.

A component describes the shape of your code, as well as its
implementation - it says which interfaces the component exposes for
other code to call (its exports), and which interfaces the
component depends on (its imports). Your component may target an
existing world definition that someone else has already specified
via a .wit file.

Novo components can import and export worlds defined by other WASM
components, for example any of the WASI (the WebAssembly System
Interface) components.

A component is composed of imports and exports. A component cannot
interact with anything outside itself except by having its exports
called, or by it calling its imports. This provides very strong
sandboxing; for example, if a component does not have an import for
a secret store, then it cannot access that secret store, even if
the store is running in the same process.

A component is defined with the `component` keyword, a name, and
its contents enclosed in braces. It is similar to a
namespace in other languages.

> The `world` keyword can be used in place of `component` if more
> comfortable. In WASM they define the contract and implementation
> repectively, however in novo both contract and implementation are
> defined together.

You can import and export interfaces defined in other packages.
This can be done using package/name syntax:

```
component http-proxy {
  export wasi:http/incoming-handler;
  import wasi:http/outgoing-handler;
}
```

## Include
You can `include` another world. This causes your world to export
all that world's exports, and import all that world's imports.
```
world glow-in-the-dark-multi-function-device {
    // The component provides all the same exports, and depends on
    // all the same imports, as a `multi-function-device`...
    include multi-function-device;

    // ...but also exports a function to make it glow in the dark
    export func glow(brightness: u8) {
      // implementation
    }
}
```

## Packages
A package is a set of interfaces and worlds, potentially defined
across multiple files. To declare a package, use the `package`
directive to specify the package ID. This must include a namespace
and name, separated by a colon, and may optionally include a
semver-compliant version:

```
package documentation:example;
package documentation:example@1.0.1;
```

If a package spans multiple files, only one file needs to contain a
package declaration (but if multiple files contain declarations
then they must all be the same). All files must have the `.no`
extension and must be in the same directory. For example, the
following `documentation:http` package is spread across four files:

```
// types.no
interface types {
  record request { /* ... */ }
  record response { /* ... */ }
}

// incoming.no
interface incoming-handler {
  use types.{request, response};
  // ...
}

// outgoing.no
interface outgoing-handler {
  use types.{request, response};
  // ...
}

// http.no
package documentation:http@1.0.0;

world proxy {
  export incoming-handler;
  import outgoing-handler;
}
```

## WAT Instruction Compatibility

Novo maintains syntactic compatibility with WebAssembly Text Format (WAT) instructions while implementing them through novo-specific mechanisms. The goal is to preserve the spirit and syntax of WAT instructions while providing a more ergonomic development experience.

### Instruction Implementation

WAT instructions like `i32.add` are implemented using namespaces and functions. For example:
- `i32.add` could be implemented as a function in the `i32` namespace
- Function calls can drop parentheses, so `i32.add()` becomes `i32.add`
- This maintains syntactic equivalence with WAT while providing implementation flexibility

Core instructions that form the foundation for all other functionality may use alternative implementation mechanisms, but the end syntax should remain consistent with WAT conventions.

### Stack Management

Novo provides two levels of stack interaction:

1. **Managed Operations**: Variable declarations, function parameters, and results are handled automatically by novo without requiring developer intervention.

2. **Explicit Stack Operations**: When using raw WAT instructions or optimizing performance, developers can directly manage the stack. Stack operations (push/pop behavior) are not hidden when performing mathematical operations - developers remain aware of the underlying stack-based nature.

Inline functions serve as a primary mechanism for bridging these two levels, allowing novo to inject functionality while compiling to efficient WASM.

### Variable Declaration and Syntax

Variables can be declared using sugar syntax or full WAT-compatible syntax:

```novo
// Sugar syntax
result := value                    // Type inferred
name : type = value               // Explicit type

// WAT-compatible local declaration syntax is also valid
```

### Mathematical Operations Syntax

Novo uses familiar infix notation for mathematical operations with standard PEMDAS precedence rules:

```novo
result := a + b * c        // Equivalent to a + (b * c)
result := (a + b) * c      // Explicit grouping
result := a / b - c        // Left-to-right for same precedence
```

This provides familiar syntax while the compiler translates to appropriate stack-based WASM instructions based on operand types.

### WAT-Compatible Function Call Syntax

Function calls support dropping parentheses and commas for WAT compatibility:

```novo
// Traditional function call syntax
result := i32.add(a, b)

// WAT-compatible syntax (equivalent to above)
result := i32.add a b

// Invalid syntax
result := a i32.add b     // Error: method-style calls not supported
```

When parentheses are dropped, arguments must appear in the same order as a standard function call, separated by spaces instead of parentheses and commas.

## Syntax Disambiguation and Parsing Rules

### Identifier vs Mathematical Expression Disambiguation

Due to WIT's kebab-case identifier requirements, certain syntax patterns can be ambiguous:

```novo
my-func := 42        // Assignment (clear due to :=)
result := my-func    // Variable reference (clear)
result := my - func  // Subtraction between 'my' and 'func' variables (ambiguous)
```

**Alternative subtraction syntax solution:**
- **Space-separated operators**: `my - func` (requires spaces around `-` operator)
- This disambiguates subtraction from kebab-case identifiers
- Mathematical operators must have spaces: `a - b`, `x + y`, `m * n`
- Kebab-case identifiers cannot contain spaces: `my-func`, `other-var`

### Function Call vs Mathematical Expression Rules

When using parentheses-free function calls, mathematical operations are not permitted to avoid parsing ambiguity:

```novo
// Valid: Traditional function call with math
result := i32.add(a + b, c * d)

// Valid: WAT-style function call (no math allowed in this context)
result := i32.add a b

// Invalid: Mixed syntax creates ambiguity
result := i32.add a b + c    // Error: no math operations allowed with paren-free calls
```

**Parsing rule:** When using WAT-compatible parentheses-free function syntax, mathematical operations are prohibited in the same expression to maintain unambiguous parsing.

## Language Syntax

### Statement Termination

Novo treats semicolons and newlines as equivalent for statement termination:

```novo
// These are equivalent
x := 42
y := 24

x := 42; y := 24

// Mixed usage is allowed
if condition {
    process-data(); log-result()
    cleanup-resources()
}
```

Semicolons are optional at the end of lines but can be used to combine multiple statements on a single line.

### Reserved Words

The following terms are reserved keywords in novo:

**Type keywords:** `bool`, `s8`, `s16`, `s32`, `s64`, `u8`, `u16`, `u32`, `u64`, `f32`, `f64`, `char`, `string`, `list`, `option`, `result`, `tuple`

**Structure keywords:** `record`, `variant`, `enum`, `flags`, `type`, `resource`

**Function keywords:** `func`, `inline`, `return`

**Component keywords:** `component`, `world`, `interface`, `package`, `import`, `export`, `include`, `use`

**Control flow keywords:** `if`, `else`, `while`, `for`, `break`, `continue`

**Literals:** `true`, `false`

### Comment Syntax

Novo uses C-style comment syntax:

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

## Development Tooling

### Optimization Strategy

The compiler focuses on standard compilation without advanced optimization passes. Novo provides developers direct optimization access through:

- Inline functions for macro-like optimizations
- Direct WAT instruction access for performance-critical code
- Explicit memory layout control
- Stack-aware operations

This approach prioritizes developer control over compiler optimization.

### Debugging and Tooling

- **Debug Information**: No novo-specific debug formats planned; will adopt WASM ecosystem debug tools as they mature
- **Package Management**: Will integrate with WASM ecosystem package management strategies rather than defining novo-specific solutions
- **Build Tools**: Standard WASM toolchain integration

## Advanced Type System Details

### Mixed Type Operations and Type Safety

Operations between different integer sizes require explicit conversion using meta functions:

```novo
a : s8 = 100
b : s32 = 200
result := a::s32() + b   // Valid: explicit conversion using meta function
result := a + b          // Error: explicit conversion required
```

### Untyped Number Literals and Type Inference

Novo supports flexible untyped number literals that adapt to their usage context:

```novo
x := 42              // Untyped number literal
y : u32 = 100

result1 := x + y     // x becomes u32 for this operation
result2 : u8 = x     // x becomes u8 for this assignment (if value fits)
result3 := x * 2.0   // Error: mixed typed/untyped operation requires explicit typing
```

**Untyped number constraints:**
- Value must be compatible with target type (e.g., 256 cannot be used as u8)
- Floating-point literals (3.14) only compatible with f32/f64 types
- Untyped variables cannot be reassigned (they disappear during compilation)
- At least one operand in binary operations must be explicitly typed
- Compiler substitutes literal values directly at usage sites

### Untyped Literal Error Messages

When untyped number literals fail type inference, error messages prioritize explaining the specific failure while providing helpful context:

```novo
x := 256
y : u8 = x    // Error: "literal 256 cannot fit in u8 (maximum value: 255)"
              // Additional context: "literal 256 is valid for: u16, u32, u64, s16, s32, s64"

z := 3.14
w : s32 = z   // Error: "floating-point literal 3.14 cannot be used as integer type s32"
              // Additional context: "literal 3.14 is valid for: f32, f64"
```

**Error message structure:**
1. **Primary error**: Specific rule violation and constraint that failed
2. **Helpful context**: Suggested valid types for the literal value
3. **Location**: Error reported at the usage site, not the declaration site

### Integer Type Operations

Novo's type system enables precise operation selection based on declared types:

- `s8`/`i8` → Uses WASM i32 with 8-bit specific operations (i32.add with i32.and 0xFF)
- `s16`/`i16` → Uses WASM i32 with 16-bit specific operations
- `s32`/`i32` → Direct WASM i32 operations
- `s64`/`i64` → Direct WASM i64 operations

```novo
a : s8 = 100
b : s8 = 50
result := a + b        // Compiler uses 8-bit addition with overflow handling
```

### Overflow and Underflow Behavior

The compiler performs compile-time overflow/underflow detection when all values are known:

```novo
a : u8 = 255
b : u8 = 1
result := a + b      // Compiler warning: u8 overflow detected
```

When compile-time detection is not possible, novo defers to WASM runtime behavior without imposing additional constraints beyond those defined by the WASM specification.

### String and Character Implementation

Strings are implemented as UTF-8 byte sequences in linear memory with a 4-byte (i32) length prefix:

```
[length: i32][utf8_bytes...]
```

Characters (`char`) represent Unicode scalar values and are stored as their UTF-8 encoding.

> Note: If the Component Model specification defines a more specific string representation, that specification takes precedence.

### Complex Type Memory Layout and Stack Allocation

Record, variant, and list types are laid out contiguously in memory in the order defined by the developer using packed layout:

```novo
record example {
    id: u32,           // Bytes 0-3
    value: u64,        // Bytes 4-11
    flag: bool,        // Byte 12
}
// Total size: 13 bytes (packed, no padding)
```

**Memory allocation strategy:**
- **Stack allocation**: Default for variables within block scope
- **Linear memory allocation**: When variables escape block boundaries (returned from functions, stored in globals, etc.)

Developers can reorder field definitions to optimize memory layout. The memory layout is exposed through the abstraction of type declarations, giving developers control over data organization.

## Function System Extensions

### Function Overloading

*[Placeholder for future function overloading specification]*

Function overloading capabilities will be defined in future iterations of the language specification.

### Interface Implementation

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

### Use Statements and Imports

The `use` statement creates locally scoped references to imported types and functions:

```novo
use types.{request, response}
// Equivalent to declaring:
// request := types.request
// response := types.response
```

This brings the specified types into the current scope as if they were locally declared variables.

### Import/Export Granularity

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

### Component Composition and Naming Conflicts

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

## Meta Functions

Novo provides a meta function system for common operations on types using the `::` syntax. Meta functions are compiler-implemented features that provide standardized operations for all types.

### Meta Function Syntax

Meta functions use the `::` operator and can be called with or without parentheses:

```novo
x : u8 = 24
size := x::size()       // Traditional call syntax
size := x::size         // Paren-less syntax (equivalent)
```

### Built-in Meta Functions

#### Universal Meta Functions
Available on all types with identifiers:

- `::type()` → `string` - Returns the type name as a string literal (compile-time)

```novo
func my-function() { /* ... */ }
record user { name: string }

func-type := my-function::type()    // Returns "func"
user-type := user::type()           // Returns "record"
variable : u32 = 42
var-type := variable::type()        // Returns "u32"
```

#### Numeric Type Meta Functions
Available on all numeric types (`s8`, `s16`, `s32`, `s64`, `u8`, `u16`, `u32`, `u64`, `f32`, `f64`):

- `::size()` → `u32` - Returns the byte size of the type
- `::u8()`, `::u16()`, `::u32()`, `::u64()` - Convert to unsigned integer types
- `::s8()`, `::s16()`, `::s32()`, `::s64()` - Convert to signed integer types
- `::f32()`, `::f64()` - Convert to floating-point types

```novo
x : u8 = 24
byte-size := x::size()      // Returns 4 (u32 value - WASM storage size)
as-u32 := x::u32()          // Convert u8 to u32

// Meta functions also work on type names
type-size := u32::size()    // Returns 4 (u32 value)
type-name := u32::type()    // Returns "u32" (string)
```

#### String Meta Functions
Available on `string` and `char` types:

- `::size()` → `u32` - Returns the length in bytes (for strings) or UTF-8 byte count (for chars)

#### Record Meta Functions
Available on `record` types:

- `::size()` → `u32` - Returns total memory size (sum of all field sizes)

#### Resource Meta Functions
Available on `resource` types:

- `::new()` - Calls the resource constructor
- `::destroy()` - Performs resource cleanup/destruction

```novo
resource file-handle {
    constructor(path: string) -> result<file-handle, io-error>
    // ... methods
}

// Using meta functions
handle := file-handle::new("/path/to/file")
handle::destroy()       // Cleanup
size := handle::size()  // Total size including base-file data
```

### Meta Function Characteristics

- **Compiler-implemented**: Meta functions are built into the compiler, not user-definable
- **Non-extendable**: Developers cannot add custom meta functions
- **Compile-time resolution**: Many meta functions (like `::name()`) are resolved at compile time
- **Type-specific**: Different types have different available meta functions

### Generic Type Meta Functions

The `::type()` meta function works with generic types by returning the complete parameterized type name:

```novo
success : result<string, error> = ok("hello")
failure : result<string, error> = error("oops")

success_type := success::type()    // Returns "result<string, error>"
failure_type := failure::type()    // Returns "result<string, error>"

// For comparison with simple types
number : u32 = 42
number_type := number::type()      // Returns "u32"
```

**Generic type behavior:**
- Returns complete generic type signature including parameters
- Type parameters are fully qualified (e.g., "result<string, io-error>")
- Uninstantiated generic types cannot use `::type()` (must be instantiated first)
- Custom generic types follow same pattern when supported

**Usage with type checking:**
```novo
func handle-value(val: result<string, error>) {
    if val::type() == "result<string, error>" {
        // Type-safe operations
    }
}
```

## Extension Inheritance in Meta Functions

When resources use extension/embedding, meta functions behave contextually:

```novo
resource base-file {
    func close() -> result
}

resource text-file {
    base-file                    // Extended resource
    func read-line() -> option<string>
}
```

**Meta function inheritance:**
- `::size()` - Includes size of extended resource data
- `::destroy()` - Calls full cleanup chain from most-derived to base resource
- `::new()` - Does not chain (each resource has its own constructor)
- `::type()` - Returns the specific resource type name, not the extended one

**Destroy chain example:**
```novo
resource base-resource {
    func cleanup() -> result
}

resource middle-resource {
    base-resource
    func validate() -> result
}

resource derived-resource {
    middle-resource
    func finalize() -> result
}

// Cleanup chain order when called
derived := derived-resource::new()
derived::destroy()  // Calls: derived cleanup → middle cleanup → base cleanup
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

**Usage patterns:**
```novo
// Minimal component without _start
component simple-math {
    export func add(a: u32, b: u32) -> u32 { a + b }
}

// Component with initialization
component database-connector {
    connection-pool : list<connection>

    func _start() {
        connection-pool = list::new()
        initialize-ssl()
        load-config()
    }

    export func query(sql: string) -> result<data, error>
    export func close() { cleanup-connections() }
}
```

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
## Future Features

This section outlines planned features and enhancements for future versions of the novo programming language.

### Language Features

#### Generic Types and Functions
Support for user-defined generic types and functions:

```novo
// Future generic function syntax
func<T> process-list(items: list<T>, processor: func(T) -> T) -> list<T> {
    // Implementation
}

// Future generic record syntax
record<T> container {
    value: T,
    metadata: string,
}
```

#### Function Overloading
Multiple function definitions with the same name but different parameter types:

```novo
func process(data: string) -> string {
    // String processing
}

func process(data: list<u8>) -> list<u8> {
    // Binary data processing
}
```

#### Advanced Pattern Matching
Extended pattern matching capabilities:

```novo
// Pattern matching on ranges
match age {
    0..=12 => "child",
    13..=19 => "teenager",
    20..=64 => "adult",
    65.. => "senior",
}

// Pattern matching on arrays/lists
match numbers {
    [first, ..rest] => process-with-head(first, rest),
    [] => handle-empty(),
}
```

#### For Loops and Iterators
Comprehensive iteration support:

```novo
for item in collection {
    process(item)
}

for (index, value) in collection.enumerate() {
    log("Item " + index.to-string() + ": " + value.to-string())
}

for i in 0..10 {
    log("Count: " + i.to-string())
}
```

#### Async/Await Support
Asynchronous programming model compatible with WASM async proposals:

```novo
async func fetch-data(url: string) -> result<string, http-error> {
    response := await http-get(url)?
    content := await response.text()?
    return ok(content)
}
```

#### Const Expressions and Compile-Time Evaluation
Enhanced compile-time computation:

```novo
const MAX_BUFFER_SIZE: u32 = 1024 * 1024
const VERSION_STRING: string = "v" + MAJOR_VERSION.to-string() + "." + MINOR_VERSION.to-string()

func process-buffer() {
    buffer: [u8; MAX_BUFFER_SIZE] = [0; MAX_BUFFER_SIZE]
    // ...
}
```

### Tooling and Development Experience

#### IDE Language Server
Full IDE support with:
- Syntax highlighting
- Code completion
- Error diagnostics
- Go-to-definition
- Refactoring tools
- Inline documentation

#### Build System Enhancements
Advanced build features:
- Incremental compilation
- Parallel compilation of modules
- Dependency graph optimization
- Custom build scripts and plugins

#### Testing Framework
Built-in testing support:

```novo
#[test]
func test-addition() {
    result := add(2, 3)
    assert-eq(result, 5)
}

#[test]
func test-error-handling() {
    result := divide(10, 0)
    match result {
        error(_) => {}, // Expected
        ok(_) => panic("Expected division by zero error"),
    }
}
```

### Performance and Optimization

#### Advanced Compiler Optimizations
- Dead code elimination
- Constant folding and propagation
- Loop optimization
- Inlining heuristics
- SIMD instruction generation

#### Memory Management Enhancements
- Escape analysis for stack allocation
- Memory pool management
- Automatic resource cleanup tracking
- Linear memory optimization

#### Profile-Guided Optimization
Runtime profiling integration for:
- Hot path identification
- Branch prediction optimization
- Memory layout optimization
- Function inlining decisions

### WebAssembly Integration

#### WASI Integration
Full WebAssembly System Interface support:
- File system access
- Network operations
- Environment variables
- Command-line arguments

#### Component Model Evolution
Support for emerging Component Model features:
- Component composition patterns
- Resource sharing between components
- Advanced interface types
- Component versioning and migration

#### Browser API Integration
Direct browser API bindings:
- DOM manipulation
- Web APIs (fetch, storage, etc.)
- WebGL/WebGPU integration
- Service Worker support

### Experimental Features

#### Formal Verification
Integration with verification tools:
- Pre/post condition assertions
- Loop invariants
- Property-based testing
- Static analysis integration

#### Machine Learning Integration
WebAssembly-compatible ML frameworks:
- ONNX model execution
- TensorFlow Lite integration
- Edge computing optimizations

### Timeline and Priorities

**Phase 1 (v0.2.0)**: Core language completion
- Pattern matching
- Control flow
- Default values
- Basic error handling

**Phase 2 (v0.3.0)**: Developer experience
- IDE tooling
- Testing framework
- Enhanced error messages
- Documentation generation

**Phase 3 (v0.4.0)**: Advanced features
- Generic types
- Function overloading
- Advanced pattern matching
- Performance optimizations

**Phase 4 (v1.0.0)**: Production readiness
- Stable ABI
- Comprehensive standard library
- Package management
- Production tooling

**Future Phases**: Experimental and emerging features based on WebAssembly ecosystem evolution and community feedback.

### Community Input

Feature priorities and design decisions will be influenced by:
- Community feedback and usage patterns
- WebAssembly specification evolution
- Real-world use case requirements
- Performance benchmarking results

Contributors and users are encouraged to participate in the RFC process for major language features and design decisions.
