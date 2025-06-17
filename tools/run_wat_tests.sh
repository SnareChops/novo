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

# Create build directory
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
  "ast/node-creators:ast-node-creators"
  "ast/main:ast-main"

  # Parser modules (dependencies first)
  "parser/precedence:parser-precedence"
  "parser/utils:parser-utils"
  "parser/types:parser-types"
  "parser/functions:parser-functions"
  "parser/control-flow:parser-control-flow"
  "parser/patterns:parser-patterns"
  "parser/expression-core:parser-expression-core"
  "parser/main:parser-main"
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
  "ast_node_creators=ast-node-creators.wasm"
  "parser_precedence=parser-precedence.wasm"
  "parser_utils=parser-utils.wasm"
  "parser_types=parser-types.wasm"
  "parser_functions=parser-functions.wasm"
  "parser_control_flow=parser-control-flow.wasm"
  "parser_main=parser-main.wasm"
  "parser_expression_core=parser-expression-core.wasm"
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
    $(find . -maxdepth 2 -path './lexer/*' -name '*-test.wasm' | sort)
    $(find . -path './ast/*' -name '*-test.wasm' | sort)
    $(find . -path './parser/*' -name '*-test.wasm' | sort)
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

    # Capture both stdout and stderr
    if output=$(wasmtime run \
      --wasm all-proposals=y \
      --dir . \
      "${preload_args[@]}" \
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
