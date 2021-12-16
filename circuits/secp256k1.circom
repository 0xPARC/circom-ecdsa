pragma circom 2.0.1;

include "bigint.circom";

function get_secp256k1_prime(n, k) {
     var ret[100];
     if (n == 86 && k == 3) {
         ret[0] = 77371252455336262886226991;
         ret[1] = 77371252455336267181195263;
         ret[2] = 19342813113834066795298815;
     }
     return ret;
}

template Secp256k1Add(n, k) {
    signal input a[2][k];
    signal input b[2][k];

    signal output out[2][k];

    var p[100] = get_secp256k1_prime(n, k);

    component sub1 = BigSubModP(n, k);
    for (var i = 0; i < k; i++) {
        sub1.a[i] <== a[1][i];
        sub1.b[i] <== b[1][i];
        sub1.p[i] <== p[i];
    }
    component sub0 = BigSubModP(n, k);
    for (var i = 0; i < k; i++) {
        sub0.a[i] <== a[0][i];
        sub0.b[i] <== b[0][i];
        sub0.p[i] <== p[i];
    }
    component sub0inv = BigModInv(n, k);
    for (var i = 0; i < k; i++) {
        sub0inv.in[i] <== sub0.out[i];
        sub0inv.p[i] <== p[i];
    }
    component lambda_pre = BigMult(n, k);
    for (var i = 0; i < k; i++) {
        lambda_pre.a[i] <== sub1.out[i];
        lambda_pre.b[i] <== sub0inv.out[i];
    }
    component lambda = BigMod(n, k);   
    for (var i = 0; i < 2 * k; i++) {
        lambda.a[i] <== lambda_pre.out[i];
    }
    for (var i = 0; i < k; i++) {
        lambda.b[i] <== p[i];
    }

    component lambdasq_pre = BigMult(n, k);
    for (var i = 0; i < k; i++) {
        lambdasq_pre.a[i] <== lambda.mod[i];
        lambdasq_pre.b[i] <== lambda.mod[i];
    }
    component lambdasq = BigMod(n, k);   
    for (var i = 0; i < 2 * k; i++) {
        lambdasq.a[i] <== lambdasq_pre.out[i];
    }
    for (var i = 0; i < k; i++) {
        lambdasq.b[i] <== p[i];
    }

    component out0_pre = BigSubModP(n, k);
    for (var i = 0; i < k; i++) {
        out0_pre.a[i] <== lambdasq.mod[i];
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
    component out1_1 = BigMult(n, k);
    for (var i = 0; i < k; i++) {
        out1_1.a[i] <== lambda.mod[i];
        out1_1.b[i] <== out1_0.out[i];
    }
    component out1_2 = BigMod(n, k);
    for (var i = 0; i < 2 * k; i++) {
        out1_2.a[i] <== out1_1.out[i];
    }
    for (var i = 0; i < k; i++) {
        out1_2.b[i] <== p[i];
    }
    component out1 = BigSubModP(n, k);
    for (var i = 0; i < k; i++) {
        out1.a[i] <== out1_2.mod[i];
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
