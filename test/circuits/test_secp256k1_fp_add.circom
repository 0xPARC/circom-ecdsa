pragma circom 2.0.2;

include "../../circuits/bigint.circom";
include "../../circuits/secp256k1_func.circom";

template Secp256k1_Fp_Add(n, k) {
    signal input a[k];
    signal input b[k];
    signal output out[k];

    component adder = BigAdd(n, k);
    for (var i = 0; i < k; i ++) {
        adder.a[i] <== a[i];
        adder.b[i] <== b[i];
    }

    component mod = BigMod(n, k);

    for (var i = 0; i < k + 1; i ++) {
        mod.a[i] <== adder.out[i];
    }

    for (var i = k + 1; i < k * 2; i ++) {
        mod.a[i] <== 0;
    }

    mod.b[0] <== 18446744069414583343;
    mod.b[1] <== 18446744073709551615;
    mod.b[2] <== 18446744073709551615;
    mod.b[3] <== 18446744073709551615;

    for (var i = 0; i < k; i ++) {
        out[i] <== mod.mod[i];
    }
}

component main {public [a, b]} = Secp256k1_Fp_Add(64, 4);
