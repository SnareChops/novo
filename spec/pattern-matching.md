# Pattern Matching

Pattern matching in novo provides a powerful way to destructure and match against variant types, options, results, and other complex data structures.

## Match Statements

The `match` statement allows pattern matching against values:

```novo
variant message {
    text(string)
    image(string, u32, u32)  // path, width, height
    audio(string, u32)       // path, duration
    empty
}

func process-message(msg: message) {
    match msg {
        text(content) => log("Text: " + content)
        image(path, w, h) => log("Image: " + path + " (" + w::string() + "x" + h::string() + ")")
        audio(path, duration) => log("Audio: " + path + " (" + duration::string() + "s)")
        empty => log("Empty message")
    }
}
```

## Pattern Matching with Results and Options

Pattern matching is particularly useful with `result` and `option` types:

```novo
func handle-file-operation() -> result<string, io-error> {
    file-content := read-file("/path/to/file")
    match file-content {
        ok(content) => {
            processed := process-content(content)
            return ok(processed)
        }
        error(err) => {
            log("Failed to read file: " + err::string())
            return error(err)
        }
    }
}

func process-optional-value(maybe-value: option<u32>) {
    match maybe-value {
        some(value) => {
            log("Got value: " + value::string())
            process-number(value)
        }
        none => {
            log("No value provided")
        }
    }
}
```

## Exhaustiveness Checking

The compiler enforces exhaustive pattern matching - all possible cases must be handled:

```novo
enum status {
    pending
    running
    completed
    failed
}

func handle-status(s: status) {
    match s {
        pending => log("Waiting to start")
        running => log("Currently executing")
        completed => log("Finished successfully")
        failed => log("Execution failed")
        // All cases covered - no default needed
    }
}
```

## Default Match Case with Exhaustiveness

When pattern matching is not exhaustive, a default case using `_` is required:

```novo
enum status {
    pending
    running
    completed
    failed
    cancelled
}

func handle-status(s: status) {
    match s {
        pending => log("Waiting to start")
        running => log("Currently executing")
        _ => log("Other status")  // Handles completed, failed, and cancelled
    }
}

// For variants with different arities
variant message {
    text(string)
    image(string, u32, u32)  // path, width, height
    video(string, u32)       // path, duration
    audio(string, u32)       // path, duration
}

func handle-message(msg: message) {
    match msg {
        text(content) => log("Text: " + content)
        _ => log("Media message")  // Handles image, video, and audio cases
    }
}
```

**Exhaustiveness checking rules:**
- If all possible cases are explicitly handled, no default case is needed
- If any case is missing, a `_` default case becomes mandatory
- The default case must be the last pattern in the match
- Compiler validates exhaustiveness at compile time

## Pattern Guards

Pattern guards allow additional conditions within patterns:

```novo
func categorize-number(n: s32) -> string {
    return match n {
        x if x > 100 => "large"
        x if x > 10 => "medium"
        x if x > 0 => "small"
        0 => "zero"
        _ => "negative"
    }
}

variant user-action {
    login(string)           // username
    purchase(string, u32)   // item, price
    view(string)           // page
}

func handle-action(action: user-action) {
    match action {
        login(username) if username.length > 0 => authenticate(username)
        login(_) => log("Invalid username")
        purchase(item, price) if price > 1000 => require-approval(item, price)
        purchase(item, price) => process-purchase(item, price)
        view(page) => track-page-view(page)
    }
}
```

**Guard limitations:**
- Guards must be boolean expressions
- Guards cannot call functions that may have side effects
- Guards are evaluated in order, first matching guard wins
- If no guard matches, the pattern fails and the next pattern is tried

## Destructuring Patterns

Records and tuples can be destructured in patterns:

```novo
record point {
    x: f32
    y: f32
}

func process-point(p: point) {
    match p {
        point { x: 0.0, y: 0.0 } => log("Origin point")
        point { x, y } if x == y => log("Diagonal point: " + x::string())
        point { x, y } => log("Point at (" + x::string() + ", " + y::string() + ")")
    }
}

func process-tuple(t: tuple<string, u32>) {
    match t {
        ("admin", _) => log("Admin user")
        (name, age) if age >= 18 => log("Adult: " + name)
        (name, age) => log("Minor: " + name + " (" + age::string() + ")")
    }
}
```

## Variable Binding in Patterns

Patterns can bind parts of the matched value to variables:

```novo
variant tree {
    leaf(s32)
    branch(tree, tree)
}

func sum-tree(t: tree) -> s32 {
    match t {
        leaf(value) => value
        branch(left, right) => sum-tree(left) + sum-tree(right)
    }
}

variant http-response {
    ok(u32, string)        // status, body
    redirect(u32, string)  // status, location
    error(u32, string)     // status, message
}

func handle-response(response: http-response) {
    match response {
        ok(200, body) => process-success(body)
        ok(status, body) => log("Success " + status::string() + ": " + body)
        redirect(_, location) => follow-redirect(location)
        error(status, message) => log("Error " + status::string() + ": " + message)
    }
}
```

## Wildcard Patterns

The `_` wildcard pattern matches anything without binding:

```novo
func handle-result(r: result<string, error>) {
    match r {
        ok(value) => process-value(value)
        error(_) => log("An error occurred")  // Don't care about specific error
    }
}

variant complex-data {
    simple(string)
    detailed(string, u32, bool, f32)
}

func extract-name(data: complex-data) -> string {
    match data {
        simple(name) => name
        detailed(name, _, _, _) => name  // Only care about the name field
    }
}
```

## Pattern Matching in Variable Declarations

Simple pattern matching can be used in variable declarations:

```novo
// Destructuring assignment
point { x, y } := get-point()
(name, age, active) := get-user-info()

// Option unwrapping (must be exhaustive)
some(value) := get-optional-value() else {
    log("No value available")
    return
}

// Result unwrapping
ok(data) := fetch-data() else {
    error(err) => {
        log("Failed to fetch: " + err::string())
        return
    }
}
```

## Error Propagation through Pattern Matching

Novo encourages explicit error handling through pattern matching rather than using a `?` operator:

```novo
func process-data() -> result<string, error> {
    // Read file
    file-content := read-file("/data.txt")
    data := match file-content {
        ok(content) => content
        error(err) => return error(err)  // Explicit error propagation
    }

    // Process data
    processed := process-string(data)
    result := match processed {
        ok(value) => value
        error(err) => return error(err)  // Explicit error propagation
    }

    return ok(result)
}

// Helper function for cleaner error propagation
func try-operation() -> result<string, error> {
    step1 := operation1()?  // Future syntax for automatic propagation
    step2 := operation2(step1)?
    step3 := operation3(step2)?
    return ok(step3)
}
```

This approach ensures all error paths are explicitly handled and visible in the code.
