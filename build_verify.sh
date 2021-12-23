#!/bin/bash

PHASE1=circuits/pot24_final.ptau
BUILD_DIR=build

if [ -f "$PHASE1" ]; then
    echo "Found Phase 1 ptau file"
else
    echo "No Phase 1 ptau file found. Exiting..."
    exit 1
fi

if [ ! -d "$BUILD_DIR" ]; then
    echo "No build directory found. Creating build directory..."
    mkdir "$BUILD_DIR"
fi

echo "** Compiling circuit"
start=`date +%s`
set -x
circom test/circuits/test_ecdsa_verify.circom --r1cs --wasm --sym --c --wat --output "$BUILD_DIR"
{ set +x; } 2>/dev/null
end=`date +%s`
echo "DONE ($((end-start))s)"

echo "** Generating witness for sample input"
start=`date +%s`
set -x
node "$BUILD_DIR"/test_ecdsa_verify_js/generate_witness.js "$BUILD_DIR"/test_ecdsa_verify_js/test_ecdsa_verify.wasm test/input_verify.json "$BUILD_DIR"/witness.wtns
{ set +x; } 2>/dev/null
end=`date +%s`
echo "DONE ($((end-start))s)"

echo "** Generating initial .zkey"
start=`date +%s`
set -x
NODE_OPTIONS=--max_old_space_size=56000 npx snarkjs groth16 setup "$BUILD_DIR"/test_ecdsa_verify.r1cs "$PHASE1" "$BUILD_DIR"/test_ecdsa_verify_0.zkey
{ set +x; } 2>/dev/null
end=`date +%s`
echo "DONE ($((end-start))s)"

echo "** Adding beacon contribution to get final .zkey"
start=`date +%s`
set -x
NODE_OPTIONS=--max_old_space_size=56000 npx snarkjs zkey beacon "$BUILD_DIR"/test_ecdsa_verify_0.zkey "$BUILD_DIR"/test_ecdsa_verify.zkey 0102030405060708090a0b0c0d0e0f101112231415161718221a1b1c1d1e1f 10 -n="Final Beacon phase2"
{ set +x; } 2>/dev/null
end=`date +%s`
echo "DONE ($((end-start))s)"

echo "** Verifying final .zkey"
start=`date +%s`
set -x
NODE_OPTIONS=--max_old_space_size=58000 npx snarkjs zkey verify "$BUILD_DIR"/test_ecdsa_verify.r1cs "$PHASE1" "$BUILD_DIR"/test_ecdsa_verify.zkey
{ set +x; } 2>/dev/null
end=`date +%s`
echo "DONE ($((end-start))s)"

echo "** Exporting vkey"
start=`date +%s`
set -x
NODE_OPTIONS=--max_old_space_size=56000 npx snarkjs zkey export verificationkey "$BUILD_DIR"/test_ecdsa_verify.zkey "$BUILD_DIR"/vkey.json
end=`date +%s`
{ set +x; } 2>/dev/null
echo "DONE ($((end-start))s)"

echo "** Generating proof for sample input"
start=`date +%s`
set -x
NODE_OPTIONS=--max_old_space_size=56000 npx snarkjs groth16 prove "$BUILD_DIR"/test_ecdsa_verify.zkey "$BUILD_DIR"/witness.wtns "$BUILD_DIR"/proof.json "$BUILD_DIR"/public.json
{ set +x; } 2>/dev/null
end=`date +%s`
echo "DONE ($((end-start))s)"

echo "** Verifying proof for sample input"
start=`date +%s`
set -x
NODE_OPTIONS=--max_old_space_size=56000 npx snarkjs groth16 verify "$BUILD_DIR"/vkey.json "$BUILD_DIR"/public.json "$BUILD_DIR"/proof.json
end=`date +%s`
{ set +x; } 2>/dev/null
echo "DONE ($((end-start))s)"
