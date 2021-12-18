pragma circom 2.0.2;

include "../node_modules/circomlib/circuits/bitify.circom";

include "bigint.circom";
include "bigint_func.circom";
include "secp256k1_func.circom";

// requires a[0] != b[0]
//
// Implements:
// lamb = (b[1] - a[1]) / (b[0] - a[0]) % p
// out[0] = lamb ** 2 - a[0] - b[0] % p
// out[1] = lamb * (a[0] - out[0]) - a[1] % p
template Secp256k1AddUnequal(n, k) {
    signal input a[2][k];
    signal input b[2][k];

    signal output out[2][k];

    var p[100] = get_secp256k1_prime(n, k);

    // b[1] - a[1]
    component sub1 = BigSubModP(n, k);
    for (var i = 0; i < k; i++) {
        sub1.a[i] <== b[1][i];
        sub1.b[i] <== a[1][i];
        sub1.p[i] <== p[i];
    }

    // b[0] - a[0]
    component sub0 = BigSubModP(n, k);
    for (var i = 0; i < k; i++) {
        sub0.a[i] <== b[0][i];
        sub0.b[i] <== a[0][i];
        sub0.p[i] <== p[i];
    }

    signal lambda[k];
    var sub0inv[100] = mod_inv(n, k, sub0.out, p);
    var sub1_sub0inv[100] = prod(n, k, sub1.out, sub0inv);
    var lamb_arr[2][100] = long_div(n, k, sub1_sub0inv, p);
    for (var i = 0; i < k; i++) {
        lambda[i] <-- lamb_arr[1][i];
    }
    component range_checks[k];
    for (var i = 0; i < k; i++) {
        range_checks[i] = Num2Bits(n);
        range_checks[i].in <== lambda[i];
    }
    component lt = BigLessThan(n, k);
    for (var i = 0; i < k; i++) {
        lt.a[i] <== lambda[i];
        lt.b[i] <== p[i];
    }
    lt.out === 1;

    component lambda_check = BigMultModP(n, k);
    for (var i = 0; i < k; i++) {
        lambda_check.a[i] <== sub0.out[i];
        lambda_check.b[i] <== lambda[i];
        lambda_check.p[i] <== p[i];
    }
    for (var i = 0; i < k; i++) {
        lambda_check.out[i] === sub1.out[i];
    }

    component lambdasq = BigMultModP(n, k);
    for (var i = 0; i < k; i++) {
        lambdasq.a[i] <== lambda[i];
        lambdasq.b[i] <== lambda[i];
        lambdasq.p[i] <== p[i];
    }
    component out0_pre = BigSubModP(n, k);
    for (var i = 0; i < k; i++) {
        out0_pre.a[i] <== lambdasq.out[i];
        out0_pre.b[i] <== a[0][i];
        out0_pre.p[i] <== p[i];
    }
    component out0 = BigSubModP(n, k);
    for (var i = 0; i < k; i++) {
        out0.a[i] <== out0_pre.out[i];
        out0.b[i] <== b[0][i];
        out0.p[i] <== p[i];
    }
    for (var i = 0; i < k; i++) {
        out[0][i] <== out0.out[i];
    }

    component out1_0 = BigSubModP(n, k);
    for (var i = 0; i < k; i++) {
        out1_0.a[i] <== a[0][i];
        out1_0.b[i] <== out[0][i];
        out1_0.p[i] <== p[i];
    }
    component out1_1 = BigMultModP(n, k);
    for (var i = 0; i < k; i++) {
        out1_1.a[i] <== lambda[i];
        out1_1.b[i] <== out1_0.out[i];
        out1_1.p[i] <== p[i];  
    }
    component out1 = BigSubModP(n, k);
    for (var i = 0; i < k; i++) {
        out1.a[i] <== out1_1.out[i];
        out1.b[i] <== a[1][i];
        out1.p[i] <== p[i];
    }
    for (var i = 0; i < k; i++) {
        out[1][i] <== out1.out[i];
    }
}

template Secp256k1ScalarMult(n, k) {
    signal input scalar[k];
    signal input point[2][k];

    signal output out[2][k];
}

