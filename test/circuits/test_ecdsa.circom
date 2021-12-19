pragma circom 2.0.2;

include "../../circuits/ecdsa.circom";

component main {public [privkey]} = ECDSAPrivToPubStride(86, 3, 10);
