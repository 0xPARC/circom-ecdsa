pragma circom 2.0.2;

include "../../circuits/ecdsa.circom";

component main {public [a, b]} = Secp256k1AddUnequal(86, 3);
