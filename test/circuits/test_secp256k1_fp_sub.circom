pragma circom 2.0.2;

include "../../circuits/bigint.circom";
include "../../circuits/secp256k1_func.circom";

template Secp256k1_Fp_Sub(n, k) {
    signal input a[k];
    signal input b[k];
    signal output out[k];

    component sub = BigSubModP(n, k);
    for (var i = 0; i < k; i ++) {
        sub.a[i] <== a[i];
        sub.b[i] <== b[i];
    }

    sub.p[0] <== 18446744069414583343;
    sub.p[1] <== 18446744073709551615;
    sub.p[2] <== 18446744073709551615;
    sub.p[3] <== 18446744073709551615;

    for (var i = 0; i < k; i ++) {
        out[i] <== sub.out[i];
    }
}

component main {public [a, b]} = Secp256k1_Fp_Sub(64, 4);
