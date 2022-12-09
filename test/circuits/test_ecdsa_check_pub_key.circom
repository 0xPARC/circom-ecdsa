pragma circom 2.0.2;

include "../../circuits/ecdsa.circom";

component main {public [pubkey]} = ECDSACheckPubKey(64, 4);
