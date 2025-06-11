const fs = require('fs');
const util = require('util');
const exec = util.promisify(require('child_process').exec);
const path = require('path');

async function compileWat(watFile, wasmFile) {
    try {
        // Use wasmtime wat2wasm for compilation
        await exec(`wasmtime compile ${watFile} -o ${wasmFile}`);
        console.log(`Successfully compiled ${watFile} to ${wasmFile}`);
    } catch (error) {
        console.error(`Error compiling ${watFile}:`, error.stderr);
        throw error;
    }
}

async function runTests() {
    const srcDir = path.join(__dirname, '..', 'src');
    const testDir = path.join(__dirname, '..', 'tests', 'unit');
    const buildDir = path.join(__dirname, '..', 'build');

    // Create build directory if it doesn't exist
    if (!fs.existsSync(buildDir)) {
        fs.mkdirSync(buildDir, { recursive: true });
    }

    try {
        // Compile memory module
        await compileWat(
            path.join(srcDir, 'memory.wat'),
            path.join(buildDir, 'memory.wasm')
        );

        // Compile keywords module
        await compileWat(
            path.join(srcDir, 'keywords.wat'),
            path.join(buildDir, 'keywords.wasm')
        );

        // Compile lexer module
        await compileWat(
            path.join(srcDir, 'lexer.wat'),
            path.join(buildDir, 'lexer.wasm')
        );

        // Compile and run tests
        await compileWat(
            path.join(testDir, 'lexer_test.wat'),
            path.join(buildDir, 'lexer_test.wasm')
        );

        // Run compiled modules using wasmtime
        console.log('Running lexer tests...');

        // Create a shared memory file
        const memoryFile = path.join(buildDir, 'shared_memory.wasm');
        await exec(`wasmtime compile ${path.join(srcDir, 'memory.wat')} -o ${memoryFile}`);

        // Run the tests using wasmtime with proper module instantiation order
        const { stdout, stderr } = await exec(
            `wasmtime run \
            --mapdir=/::${path.resolve(__dirname, '..')} \
            --memory-file=${memoryFile} \
            --wasm-features=multi-memory,multi-value \
            ${path.join(buildDir, 'memory.wasm')} \
            ${path.join(buildDir, 'keywords.wasm')} \
            ${path.join(buildDir, 'lexer.wasm')} \
            ${path.join(buildDir, 'lexer_test.wasm')}`
        );

        // Check test output
        if (stdout) console.log('Test output:', stdout);
        if (stderr) {
            console.error('Test errors:', stderr);
            process.exit(1);
        }

        // Verify no errors were logged
        if (stdout.includes('error') || stdout.includes('Error')) {
            console.error('Tests failed with errors');
            process.exit(1);
        }

        console.log('All tests passed successfully!');

    } catch (error) {
        console.error('Test execution failed:', error);
        process.exit(1);
    }
}

runTests().catch(console.error);
