pragma circom 2.0.2;

include "../../circuits/bigint.circom";

template Secp256k1_Fp_Mod() {
    var n = 64;
    var k = 4;

    signal input a[k];
    signal output out[k];

    component m = BigMod(n, k);

    for (var i = 0; i < k; i ++) {
        m.a[i] <== a[i];
        m.a[k + i] <== 0;
    }

    m.b[0] <== 18446744069414583343;
    m.b[1] <== 18446744073709551615;
    m.b[2] <== 18446744073709551615;
    m.b[3] <== 18446744073709551615;

    for (var i = 0; i < k; i ++) {
        out[i] <== m.mod[i];
    }
}

component main {public [a]} = Secp256k1_Fp_Mod();
