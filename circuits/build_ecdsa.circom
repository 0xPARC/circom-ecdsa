pragma circom 2.0.2;

include "ecdsa.circom";

component main {public [privkey]} = ECDSAPrivToPubStride(86, 3, 10);
