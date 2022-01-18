# circom-ecdsa

Implementation of ECDSA operations in circom.

## Project overview

This repository provides proof-of-concept implementations of ECDSA operations in circom. **These implementations are for demonstration purposes only**; these circuits are not audited, and this is not intended to be used as a library for production-grade applications.

Circuits can be found in `circuits`. `scripts` contains various utility scripts (most importantly, scripts for building a few example zkSNARKs using the ECDSA circuit primitives). `test` contains some sanity checks for the circuits, mostly for witness generation.

## Install dependencies

- Run `yarn` at the top level to install npm dependencies (`snarkjs` and `circomlib`).
- You'll also need circom itself on your system. Installation instructions [here](https://github.com/iden3/circom).
- If you want to build the `pubkeygen` and `groupsig` circuits, you'll need to download a Powers of Tau file with `2^22` constraints and copy it into the `circuits` subdirectory of the project, with the name `pot22_final.ptau`. This file is not checked in to Github due to its large size. However, you can download and copy the file manually from [this repository](https://github.com/iden3/snarkjs#7-prepare-phase-2).
- If you want to build the `verify` circuits, you'll also need a Powers of Tau file that can support `2^24` constraints (place it in the same directory as above with the same naming convention).

## Building keys and witness generation files

We provide examples of three circuits using the ECDSA primitives implemented here:
- `pubkeygen`: Prove knowledge of a private key corresponding to an Ethereum address.
- `groupsig`: Prove knowledge of a private key corresponding to one of three Ethereum addresses, and attest to a specific message.
- `verify`: Prove that a ECDSA verification ran properly on a provided signature and message.

Run `yarn build:pubkeygen`, `yarn build:groupsig`, `yarn build:verify` at the top level to compile each respective circuit and keys.

Each of these will create a subdirectory inside a `build` directory at the top level (which will be created if it doesn't already exist). Inside this directory, the build process will create `r1cs` and `wasm` files for witness generation, as well as a `zkey` file (proving and verifying keys). Note that this process will take several minutes.

This process will also generate and verify a proof for a dummy inputs in the respective `scripts/[circuit_name]` subdirectory, as a smoke test.

## Benchmarks

(TODO for yi)

## Testing

Run `yarn test` at the top level to run tests. Note that these tests only test for correctness of witness generation--they do not check that circuits are properly constrained (this is a much harder problem that we're currently working on!)

Circuit unit tests are written in typescript, in the `test` directory using `chai`, `mocha`, and `circom_tester`. 

## Groupsig CLI Demo

You can run a CLI demo of a zkSNARK-enabled group signature generator once you've built the `groupsig` keys. Simply run `yarn groupsig-demo` at the top level and follow the instructions in your terminal.

## Acknowledgements

This project was built during [0xPARC](http://0xparc.org/)'s [Applied ZK Learning Group #1](https://0xparc.org/blog/zk-learning-group).

We use a [circom implementation of keccak](https://github.com/vocdoni/keccak256-circom) from Vocdoni. We also use some circom utilities for converting an ECDSA public key to an Ethereum address implemented by [lsankar4033](https://github.com/lsankar4033), [jefflau](https://github.com/jefflau), and [veronicaz41](https://github.com/veronicaz41) for another ZK Learning Group project in the same cohort.
