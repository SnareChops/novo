#!/bin/zsh

# WAT Test Runner Script
# Compiles and runs WebAssembly core modules

set -e  # Exit on any error

# Directory setup
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$PROJECT_ROOT/src"
TEST_DIR="$PROJECT_ROOT/tests/unit"
BUILD_DIR="$PROJECT_ROOT/build"

# Optional test directory filter from command line argument
if [[ $# -gt 0 ]]; then
  TEST_FILTER="$1"
  # Convert absolute path to relative if needed
  if [[ "$TEST_FILTER" == /* ]]; then
    TEST_FILTER=$(realpath --relative-to="$PROJECT_ROOT" "$TEST_FILTER")
  fi
  echo "Filtering tests to: $TEST_FILTER"
else
  TEST_FILTER=""
fi

# Clear and recreate build directory for fresh build
echo "Clearing build directory for fresh build..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "Compiling WAT modules..."

# Compile modules in dependency order
echo "Compiling modules in dependency order..."
typeset -a build_modules
build_modules=(
  # Memory management first
  "lexer/memory:lexer-memory"

  # Token definitions and core utilities
  "lexer/tokens:lexer-tokens"
  "lexer/char-utils:lexer-char-utils"

  # Token storage must come before identifiers
  "lexer/token-storage:lexer-token-storage"

  # Keywords must come before identifiers
  "lexer/keywords:lexer-keywords"

  # Lexer processing modules
  "lexer/operators:lexer-operators"
  "lexer/identifiers:lexer-identifiers"
  "lexer/main:lexer-main"

  # AST modules
  "ast/node-types:ast-node-types"
  "ast/memory:ast-memory"
  "ast/node-core:ast-node-core"
  # Split AST node creators
  "ast/type-creators:ast-type-creators"
  "ast/expression-creators:ast-expression-creators"
  "ast/control-flow-creators:ast-control-flow-creators"
  "ast/pattern-creators:ast-pattern-creators"
  "ast/declaration-creators:ast-declaration-creators"
  "ast/node-creators:ast-node-creators"
  "ast/main:ast-main"

  # Parser modules (dependencies first)
  "parser/precedence:parser-precedence"
  "parser/utils:parser-utils"
  "parser/types:parser-types"
  "parser/functions:parser-functions"
  "parser/control-flow:parser-control-flow"
  "parser/patterns:parser-patterns"
  "parser/components:parser-components"
  # Split parser expression modules
  "parser/expression-utilities:parser-expression-utilities"
  "parser/expression-parsing:parser-expression-parsing"
  "parser/expression-core:parser-expression-core"
  "parser/main:parser-main"

  # Type checker modules
  "typechecker/main:typechecker-main"
  "typechecker/expressions:typechecker-expressions"
  # Split typechecker pattern modules
  "typechecker/pattern-matching:typechecker-pattern-matching"
  "typechecker/pattern-validation:typechecker-pattern-validation"

  # Meta functions modules (depend on type checker and AST)
  "meta-functions/core:meta-functions-core"
  "meta-functions/numeric:meta-functions-numeric"
  "meta-functions/memory:meta-functions-memory"
  "meta-functions/record:meta-functions-record"
  "meta-functions/resource:meta-functions-resource"
  "meta-functions/main:meta-functions-main"

  # Code generation modules (depend on type checker, AST, and meta functions)
  "codegen/core:codegen-core"
  "codegen/module:codegen-module"
  "codegen/functions:codegen-functions"
  "codegen/stack:codegen-stack"
  "codegen/expressions:codegen-expressions"
  "codegen/control-flow:codegen-control-flow"
  "codegen/patterns:codegen-patterns"
  "codegen/error-handling:codegen-error-handling"
  "codegen/main:codegen-main"

  # Binary code generation modules (Phase 7.3 - Binary WASM output correction)
  "codegen/binary/leb128:leb128-encoder"
  "codegen/binary/instructions:instruction-encoder"
  "codegen/binary/sections:section-generator"
  "codegen/binary/encoder:binary-encoder"
  "codegen/binary_main:codegen-binary-main"
)

for pair in "${build_modules[@]}"; do
  src="${pair%%:*}"
  out="${pair##*:}"
  echo "Compiling $src..."
  wat2wasm --enable-all "$SRC_DIR/$src.wat" -o "$BUILD_DIR/$out.wasm" || exit 1
done

# Compile test modules from nested directory structure
echo "Compiling test modules..."
find "$TEST_DIR" -name "*.wat" -type f | while read test; do
  # Calculate relative path from TEST_DIR for maintaining directory structure
  rel_path=$(realpath --relative-to="$TEST_DIR" "$test")
  rel_dir=$(dirname "$rel_path")
  base=$(basename "$test" .wat)

  # Create nested directory structure in build folder
  mkdir -p "$BUILD_DIR/$rel_dir"

  echo "Compiling $rel_path..."
  wat2wasm --enable-all "$test" -o "$BUILD_DIR/$rel_dir/$base.wasm" || exit 1
done

# Run tests
echo "Running tests..."

# Define preload modules in dependency order
typeset -a preloads
preloads=(
  "memory=lexer-memory.wasm"
  "lexer_memory=lexer-memory.wasm"
  "tokens=lexer-tokens.wasm"
  "lexer_tokens=lexer-tokens.wasm"
  "char_utils=lexer-char-utils.wasm"
  "lexer_char_utils=lexer-char-utils.wasm"
  "lexer_token_storage=lexer-token-storage.wasm"
  "keywords=lexer-keywords.wasm"
  "lexer_keywords=lexer-keywords.wasm"
  "operators=lexer-operators.wasm"
  "lexer_operators=lexer-operators.wasm"
  "lexer_identifiers=lexer-identifiers.wasm"
  "novo_lexer=lexer-main.wasm"
  "ast_node_types=ast-node-types.wasm"
  "ast_memory=ast-memory.wasm"
  "ast_node_core=ast-node-core.wasm"
  # Split AST node creator modules
  "ast_type_creators=ast-type-creators.wasm"
  "ast_expression_creators=ast-expression-creators.wasm"
  "ast_control_flow_creators=ast-control-flow-creators.wasm"
  "ast_pattern_creators=ast-pattern-creators.wasm"
  "ast_declaration_creators=ast-declaration-creators.wasm"
  "ast_node_creators=ast-node-creators.wasm"
  "parser_precedence=parser-precedence.wasm"
  "parser_utils=parser-utils.wasm"
  "parser_types=parser-types.wasm"
  # Split parser expression modules (dependencies first)
  "novo_parser_expression_utilities=parser-expression-utilities.wasm"
  "parser_expression_parsing=parser-expression-parsing.wasm"
  "parser_expression_core=parser-expression-core.wasm"
  "parser_functions=parser-functions.wasm"
  "parser_control_flow=parser-control-flow.wasm"
  "parser_components=parser-components.wasm"
  "parser_main=parser-main.wasm"
  # Typechecker modules (main must come before pattern modules)
  "typechecker_main=typechecker-main.wasm"
  "typechecker_expressions=typechecker-expressions.wasm"
  # Split typechecker pattern modules
  "typechecker_pattern_matching=typechecker-pattern-matching.wasm"
  "typechecker_pattern_validation=typechecker-pattern-validation.wasm"
  # Meta functions modules (depend on typechecker and AST)
  "meta_functions_core=meta-functions-core.wasm"
  "meta_functions_numeric=meta-functions-numeric.wasm"
  "meta_functions_memory=meta-functions-memory.wasm"
  "meta_functions_record=meta-functions-record.wasm"
  "meta_functions_resource=meta-functions-resource.wasm"
  "meta_functions_main=meta-functions-main.wasm"
  # Code generation modules (depend on typechecker, AST, and meta functions)
  "codegen_core=codegen-core.wasm"
  "codegen_module=codegen-module.wasm"
  "codegen_functions=codegen-functions.wasm"
  "codegen_stack=codegen-stack.wasm"
  "codegen_expressions=codegen-expressions.wasm"
  "codegen_control_flow=codegen-control-flow.wasm"
  "codegen_patterns=codegen-patterns.wasm"
  "codegen_error_handling=codegen-error-handling.wasm"
  "codegen_main=codegen-main.wasm"
  # Binary code generation modules (Phase 7.3 - Binary WASM output correction)
  "leb128_encoder=leb128-encoder.wasm"
  "instruction_encoder=instruction-encoder.wasm"
  "section_generator=section-generator.wasm"
  "binary_encoder=binary-encoder.wasm"
  "codegen_binary_main=codegen-binary-main.wasm"
)
preload_args=()
for preload in "${preloads[@]}"; do
  preload_args+=("--preload" "$preload")
done

cd "$BUILD_DIR"

# Find all test files in nested directory structure and sort them
# Run lexer tests first, then AST, then parser
if [[ -n "$TEST_FILTER" ]]; then
  # Filter tests based on the provided directory or file
  filter_path="${TEST_FILTER#tests/unit/}"
  echo "Using filter path: $filter_path"

  # Check if filter is a specific file
  if [[ "$filter_path" == *.wat ]]; then
    # Handle specific file - convert .wat to .wasm and find it
    base_name=$(basename "$filter_path" .wat)
    dir_path=$(dirname "$filter_path")
    test_files=(
      $(find . -path "./$dir_path/$base_name.wasm" | sort)
    )
  else
    # Handle directory filter
    test_files=(
      $(find . -path "./$filter_path*" -name '*-test.wasm' | sort)
    )
  fi

  echo "Found ${#test_files[@]} test files matching filter: $TEST_FILTER"
  if [[ ${#test_files[@]} -gt 0 ]]; then
    echo "Test files found:"
    for tf in "${test_files[@]}"; do
      echo "  $tf"
    done
  fi
else
  test_files=(
    $(find . -path './lexer/char-utils/*' -name '*-test.wasm' | sort)
    $(find . -path './lexer/keywords/*' -name '*-test.wasm' | sort)
    $(find . -path './lexer/operators/*' -name '*-test.wasm' | sort)
    $(find . -path './lexer/token-storage/*' -name '*-test.wasm' | sort)
    $(find . -path './lexer/identifiers/*' -name '*-test.wasm' | sort)
    $(find . -path './lexer/memory/*' -name '*-test.wasm' | sort)
    $(find . -maxdepth 2 -path './lexer/*' -name '*-test.wasm' | sort)
    $(find . -path './ast/*' -name '*-test.wasm' | sort)
    $(find . -path './parser/*' -name '*-test.wasm' | sort)
    $(find . -path './typechecker/*' -name '*-test.wasm' | sort)
    $(find . -path './meta-functions/*' -name '*-test.wasm' | sort)
    $(find . -path './codegen/*' -name '*-test.wasm' | sort)
  )
fi

# Run tests in dependency order
total_tests=0
passed_tests=0
failed_tests=0
typeset -a failed_test_names

echo "=========================================="
echo "           RUNNING TESTS"
echo "=========================================="

for test in "${test_files[@]}"; do
  if [[ -f "$test" ]]; then
    test_name=$(basename "$test" .wasm)
    rel_path=$(echo "$test" | sed 's|^\./||')

    total_tests=$((total_tests + 1))

    echo ""
    echo "[$total_tests] Running test: $test_name"
    echo "    Path: $rel_path"
    echo -n "    Status: "

    # Check if this is a pattern matching test and add required modules
    pattern_preload_args=()
    if [[ "$test_name" == *"pattern-matching"* || "$test_name" == *"pattern"* ]]; then
      pattern_preload_args+=("--preload" "parser_patterns=parser-patterns.wasm")
    fi

    # Check if this is a typechecker test and add required modules
    typechecker_preload_args=()
    # Note: Removed typechecker preloads to avoid duplicate import conflicts
    # wasmtime will automatically resolve dependencies
    if [[ "$test_name" == *"typechecker"* || "$test_name" == *"type-checking"* || "$test_name" == *"type-checker"* ]]; then
      # Let wasmtime handle dependencies automatically
      :
    fi

    # Capture both stdout and stderr
    if output=$(wasmtime run \
      --wasm all-proposals=y \
      --dir . \
      "${preload_args[@]}" \
      "${pattern_preload_args[@]}" \
      "${typechecker_preload_args[@]}" \
      "$test" 2>&1); then
      echo "✅ PASS"
      passed_tests=$((passed_tests + 1))
      # Show output if test produces any
      if [[ -n "$output" ]]; then
        echo "    Output: $output"
      fi
    else
      echo "❌ FAIL"
      failed_tests=$((failed_tests + 1))
      failed_test_names+=("$test_name")
      echo "    Error: $output"
    fi
  fi
done

echo ""
echo "=========================================="
echo "           TEST SUMMARY"
echo "=========================================="
echo "Total tests run: $total_tests"
echo "Passed: $passed_tests"
echo "Failed: $failed_tests"

if [[ $failed_tests -gt 0 ]]; then
  echo ""
  echo "Failed tests:"
  for failed_test in "${failed_test_names[@]}"; do
    echo "  - $failed_test"
  done
  echo ""
  echo "❌ Some tests failed!"
  exit 1
else
  echo ""
  echo "✅ All tests passed!"
fi
