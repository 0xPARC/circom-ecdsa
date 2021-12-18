# circom-secp256k1

Implementation of ECC operations in circom.

## Install dependencies

- Run `yarn` at the top level to install npm dependencies (`snarkjs` and `circomlib`).
- You'll also need circom itself on your system. Installation instructions [here](https://github.com/iden3/circom).
- Right now, you'll need Python 3.x as well to run the test scripts. These will be ported to Javascript/Typescript shortly however.
- You'll need to download a Powers of Tau file (with `2^22` constraints) and copy it into the `circuits` subdirectory of the project, with the name `pot22_final.ptau`. This file is not checked in to Github due to its large size. However, you can download and copy the file manually from [this repository](https://github.com/iden3/snarkjs#7-prepare-phase-2).

## Testing

Right now we have some python scripts to test circuit compilation and proofs. This will be ported to JS shortly. You can run tests by running:
```
python test_ecdsa.py --stride 8 --zk_sys groth16
```

Note that the script takes a VERY long time to run.
