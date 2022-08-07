# circom-bigint

Implementation of bigint arithmetic in circom.

## Project overview

This repository provides proof-of-concept implementations of bigint arithmetic in circom. **These implementations are for demonstration purposes only**.  These circuits are not audited, and this is not intended to be used as a library for production-grade applications.

Circuits can be found in `circuits`. `scripts` contains various utility scripts (most importantly, scripts for building an example zkSNARK using the bigint circuit primitive). `test` contains some unit tests for the circuits, mostly for witness generation.

## Install dependencies

- Run `yarn` at the top level to install npm dependencies (`snarkjs` and `circomlib`).
- You'll also need `circom` version `>= 2.0.2` on your system. Installation instructions [here](https://docs.circom.io/getting-started/installation/).
- To build `bigint` circuits, you'll need to download a Powers of Tau file with `2^8` constraints and copy it into the `circuits` subdirectory of the project, with the name `pot08_final.ptau`. We do not provide such a file in this repo due to its large size. You can download and copy Powers of Tau files from the Hermez trusted setup from [this repository](https://github.com/iden3/snarkjs#7-prepare-phase-2).

## Building keys and witness generation files

Run `yarn build:bigint` at the top level to compile a bigint related circuit.

This will create a subdirectory inside a `build` directory at the top level (which will be created if it doesn't already exist). Inside this directory, the build process will create `r1cs` and `wasm` files for witness generation, as well as a `zkey` file (proving and verifying keys).

This process will also generate and verify a proof for a dummy input in the respective `scripts/bigint` subdirectory, as a smoke test.

## Benchmarks

Todo.

## Testing

Run `yarn test` at the top level to run tests. Note that these tests only test correctness of witness generation.  They do not check that circuits are properly constrained, i.e. that only valid witnesses satisfy the constraints.

Circuit unit tests are written in typescript, in the `test` directory using `chai`, `mocha`, and `circom_tester`. To run a subset of the tests, use `yarn test --grep [test_str]` to run all tests whose description matches `[test_str]`.

## Acknowledgments

This project was built during [0xPARC](http://0xparc.org/)'s [Applied ZK Learning Group #1](https://0xparc.org/blog/zk-learning-group).

We use an optimization for big integer multiplication from [xJsnark](https://github.com/akosba/xjsnark).
