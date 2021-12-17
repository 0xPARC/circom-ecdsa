pragma circom 2.0.1;

include "../node_modules/circomlib/circuits/switcher.circom";

include "bigint.circom";
include "secp256k1.circom";
include "secp256k1_func.circom";

// keys are encoded as (x, y) pairs with each coordinate being
// encoded with k registers of n bits each

// only works if the lowest order bit of privkey is 1
template ECDSAPrivToPub(n, k) {
    signal input privkey[k];
    signal output pubkey[2][k];
    
    component n2b[k];
    for (var i = 0; i < k; i++) {
        n2b[i] = Num2Bits(n);
        n2b[i].in <== privkey[i];
    }

    var powers[258][2][100] = get_g_pow(86, 3, 258);

    signal partial[k * n][2][k];
    component adders[n * k - 1];
    for (var idx = 0; idx < k; idx++) {
        // TODO: Correct for case where n2b[0].out[0] == 0
        partial[0][0][idx] <== powers[0][0][idx];
        partial[0][1][idx] <== powers[0][1][idx];
    }

    for (var i = 0; i < k; i++) {
        for (var j = 0; j < n; j++) {
            if (i > 0 || j > 0) {
               adders[n * i + j - 1] = Secp256k1AddUnequal(n, k);
               for (var idx = 0; idx < k; idx++) {
                   adders[n * i + j - 1].a[0][idx] <== partial[n * i + j - 1][0][idx];
                   adders[n * i + j - 1].a[1][idx] <== partial[n * i + j - 1][1][idx];
                   adders[n * i + j - 1].b[0][idx] <== powers[n * i + j][0][idx];
                   adders[n * i + j - 1].b[1][idx] <== powers[n * i + j][1][idx];
               }

               for (var idx = 0; idx < k; idx++) {
                   partial[n * i + j][0][idx] <== n2b[i].out[j] * (adders[n * i + j - 1].out[0][idx] - partial[n * i + j - 1][0][idx]) + partial[n * i + j - 1][0][idx];
                   partial[n * i + j][1][idx] <== n2b[i].out[j] * (adders[n * i + j - 1].out[1][idx] - partial[n * i + j - 1][1][idx]) + partial[n * i + j - 1][1][idx];
               }
            }
        }
    }
    for (var i = 0; i < k; i++) {
        pubkey[0][i] <== partial[n * k - 1][0][i];
        pubkey[1][i] <== partial[n * k - 1][1][i];
    }
}

// r, s, msghash, nonce, and privkey have coordinates
// encoded with k registers of n bits each 
// signature is (r, s)
template ECDSASign(n, k) {
    signal input privkey[k];
    signal input msghash[k];
    signal input nonce[k];
    
    signal output r[k];
    signal output s[k];
}

// r, s, msghash, nonce, and privkey have coordinates
// encoded with k registers of n bits each 
// v is a bit
// signature is (r, s, v)
template ECDSAExtendedSign(n, k) {
    signal input privkey[k];
    signal input msghash[k];
    signal input nonce[k];
    
    signal output r[k];
    signal output s[k];
    signal output v;
}

// r, s, msghash, and pubkey have coordinates
// encoded with k registers of n bits each
// signature is (r, s)
template ECDSAVerify(n, k) {
    signal input r[k];
    signal input s[k];     
    signal input msghash[k];
    signal input pubkey[2][k];

    signal output result;
}

// r, s, and msghash have coordinates
// encoded with k registers of n bits each
// v is a single bit
// extended signature is (r, s, v)
template ECDSAExtendedVerify(n, k) {
    signal input r[k];
    signal input s[k];
    signal input v;
    signal input msghash[k];

    signal output result;
}
