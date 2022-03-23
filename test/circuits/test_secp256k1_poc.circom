pragma circom 2.0.2;

include "../../circuits/secp256k1.circom";

component main {public [x, y]} = Secp256k1PointOnCurve();
