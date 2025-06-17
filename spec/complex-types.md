# Complex Types

## Lists

Lists represent ordered collections of elements of the same type:

```novo
numbers := list<u32>{}
names : list<string> = {"Alice", "Bob", "Charlie"}

// List operations
numbers.append(42)
first-name := names[0]
length := names.length
```

## Options

Options represent values that may or may not be present:

```novo
maybe-value : option<string> = some{"hello"}
empty-value : option<string> = none

// Pattern matching with options
message := match maybe-value {
    some{value} => "Got: " + value
    none => "No value"
}
```

## Results

Results represent operations that may succeed or fail:

```novo
operation-result : result<string, error> = ok{"success"}
failed-result : result<string, error> = error{"something went wrong"}

// Error handling through pattern matching
processed := match operation-result {
    ok{value} => process-success(value)
    error{err} => handle-error(err)
}
```

## Tuples

Tuples group a fixed number of values of potentially different types:

```novo
point : tuple<f32, f32> = {3.14, 2.71}
person : tuple<string, u32, bool> = {"Alice", 30, true}

// Destructuring tuples
{x, y} := point
{name, age, active} := person
```

## Records

Records define structured data with named fields:

```novo
record user {
    id: u32
    name: string
    email: string
    active: bool = true  // Default value
}

// Creating records
alice := user {
    id: 1,
    name: "Alice",
    email: "alice@example.com"
    // active uses default value
}

// Field access
user-id := alice.id
user-name := alice.name
```

### Record Field Default Values

Fields can have default values for ergonomic construction:

```novo
record config {
    host: string = "localhost"
    port: u16 = 8080
    ssl-enabled: bool = false
    timeout-ms: u32 = 5000
    name: string  // No default - must be provided
}

// Usage with defaults
cfg := config{ name: "my-app" }  // Uses all defaults except name
```

## Variants

Variants represent a value that can be one of several different types:

```novo
variant message {
    text{string}
    image{string, u32, u32}  // path, width, height
    audio{string, u32}       // path, duration
    empty
}

// Creating variants
text-msg := message.text{"Hello"}
image-msg := message.image{"/path/to/image.jpg", 800, 600}
empty-msg := message.empty

// Pattern matching variants
response := match text-msg {
    text{content} => "Text: " + content
    image{path, w, h} => "Image: " + path + " (" + w::string() + "x" + h::string() + ")"
    audio{path, duration} => "Audio: " + path + " (" + duration::string() + "s)"
    empty => "Empty message"
}
```

## Enums

Enums define a type with a fixed set of named values:

```novo
enum status {
    pending
    running
    completed
    failed
    cancelled
}

enum priority {
    low
    medium
    high
    critical
}

// Using enums
current-status := status.running
task-priority := priority.high
```

## Resources

Resources represent external or managed objects with explicit lifecycle control:

```novo
resource file-handle : file-state {
    constructor(path: string) -> result<file-handle, io-error>

    func read(bytes: u32) -> result<list<u8>, io-error>
    func write(data: list<u8>) -> result<u32, io-error>
    func close() -> result

    static func exists(path: string) -> bool
}

record file-state {
    path: string
    is-open: bool
}

// Using resources
handle := file-handle::new("/path/to/file")
data := handle.read(1024)
bytes-written := handle.write(data)

// Check state
state := handle::state()
if state.is-open {
    handle.close()
}

// Manual cleanup (optional - automatic when out of scope)
handle::destroy()
```

### Resource Declaration Pattern

Resources must be associated with a record or variant type:

```novo
// Resource with record association
resource database-connection : connection-info {
    constructor(url: string) -> result<database-connection, db-error>
    func query(sql: string) -> result<result-set, db-error>
}

record connection-info {
    url: string
    connected-at: u64
    pool-id: u32
}

// Resource with variant association
resource file-handle : file-state {
    constructor(path: string) -> result<file-handle, io-error>
    func read() -> result<string, io-error>
}

variant file-state {
    open(string)     // file path
    closed
    error(string)    // error message
}
```

## Flags

Flags represent a set of named boolean values, efficiently stored as a bitfield:

```novo
flags permissions {
    read
    write
    execute
    delete
}

flags allowed-methods {
    get
    post
    put
    delete
}

// Using flags
file-perms := permissions.read | permissions.write
api-methods := allowed-methods.get | allowed-methods.post
```

## Type Aliases

Create meaningful names for complex or commonly used types:

```novo
type buffer = list<u8>
type http-result = result<http-response, http-error>
type user-id = u32
type coordinate = tuple<f32, f32>

// Usage
user-data : buffer = {72, 101, 108, 108, 111}  // "Hello" in bytes
api-response : http-result = ok{response-data}
current-user : user-id = 12345
position : coordinate = {10.5, 20.7}
```

## Memory Layout

Records, variants, and lists use packed layout for efficient memory usage:

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
- **Linear memory allocation**: When variables escape block boundaries

## String and Character Implementation

Strings are UTF-8 byte sequences with a 4-byte length prefix:

```
[length: i32][utf8_bytes...]
```

Characters represent Unicode scalar values stored as UTF-8 encoding.
