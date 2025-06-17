#!/bin/zsh

# Comprehensive test runner that reports failures
set +e  # Don't exit on errors, we want to catch them

BUILD_DIR="/home/snare/repos/novo-ai/build"
cd "$BUILD_DIR"

echo "=== COMPREHENSIVE TEST ANALYSIS ==="
echo "Running all tests to identify failures..."
echo

# Define preload modules for different test types
declare -A PRELOADS
PRELOADS[char-utils]="--preload memory=lexer-memory.wasm --preload char_utils=lexer-char-utils.wasm"
PRELOADS[keywords]="--preload memory=lexer-memory.wasm --preload tokens=lexer-tokens.wasm --preload keywords=lexer-keywords.wasm"
PRELOADS[operators]="--preload memory=lexer-memory.wasm --preload char_utils=lexer-char-utils.wasm --preload tokens=lexer-tokens.wasm --preload operators=lexer-operators.wasm"
PRELOADS[token-storage]="--preload memory=lexer-memory.wasm --preload tokens=lexer-tokens.wasm --preload lexer_token_storage=lexer-token-storage.wasm"
PRELOADS[lexer]="--preload memory=lexer-memory.wasm --preload tokens=lexer-tokens.wasm --preload char_utils=lexer-char-utils.wasm --preload keywords=lexer-keywords.wasm --preload operators=lexer-operators.wasm --preload lexer_token_storage=lexer-token-storage.wasm --preload identifiers=lexer-identifiers.wasm --preload lexer_main=lexer-main.wasm"

PASSED=0
FAILED=0
FAILED_TESTS=()

# Function to run a test
run_test() {
    local test_file="$1"
    local test_type="$2"
    local test_name=$(basename "$test_file" .wasm)

    echo -n "Testing $test_name... "

    # Get preload args for this test type
    local preload_args="${PRELOADS[$test_type]}"

    # Run the test
    if wasmtime --allow-precompiled $preload_args "$test_file" >/dev/null 2>&1; then
        echo "✅ PASS"
        ((PASSED++))
    else
        echo "❌ FAIL"
        ((FAILED++))
        FAILED_TESTS+=("$test_name")
    fi
}

# Test char-utils functions
echo "--- CHAR-UTILS TESTS ---"
for test in *is-kebab-char-test.wasm *is-valid-identifier-start-test.wasm *is-operator-char-test.wasm *is-letter-test.wasm *is-digit*test.wasm *is-valid-word*.wasm *skip-whitespace-test.wasm *scan-number-test.wasm *simple-number-test.wasm; do
    [[ -f "$test" ]] && run_test "$test" "char-utils"
done

echo
echo "--- KEYWORDS TESTS ---"
for test in *is-keyword-test.wasm; do
    [[ -f "$test" ]] && run_test "$test" "keywords"
done

echo
echo "--- OPERATORS TESTS ---"
for test in *scan-colon-op-test.wasm *space-requirement-test.wasm *update-space-tracking-test.wasm; do
    [[ -f "$test" ]] && run_test "$test" "operators"
done

echo
echo "--- TOKEN-STORAGE TESTS ---"
for test in *token-storage-test.wasm *token-value-test.wasm; do
    [[ -f "$test" ]] && run_test "$test" "token-storage"
done

echo
echo "--- OTHER LEXER TESTS ---"
for test in *lexer*.wasm *global-value-test.wasm; do
    [[ -f "$test" ]] && [[ "$test" != *"lexer-char-utils.wasm" ]] && [[ "$test" != *"lexer-memory.wasm" ]] && [[ "$test" != *"lexer-tokens.wasm" ]] && [[ "$test" != *"lexer-keywords.wasm" ]] && [[ "$test" != *"lexer-operators.wasm" ]] && [[ "$test" != *"lexer-token-storage.wasm" ]] && [[ "$test" != *"lexer-identifiers.wasm" ]] && [[ "$test" != *"lexer-main.wasm" ]] && run_test "$test" "lexer"
done

echo
echo "=== TEST SUMMARY ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Total:  $((PASSED + FAILED))"

if [[ $FAILED -gt 0 ]]; then
    echo
    echo "❌ FAILED TESTS:"
    for failed_test in "${FAILED_TESTS[@]}"; do
        echo "  - $failed_test"
    done
    echo
    echo "Running failed tests with verbose output for debugging..."
    for failed_test in "${FAILED_TESTS[@]}"; do
        echo
        echo "=== DEBUGGING $failed_test ==="
        # Determine test type from name
        if [[ "$failed_test" == *"char-utils"* ]] || [[ "$failed_test" == *"kebab"* ]] || [[ "$failed_test" == *"identifier"* ]] || [[ "$failed_test" == *"operator-char"* ]] || [[ "$failed_test" == *"letter"* ]] || [[ "$failed_test" == *"digit"* ]] || [[ "$failed_test" == *"word"* ]] || [[ "$failed_test" == *"whitespace"* ]] || [[ "$failed_test" == *"number"* ]]; then
            wasmtime --allow-precompiled ${PRELOADS[char-utils]} "$failed_test.wasm"
        elif [[ "$failed_test" == *"keyword"* ]]; then
            wasmtime --allow-precompiled ${PRELOADS[keywords]} "$failed_test.wasm"
        elif [[ "$failed_test" == *"colon"* ]] || [[ "$failed_test" == *"space"* ]] || [[ "$failed_test" == *"tracking"* ]]; then
            wasmtime --allow-precompiled ${PRELOADS[operators]} "$failed_test.wasm"
        elif [[ "$failed_test" == *"token"* ]]; then
            wasmtime --allow-precompiled ${PRELOADS[token-storage]} "$failed_test.wasm"
        else
            wasmtime --allow-precompiled ${PRELOADS[lexer]} "$failed_test.wasm"
        fi
    done
fi
