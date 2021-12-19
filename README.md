# circom-secp256k1

Implementation of ECC operations in circom.

## Install dependencies

- Run `yarn` at the top level to install npm dependencies (`snarkjs` and `circomlib`).
- You'll also need circom itself on your system. Installation instructions [here](https://github.com/iden3/circom).
- You'll need to download a Powers of Tau file (with `2^22` constraints) and copy it into the `circuits` subdirectory of the project, with the name `pot22_final.ptau`. This file is not checked in to Github due to its large size. However, you can download and copy the file manually from [this repository](https://github.com/iden3/snarkjs#7-prepare-phase-2).

## Building keys and witness generation files

You'll need to generate `r1cs` and `wasm` files for witness generation, as well as a `zkey` file (proving and verifying keys). Running `yarn build` in the root directory will create a gitignored `build` directory and then generate all of these files. Note that this process will take several minutes.

This process will also generate and verify a proof for a dummy input in `test/input.json`.

## (WIP) Testing

Circuit unit tests are written in javascript, in the `test` directory.
