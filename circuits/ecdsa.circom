pragma circom 2.0.1;

include "bigint.circom";

// keys are encoded as (x, y) pairs with each coordinate being
// encoded with k registers of n bits each
template ECDSAPrivToPub(n, k) {
    signal input privkey[k];
    
    signal output pubkey[2][k];
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

component main {public [a, b]} = ECDSAPrivToPub(86, 3);