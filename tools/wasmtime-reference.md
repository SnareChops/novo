# Wasmtime Test Configuration Reference

## Module Compilation and Testing

This document outlines how to properly compile and run WebAssembly modules for testing, specifically focusing on modules with imports/exports.

### Compilation Process

1. **WAT to WASM Compilation**
   ```bash
   wat2wasm [source.wat] -o [output.wasm] --enable-all
   ```
   - Use `--enable-all` to support all WebAssembly features
   - Produces a binary WebAssembly module

2. **Module Dependencies**
   - Compile modules in dependency order
   - Core module (e.g., novo-lexer.wat) must be compiled before test module

### Running Tests with Module Imports

When running tests where one module imports from another (e.g., test module importing from lexer module), use the following wasmtime configuration:

```bash
wasmtime run \
  --wasm all-proposals=y \       # Enable all WebAssembly proposals
  --dir . \                      # Allow access to current directory
  --preload novo_lexer=novo-lexer.wasm \ # Preload the lexer module
  novo-lexer-test.wasm \        # Main test module
  --invoke test_function_name    # Function to invoke
```

### Key Parameters

1. **Module Preloading**
   - `--preload NAME=MODULE_PATH`: Load dependencies before main module
   - Format: `module_name=path_to_module.wasm`

2. **Function Invocation**
   - `--invoke FUNCTION`: Specify function to run
   - Function must be exported by the module

3. **WebAssembly Features**
   - `--wasm all-proposals=y`: Enable all WebAssembly features
   - Specific features can be enabled individually:
     - `--wasm multi-value=y`: For multi-value returns
     - `--wasm reference-types=y`: For reference types
     - `--wasm bulk-memory=y`: For bulk memory operations

4. **Directory Access**
   - `--dir .`: Allow access to current directory
   - Format: `--dir HOST_DIR::GUEST_DIR` for custom mapping

### Example Test Configuration

For a test setup with:
- Core module: `novo-lexer.wasm`
- Test module: `novo-lexer-test.wasm`
- Test function: `test_operators`

```bash
wasmtime run \
  --wasm all-proposals=y \
  --dir . \
  --preload novo_lexer=novo-lexer.wasm \
  novo-lexer-test.wasm \
  --invoke test_operators
```

### Troubleshooting

1. **Module Not Found**
   - Ensure modules are in the correct directory
   - Check module names match import statements
   - Verify file permissions

2. **Import Resolution Failures**
   - Verify export names in core module match import names
   - Check function signatures match between modules
   - Enable required WebAssembly features

3. **Memory Access Issues**
   - Use `--dir` to grant filesystem access
   - Check memory limits and sharing configuration

### Best Practices

1. **Module Organization**
   - Keep core and test modules in separate files
   - Use clear naming conventions
   - Document module dependencies

2. **Testing Strategy**
   - Test one function at a time
   - Handle cleanup between tests
   - Use descriptive function names

3. **Error Handling**
   - Check return values
   - Handle trap conditions
   - Log test failures clearly
