# circom-ecdsa

Implementation of ECDSA operations in circom.

## Project overview

This repository provides proof-of-concept implementations of ECDSA operations in circom. **These implementations are for demonstration purposes only**.  These circuits are not audited, and this is not intended to be used as a library for production-grade applications.

Circuits can be found in `circuits`. `scripts` contains various utility scripts (most importantly, scripts for building a few example zkSNARKs using the ECDSA circuit primitives). `test` contains some unit tests for the circuits, mostly for witness generation.

## Install dependencies

- Run `yarn` at the top level to install npm dependencies (`snarkjs` and `circomlib`).
- You'll also need `circom` version `>= 2.0.2` on your system. Installation instructions [here](https://docs.circom.io/getting-started/installation/).
- If you want to build the `pubkeygen`, `eth_addr`, and `groupsig` circuits, you'll need to download a Powers of Tau file with `2^20` constraints and copy it into the `circuits` subdirectory of the project, with the name `pot20_final.ptau`. We do not provide such a file in this repo due to its large size. You can download and copy Powers of Tau files from the Hermez trusted setup from [this repository](https://github.com/iden3/snarkjs#7-prepare-phase-2).
- If you want to build the `verify` circuits, you'll also need a Powers of Tau file that can support at least `2^24` constraints (place it in the same directory as above with the same naming convention).

## Building keys and witness generation files

We provide examples of four circuits using the ECDSA primitives implemented here:
- `pubkeygen`: Prove knowledge of a private key corresponding to a ECDSA public key.
- `eth_addr`: Prove knowledge of a private key corresponding to an Ethereum address.
- `groupsig`: Prove knowledge of a private key corresponding to one of three Ethereum addresses, and attest to a specific message.
- `verify`: Prove that a ECDSA verification ran properly on a provided signature and message. Note that this circuit does not verify that the public key itself is valid. This must be done separately by the user.

Run `yarn build:pubkeygen`, `yarn build:eth_addr`, `yarn build:groupsig`, `yarn build:verify` at the top level to compile each respective circuit and keys.

Each of these will create a subdirectory inside a `build` directory at the top level (which will be created if it doesn't already exist). Inside this directory, the build process will create `r1cs` and `wasm` files for witness generation, as well as a `zkey` file (proving and verifying keys). Note that this process will take several minutes (see full benchmarks below).  Building `verify` requires 56G of RAM.

This process will also generate and verify a proof for a dummy input in the respective `scripts/[circuit_name]` subdirectory, as a smoke test.

## Benchmarks

All benchmarks were run on a 20-core 3.3GHz, 64G RAM machine.  Building `verify` requires 56G of RAM.

||pubkeygen|eth_addr|groupsig|verify|
|---|---|---|---|---|
|Constraints                          |416883 |568823 |571721 |9480361 |
|Circuit compilation  	      	      |90s    |115s    |116s   |324s    |
|Witness generation  	      	      |8s     |7s      |8s     |150s    |
|Trusted setup phase 2 key generation |150s   |167s    |164s   |5569s   |
|Trusted setup phase 2 contribution   |28s    |47s     |47s    |767s    |
|Proving key size                     |254M   |347M    |349M   |5.8G    |
|Proving key verification             |157s   |185s    |184s   |6211s   |
|Proving time         		      |12s    |17s     |16s    |239s    |
|Proof verification time              |<1s    |<1s     |<1s    |<1s     |

## Testing

Run `yarn test` at the top level to run tests. Note that these tests only test correctness of witness generation.  They do not check that circuits are properly constrained, i.e. that only valid witnesses satisfy the constraints.  This is a much harder problem that we're currently working on!

Circuit unit tests are written in typescript, in the `test` directory using `chai`, `mocha`, and `circom_tester`.  Running all tests takes about 1 hour on our 3.3GHz, 64G RAM test machine. To run a subset of the tests, use `yarn test --grep [test_str]` to run all tests whose description matches `[test_str]`.

## Groupsig CLI Demo

You can run a CLI demo of a zkSNARK-enabled group signature generator once you've built the `groupsig` keys. Simply run `yarn groupsig-demo` at the top level and follow the instructions in your terminal.

## Acknowledgments

This project was built during [0xPARC](http://0xparc.org/)'s [Applied ZK Learning Group #1](https://0xparc.org/blog/zk-learning-group).

We use a [circom implementation of keccak](https://github.com/vocdoni/keccak256-circom) from Vocdoni. We also use some circom utilities for converting an ECDSA public key to an Ethereum address implemented by [lsankar4033](https://github.com/lsankar4033), [jefflau](https://github.com/jefflau), and [veronicaz41](https://github.com/veronicaz41) for another ZK Learning Group project in the same cohort.  We use an optimization for big integer multiplication from [xJsnark](https://github.com/akosba/xjsnark).
