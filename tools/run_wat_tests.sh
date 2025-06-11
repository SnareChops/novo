#!/bin/zsh

# WAT Test Runner Script
# Compiles and runs WebAssembly core modules using wasm-tools

set -e  # Exit on any error

# Directory setup
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$PROJECT_ROOT/src"
TEST_DIR="$PROJECT_ROOT/tests/unit"
BUILD_DIR="$PROJECT_ROOT/build"

# Ensure build directory exists
mkdir -p "$BUILD_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "${YELLOW}Compiling WAT modules...${NC}"

# Compile all WAT files as core modules
compile_module() {
    local src="$1"
    local out="$2"
    echo "Compiling $(basename $src)..."

    # Parse WAT to wasm
    wasm-tools parse "$src" -o "$out" || {
        echo "${RED}Failed to parse $(basename $src)${NC}"
        return 1
    }
}

# Compile all modules in dependency order
compile_module "$SRC_DIR/memory.wat" "$BUILD_DIR/memory.wasm"
compile_module "$SRC_DIR/keywords.wat" "$BUILD_DIR/keywords.wasm"
compile_module "$SRC_DIR/lexer.wat" "$BUILD_DIR/lexer.wasm"
compile_module "$SRC_DIR/parser.wat" "$BUILD_DIR/parser.wasm"
compile_module "$TEST_DIR/lexer_test.wat" "$BUILD_DIR/lexer_test.wasm"
compile_module "$TEST_DIR/parser_test.wat" "$BUILD_DIR/parser_test.wasm"

echo "${YELLOW}Running tests...${NC}"

cd "$BUILD_DIR"

# Run lexer tests
echo "${YELLOW}Running lexer tests...${NC}"
wasmtime \
    --preload memory=memory.wasm \
    --preload keywords=keywords.wasm \
    --preload lexer=lexer.wasm \
    -W multi-value=y \
    -W reference-types=y \
    lexer_test.wasm \
    --invoke test || {
        echo "${RED}Lexer tests failed!${NC}"
        exit 1
    }

# Run parser tests
echo "${YELLOW}Running parser tests...${NC}"
wasmtime \
    --preload memory=memory.wasm \
    --preload keywords=keywords.wasm \
    --preload lexer=lexer.wasm \
    --preload parser=parser.wasm \
    -W multi-value=y \
    -W reference-types=y \
    parser_test.wasm \
    --invoke test || {
        echo "${RED}Parser tests failed!${NC}"
        exit 1
    }

echo "${GREEN}All tests passed successfully!${NC}"
