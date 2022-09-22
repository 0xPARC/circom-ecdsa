pragma circom 2.0.2;

include "../../circuits/bigint.circom";

template Secp256k1_Fp_Mul(n, k) {
    signal input a[k];
    signal input b[k];
    signal output out[k];

    component mul_mod_p = BigMultModP(n, k);
    for (var i = 0; i < k; i ++) {
        mul_mod_p.a[i] <== a[i];
        mul_mod_p.b[i] <== b[i];
    }
    mul_mod_p.p[0] <== 18446744069414583343;
    mul_mod_p.p[1] <== 18446744073709551615;
    mul_mod_p.p[2] <== 18446744073709551615;
    mul_mod_p.p[3] <== 18446744073709551615;

    for (var i = 0; i < k; i ++) {
        out[i] <== mul_mod_p.out[i];
    }
}

component main {public [a, b]} = Secp256k1_Fp_Mul(64, 4);
