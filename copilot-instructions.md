# GitHub Copilot Instructions for Novo Compiler Project

## Critical Project Requirements

### Test Completion Criteria
**🚨 CRITICAL**: A step or phase can ONLY be marked as "COMPLETED" when ALL tests in the entire project are passing, not just the tests related to the specific feature being implemented.

- Before marking any step as complete, run the full test suite: `tools/run_wat_tests.sh`
- All tests must pass (100% success rate) before proceeding to the next step
- If any tests fail after implementing a new feature, those failures must be fixed before the step can be considered complete
- This ensures no regressions are introduced and the entire project remains stable

Recent fixes applied:
- Fixed `is_keyword` function in `src/lexer/keywords.wat` (keyword recognition)
- Fixed `scan_identifier` return value handling in `src/lexer/main.wat` (identifier tokenization infinite loop)

### Implementation Guidelines

1. **Modular Architecture**: All files must stay under 300 lines for maintainability
2. **Test-Driven Development**: Write tests for new functionality and ensure all existing tests continue to pass
3. **No Breaking Changes**: New features must not break existing functionality
4. **Progressive Enhancement**: Build incrementally, testing after each change

### WebAssembly Text Format (.wat) Standards

- Use consistent 2-space indentation
- Add meaningful comments for complex operations
- Use descriptive function and variable names
- Follow established memory layout patterns
- Document any performance-critical sections

### Build System Integration

- New modules must be added to build order in `tools/run_wat_tests.sh`
- Proper preload mappings must be configured for module dependencies
- Module exports/imports must be correctly defined
- Test files must follow established naming conventions

### Quality Gates

- **Compilation**: All .wat files must compile without errors
- **Testing**: 100% test pass rate required for completion
- **Integration**: New modules must integrate cleanly with existing systems
- **Documentation**: Update plan.md and relevant documentation when completing steps
- **Validation**: Use `wasmtime` for WASM validation and execution

### Error Handling

- Provide clear, actionable error messages
- Handle edge cases gracefully
- Validate inputs and return appropriate error codes
- Test error conditions as thoroughly as success conditions

### Memory Management

- Follow established memory layout patterns from existing modules
- Use appropriate memory regions for different data types
- Implement proper cleanup and resource management
- Document memory usage and alignment requirements

Remember: **NO STEP IS COMPLETE UNTIL ALL TESTS PASS** ✅
