#!/bin/bash

PHASE1=circuits/pot22_final.ptau
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

echo "\n****COMPILING CIRCUIT****"
start=`date +%s`
circom circuits/build_ecdsa.circom --r1cs --wasm --sym --c --wat --output "$BUILD_DIR"
end=`date +%s`
echo "DONE ($((end-start))s)"

echo "\n****GENERATING WITNESS FOR SAMPLE INPUT****"
start=`date +%s`
node "$BUILD_DIR"/build_ecdsa_js/generate_witness.js "$BUILD_DIR"/build_ecdsa_js/build_ecdsa.wasm test/input.json "$BUILD_DIR"/witness.wtns
end=`date +%s`
echo "DONE ($((end-start))s)"

echo "\n****GENERATING ZKEY 0****"
start=`date +%s`
npx snarkjs groth16 setup "$BUILD_DIR"/build_ecdsa.r1cs "$PHASE1" "$BUILD_DIR"/build_ecdsa_0.zkey
end=`date +%s`
echo "DONE ($((end-start))s)"

echo "\n****GENERATING FINAL ZKEY****"
start=`date +%s`
npx snarkjs zkey beacon "$BUILD_DIR"/build_ecdsa_0.zkey "$BUILD_DIR"/build_ecdsa.zkey 0102030405060708090a0b0c0d0e0f101112231415161718221a1b1c1d1e1f 10 -n="Final Beacon phase2"
end=`date +%s`
echo "DONE ($((end-start))s)"

echo "\n****VERIFYING FINAL ZKEY****"
start=`date +%s`
npx snarkjs zkey verify "$BUILD_DIR"/build_ecdsa.r1cs "$PHASE1" "$BUILD_DIR"/build_ecdsa.zkey
end=`date +%s`
echo "DONE ($((end-start))s)"

echo "\n****EXPORTING VKEY****"
start=`date +%s`
npx snarkjs zkey export verificationkey "$BUILD_DIR"/build_ecdsa.zkey "$BUILD_DIR"/vkey.json
end=`date +%s`
echo "DONE ($((end-start))s)"

echo "\n****GENERATING PROOF FOR SAMPLE INPUT****"
start=`date +%s`
npx snarkjs groth16 prove "$BUILD_DIR"/build_ecdsa.zkey "$BUILD_DIR"/witness.wtns "$BUILD_DIR"/proof.json "$BUILD_DIR"/public.json
end=`date +%s`
echo "DONE ($((end-start))s)"

echo "\n****VERIFYING PROOF FOR SAMPLE INPUT****"
start=`date +%s`
npx snarkjs groth16 verify "$BUILD_DIR"/vkey.json "$BUILD_DIR"/public.json "$BUILD_DIR"/proof.json
end=`date +%s`
echo "DONE ($((end-start))s)"
