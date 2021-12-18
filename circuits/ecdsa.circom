pragma circom 2.0.2;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/multiplexer.circom";

include "bigint.circom";
include "secp256k1.circom";
include "ecdsa_func.circom";
include "ecdsa_stride_func.circom";

// keys are encoded as (x, y) pairs with each coordinate being
// encoded with k registers of n bits each
template ECDSAPrivToPub(n, k) {
    signal input privkey[k];
    signal output pubkey[2][k];
    
    component n2b[k];
    for (var i = 0; i < k; i++) {
        n2b[i] = Num2Bits(n);
        n2b[i].in <== privkey[i];
    }

    var powers[258][2][100] = get_g_pow_stride1_table(86, 3, 258);

    signal partial[k * n][2][k];
    signal partial_intermed1[k * n][2][k];
    signal partial_intermed2[k * n][2][k];    
    component adders[n * k - 1];
    component ors[n * k];

    for (var idx = 0; idx < k; idx++) {
        partial[0][0][idx] <== n2b[0].out[0] * powers[0][0][idx];
        partial[0][1][idx] <== n2b[0].out[0] * powers[0][1][idx];
        partial_intermed1[0][0][idx] <== 0;
        partial_intermed1[0][1][idx] <== 0;
        partial_intermed2[0][0][idx] <== 0;
        partial_intermed2[0][1][idx] <== 0;
    }
    ors[0] = OR();
    ors[0].a <== 0;
    ors[0].b <== n2b[0].out[0];

    for (var i = 0; i < k; i++) {
        for (var j = 0; j < n; j++) {
            if (i > 0 || j > 0) {
               // ors[n * i + j] = 1 if at least one of the bits in privkey up to (i, j) was 1
               ors[n * i + j] = OR();
               if (i == 0 && j == 1) {
                   ors[n * i + j].a <== n2b[0].out[0];
                   ors[n * i + j].b <== n2b[0].out[1];
               } else {
                   ors[n * i + j].a <== ors[n * i + j - 1].out;
                   ors[n * i + j].b <== n2b[i].out[j];
               }

               adders[n * i + j - 1] = Secp256k1AddUnequal(n, k);
               for (var idx = 0; idx < k; idx++) {
                   adders[n * i + j - 1].a[0][idx] <== partial[n * i + j - 1][0][idx];
                   adders[n * i + j - 1].a[1][idx] <== partial[n * i + j - 1][1][idx];
                   adders[n * i + j - 1].b[0][idx] <== powers[n * i + j][0][idx];
                   adders[n * i + j - 1].b[1][idx] <== powers[n * i + j][1][idx];
               }
               
               // partial[n * i + j] = ors[n * i + j - 1] * (n2b[i].out[j] * adders[n * j + j - 1].out + (1 - n2b[i].out[j]) * partial[n * i + j - 1][0][idx]) + (1 - ors[n * i + j - 1]) * n2b[i].out[j] * powers[n * i + j]
               for (var idx = 0; idx < k; idx++) {
                   partial_intermed1[n * i + j][0][idx] <== n2b[i].out[j] * (adders[n * i + j - 1].out[0][idx] - partial[n * i + j - 1][0][idx]) + partial[n * i + j - 1][0][idx];
                   partial_intermed1[n * i + j][1][idx] <== n2b[i].out[j] * (adders[n * i + j - 1].out[1][idx] - partial[n * i + j - 1][1][idx]) + partial[n * i + j - 1][1][idx];
                   partial_intermed2[n * i + j][0][idx] <== n2b[i].out[j] * powers[n * i + j][0][idx];
                   partial_intermed2[n * i + j][1][idx] <== n2b[i].out[j] * powers[n * i + j][1][idx];
                   partial[n * i + j][0][idx] <== ors[n * i + j - 1].out * (partial_intermed1[n * i + j][0][idx] - partial_intermed2[n * i + j][0][idx]) + partial_intermed2[n * i + j][0][idx];
                   partial[n * i + j][1][idx] <== ors[n * i + j - 1].out * (partial_intermed1[n * i + j][1][idx] - partial_intermed2[n * i + j][1][idx]) + partial_intermed2[n * i + j][1][idx];
               }
            }
        }
    }
    for (var i = 0; i < k; i++) {
        pubkey[0][i] <== partial[n * k - 1][0][i];
        pubkey[1][i] <== partial[n * k - 1][1][i];
    }
}

// keys are encoded as (x, y) pairs with each coordinate being
// encoded with k registers of n bits each
template ECDSAPrivToPubStride(n, k, stride) {
    assert(stride == 2 || stride == 8 || stride == 10);
    signal input privkey[k];
    signal output pubkey[2][k];
    
    component n2b[k];
    for (var i = 0; i < k; i++) {
        n2b[i] = Num2Bits(n);
        n2b[i].in <== privkey[i];
    }

    var num_strides = 258 \ stride;
    if (258 % stride > 0) {
        num_strides = num_strides + 1;
    }
    // power[i][j] contains: [j * (1 << stride * i) * G] for 1 <= j < (1 << stride)
    var powers[258][1024][2][3];
    if (stride == 2) {
        powers = get_g_pow_stride2_table(86, 3, 258);
    }
    if (stride == 8) {
        powers = get_g_pow_stride8_table(86, 3, 258);
    }    
    if (stride == 10) {
        powers = get_g_pow_stride10_table(86, 3, 258);
    }    

    // contains a dummy point to stand in when we are adding 0
    var dummy[2][3];
    // dummy = (2 ** 258) * G
    dummy[0][0] = 35872591715049374896265832;
    dummy[0][1] = 6356226619579407084632810;
    dummy[0][2] = 2978520823699096284322372;
    dummy[1][0] = 26608736705833900595211029;
    dummy[1][1] = 58274658945430015619912323;
    dummy[1][2] = 4380191706425255173800171;

    // selector[i] contains a value in [0, ..., 2**i - 1] 
    component selectors[num_strides];
    for (var i = 0; i < num_strides; i++) {
        selectors[i] = Bits2Num(stride);
        for (var j = 0; j < stride; j++) {
            var bit_idx1 = (i * stride + j) \ n;
            var bit_idx2 = (i * stride + j) % n;
            if (bit_idx1 < k) {
                selectors[i].in[j] <== n2b[bit_idx1].out[bit_idx2];
            } else {
                selectors[i].in[j] <== 0;
            }
        }
    }

    signal partial[num_strides][2][k];
    signal partial_intermed1[num_strides][2][k];
    signal partial_intermed2[num_strides][2][k];

    component multiplexers[num_strides][2];
    component adders[num_strides - 1];
    component ors[num_strides];
    component iszeros[num_strides];     

    // select from k-register outputs using a 2 ** stride bit selector
    for (var i = 0; i < num_strides; i++) {
        for (var l = 0; l < 2; l++) {
            multiplexers[i][l] = Multiplexer(k, (1 << stride));
            multiplexers[i][l].sel <== selectors[i].out;
            for (var idx = 0; idx < k; idx++) {
                multiplexers[i][l].inp[0][idx] <== dummy[l][idx];
                for (var j = 1; j < (1 << stride); j++) {
                    multiplexers[i][l].inp[j][idx] <== powers[i][j][l][idx];
                }
            }
        }
    }
    
    for (var idx = 0; idx < k; idx++) {
        for (var l = 0; l < 2; l++) {
            partial[0][l][idx] <== multiplexers[0][l].out[idx];
            partial_intermed1[0][l][idx] <== 0;
            partial_intermed2[0][l][idx] <== 0;
        }
    }
    
    iszeros[0] = IsZero();
    iszeros[0].in <== selectors[0].out;
    ors[0] = OR();
    ors[0].a <== 0;
    ors[0].b <== 1 - iszeros[0].out;

    for (var i = 0; i < num_strides; i++) {
        if (i > 0) {
            // ors[i] = 1 if at least one of the selections in privkey up to stride i was non-zero
            iszeros[i] = IsZero();
            iszeros[i].in <== selectors[i].out;
            ors[i] = OR();
            ors[i].a <== ors[i - 1].out;
            ors[i].b <== 1 - iszeros[i].out;

            adders[i - 1] = Secp256k1AddUnequal(n, k);
            for (var idx = 0; idx < k; idx++) {
                for (var l = 0; l < 2; l++) {
                    adders[i - 1].a[l][idx] <== partial[i - 1][l][idx];
                    adders[i - 1].b[l][idx] <== multiplexers[i][l].out[idx];
                }
            }
               
            // partial[i] = ors[i - 1] * ((1 - iszeros[i]) * adders[i - 1].out + iszeros[i] * partial[i - 1][0][idx])
            //              + (1 - ors[i - 1]) * (1 - iszeros[i]) * multiplexers[i]
            for (var idx = 0; idx < k; idx++) {
                for (var l = 0; l < 2; l++) {
                    partial_intermed1[i][l][idx] <== iszeros[i].out * (partial[i - 1][l][idx] - adders[i - 1].out[l][idx]) + adders[i - 1].out[l][idx];
                    partial_intermed2[i][l][idx] <== multiplexers[i][l].out[idx] - iszeros[i].out * multiplexers[i][l].out[idx];
                    partial[i][l][idx] <== ors[i - 1].out * (partial_intermed1[i][l][idx] - partial_intermed2[i][l][idx]) + partial_intermed2[i][l][idx];
                }
            }
        }
    }
    for (var i = 0; i < k; i++) {
        for (var l = 0; l < 2; l++) {
            pubkey[l][i] <== partial[num_strides - 1][l][i];
        }
    }
    for (var i = 0; i < k; i++) {
        log(pubkey[0][i]);
    }    
    for (var i = 0; i < k; i++) {
        log(pubkey[1][i]);
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
