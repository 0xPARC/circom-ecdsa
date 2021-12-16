pragma circom 2.0.1;

include "bigint.circom";

template Secp256k1Add(n, k) {
    signal input a[2][k];
    signal input b[2][k];

    signal output out[2][k];
}

template Secp256k1ScalarMult(n, k) {
    signal input scalar[k];
    signal input point[2][k];

    signal output out[2][k];
}

component main {public [a, b]} = BigMult(4, 3);