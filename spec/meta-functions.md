# Meta Functions

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
- `::string()` → `string` - Returns a string representation of the value (runtime)

```novo
func my-function() { /* ... */ }
record user { name: string }

func-type := my-function::type()    // Returns "func"
user-type := user::type()           // Returns "record"
variable : u32 = 42
var-type := variable::type()        // Returns "u32"

// String representation of values
number := 42
number-str := number::string()      // Returns "42"

user-obj := user { name: "Alice" }
user-str := user-obj::string()      // Returns "{name: \"Alice\"}"

status : option<string> = some("active")
status-str := status::string()      // Returns "some(\"active\")"
```

**::string() behavior:**
- For primitives: returns standard string representation
- For records: returns field-value pairs in brace notation
- For variants: returns case name with associated data
- For lists: returns comma-separated values in brackets
- For options/results: returns constructor name with contents

#### Numeric Type Meta Functions
Available on all numeric types (`s8`, `s16`, `s32`, `s64`, `i8`, `i16`, `i32`, `i64`, `u8`, `u16`, `u32`, `u64`, `f32`, `f64`):

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

### Tags System with Meta Function Access

Novo supports adding tags to types for metadata annotation and runtime identification:

```novo
// Tagged type declarations
record user {
    id      u32     `required`
    name    string  `required`
    email   string
}

variant status {
    pending
    running(u32)        `task id`
    completed(string)   `result`
    failed(string)      `error message`
}

enum priority {
    low         `json:"low"`
    medium      `json:"medium"`
    high        `json:"high"`
    critical    `json:"critical"`
}

resource file-handle `something` {
    constructor(path: string) -> result<file-handle, io-error>
    // ... methods
}
```

**Tag access via ::tag() meta function:**
```novo
// Check if type has specific tag
user-obj : user = user { id: 123, name: "Alice", email: "alice@example.com" }

if user-obj::tag() == "persist" {
    // This type represents a database entity
    persist-to-database(user-obj)
}

if user-obj::tag() == "serializable" {
    // This type can be serialized
    json-data := serialize-to-json(user-obj)
}
```

**Tag characteristics:**
- Tags are compile-time annotations that can be checked at runtime
- Tag checking is optimized to compile-time constants where possible

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


## Cross-References

- See [Basic Types](basic-types.md) for type system foundations used in generics
- See [Complex Types](complex-types.md) for generic type applications
- See [Functions and Control Flow](functions-control-flow.md) for generic function patterns
- See [Advanced Features](advanced-features.md) for related meta-programming features
