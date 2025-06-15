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
)

for pair in "${build_modules[@]}"; do
  src="${pair%%:*}"
  out="${pair##*:}"
  echo "Compiling $src..."
  wat2wasm --enable-all "$SRC_DIR/$src.wat" -o "$BUILD_DIR/$out.wasm" || exit 1
done

# Compile test modules
echo "Compiling test modules..."
for test in "$TEST_DIR"/*.wat; do
  base=$(basename "$test" .wat)
  echo "Compiling $base..."
  wat2wasm --enable-all "$test" -o "$BUILD_DIR/$base.wasm" || exit 1
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
  "lexer_operators=lexer-operators.wasm"
  "lexer_identifiers=lexer-identifiers.wasm"
  "novo_lexer=lexer-main.wasm"
  "ast_node_types=ast-node-types.wasm"
  "ast_memory=ast-memory.wasm"
  "ast_node_core=ast-node-core.wasm"
  "ast_node_creators=ast-node-creators.wasm"
)
preload_args=()
for preload in "${preloads[@]}"; do
  preload_args+=("--preload" "$preload")
done

cd "$BUILD_DIR"

# Sort test modules so core tests run first
test_files=($(find . -maxdepth 1 -name '*-test.wasm' | sort))

# Run tests in order
for test in "${test_files[@]}"; do
  if [[ -f "$test" ]]; then
    test_name=$(basename "$test" .wasm)
    echo "Running $test_name..."
    wasmtime run \
      --wasm all-proposals=y \
      --dir . \
      "${preload_args[@]}" \
      "$test"
  fi
done

echo "All tests completed"
