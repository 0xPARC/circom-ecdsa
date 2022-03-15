pragma circom 2.0.2;

include "bigint_func.circom";

// 10 registers, 64 bits. registers can be overful
// adds 43 bits to overflow, so don't input overful registers which are > 208 bits
// input registers can also be negative; the overall input can be negative as well
template Secp256k1PrimeReduce10Registers() {
    signal input in[10];

    signal output out[4];
    var offset = (1<<32) + 977; // 33 bits
    var offset2 = ((1<<33) * 977) + (977 ** 2); // 43 bits
    
    out[3] <== (offset * in[7]) + in[3];
    out[2] <== (offset * in[6]) + in[2] + in[9];
    out[1] <== (offset2 * in[9]) + (offset * in[5]) + in[1] + in[8];
    out[0] <== (offset2 * in[8]) + (offset * in[4]) + in[0];
}

// 7 registers, 64 bits. registers can be overful
// adds 33 bits to overflow, so don't input overful registers which are > 218 bits
// input registers can also be negative; the overall input can be negative as well
template Secp256k1PrimeReduce7Registers() {
    signal input in[7];

    signal output out[4];
    var offset = (1<<32) + 977; // 33 bits
    
    out[3] <== in[3];
    out[2] <== (offset * in[6]) + in[2];
    out[1] <== (offset * in[5]) + in[1];
    out[0] <== (offset * in[4]) + in[0];
}

template CheckInRangeSecp256k1 () {
    signal input in[4];
    component range64[4];
    for(var i = 0; i < 4; i++){
        range64[i] = Num2Bits(64);
        range64[i].in <== in[i];
    }
    component isEqual[3];
    signal allEqual[4];
    allEqual[0] <== 1;
    for(var i = 1; i < 4; i++){
        isEqual[i-1] = IsEqual();
        isEqual[i-1].in[0] <== in[i];
        isEqual[i-1].in[1] <== (1<<64)-1;
        allEqual[i] <== allEqual[i-1] * isEqual[i-1].out;
    }
    signal c;
    c <== (1<<64) - ((1<<32) + (1<<9) + (1<<8) + (1<<7) + (1<<6) + (1<<4) + 1);
    //lowest register is less than c
    component lessThan = LessThan(64);
    lessThan.in[0] <== in[0];
    lessThan.in[1] <== c;
    (1-lessThan.out) * allEqual[3] === 0;
}

// 64 bit registers with m-bit overflow
// registers (and overall number) are potentially negative
template CheckCubicModPIsZero(m) {
    assert(m < 206); // since we deal with up to m+46 bit, potentially negative registers

    signal input in[10];

    // the secp256k1 field size, hardcoded
    signal p[4];
    p[0] <== 18446744069414583343;
    p[1] <== 18446744073709551615;
    p[2] <== 18446744073709551615;
    p[3] <== 18446744073709551615;

    // now, we compute a positive number congruent to `in` expressible in 4 overflowed registers.
    // for this representation, individual registers are allowed to be negative, but the final number
    // will be nonnegative overall.
    // first, we apply the secp 10-register reduction technique to reduce to 4 registers. this may result
    // in a negative number overall, but preserves congruence mod p.
    // our intermediate result is z = secpReduce(in)
    // second, we add a big multiple of p to z, to ensure that our final result is positive. 
    // since the registers of z are m + 43 bits, its max abs value is 2^(m+43 + 192) + 2^(m+43 + 128) + ...
    // so we add p * 2^(m-20), which is a bit under 2^(m+236) and larger than |z| < 2^(m+43+192) + eps
    signal reduced[4];
    component secpReducer = Secp256k1PrimeReduce10Registers();
    for (var i = 0; i < 10; i++) {
        secpReducer.in[i] <== in[i];
    }
    signal multipleOfP[4];
    for (var i = 0; i < 4; i++) {
        multipleOfP[i] <== p[i] * (1 << (m-20)); // m - 20 + 64 = m+44 bits
    }
    for (var i = 0; i < 4; i++) {
        reduced[i] <== secpReducer.out[i] + multipleOfP[i]; // max(m+43, m+44) + 1 = m+45 bits
    }

    // now we compute the quotient q, which serves as a witness. we can do simple bounding to show
    // that the the expected quotient is always expressible in 3 registers (i.e. < 2^192)
    // so long as m < 211
    signal q[3];

    var temp[100] = getProperRepresentation(m + 45, 64, 4, reduced);
    var proper[8];
    for (var i = 0; i < 8; i++) {
        proper[i] = temp[i];
    }

    var qVarTemp[2][100] = long_div(64, 4, 4, proper, p);
    for (var i = 0; i < 3; i++) {
        q[i] <-- qVarTemp[0][i];
    }

    // we need to constrain that q is in proper (3x64) representation
    component qRangeChecks[3];
    for (var i = 0; i < 3; i++) {
        qRangeChecks[i] = Num2Bits(64);
        qRangeChecks[i].in <== q[i];
    }

    // now we compute a representation qpProd = q * p
    signal qpProd[6];
    component qpProdComp = BigMultNoCarry(64, 64, 64, 3, 4);
    for (var i = 0; i < 3; i++) {
        qpProdComp.a[i] <== q[i];
    }
    for (var i = 0; i < 4; i++) {
        qpProdComp.b[i] <== p[i];
    }
    for (var i = 0; i < 6; i++) {
        qpProd[i] <== qpProdComp.out[i]; // 130 bits
    }

    // finally, check that qpProd == reduced
    component zeroCheck = CheckCarryToZero(64, m + 46, 6);
    for (var i = 0; i < 6; i++) {
        if (i < 4) { // reduced only has 4 registers
            zeroCheck.in[i] <== qpProd[i] - reduced[i]; // (m + 45) + 1 bits
        } else {
            zeroCheck.in[i] <== qpProd[i];
        }
    }
}

// 64 bit registers with m-bit overflow
// registers (and overall number) are potentially negative
template CheckQuadraticModPIsZero(m) {
    assert(m < 147); // so that we can assume q has 2 registers

    signal input in[7];

    // the secp256k1 field size, hardcoded
    signal p[4];
    p[0] <== 18446744069414583343;
    p[1] <== 18446744073709551615;
    p[2] <== 18446744073709551615;
    p[3] <== 18446744073709551615;

    // now, we compute a positive number congruent to `in` expressible in 4 overflowed registers.
    // for this representation, individual registers are allowed to be negative, but the final number
    // will be nonnegative overall.
    // first, we apply the secp 7-register reduction technique to reduce to 4 registers. this may result
    // in a negative number overall, but preserves congruence mod p.
    // our intermediate result is z = secpReduce(in)
    // second, we add a big multiple of p to z, to ensure that our final result is positive. 
    // since the registers of z are m + 33 bits, its max abs value is 2^(m+33 + 192) + 2^(m+33 + 128) + ...
    // so we add p * 2^(m-30), which is a bit under 2^(m+226) and larger than |z| < 2^(m+33+192) + eps
    signal reduced[4];
    component secpReducer = Secp256k1PrimeReduce7Registers();
    for (var i = 0; i < 7; i++) {
        secpReducer.in[i] <== in[i];
    }
    signal multipleOfP[4];
    for (var i = 0; i < 4; i++) {
        multipleOfP[i] <== p[i] * (1 << (m-30)); // m - 30 + 64 = m + 34 bits
    }
    for (var i = 0; i < 4; i++) {
        reduced[i] <== secpReducer.out[i] + multipleOfP[i]; // max(m+33, m+34) + 1 = m+35 bits
    }

    // now we compute the quotient q, which serves as a witness. we can do simple bounding to show
    // that the the expected quotient is always expressible in 2 registers (i.e. < 2^192)
    // so long as m < 147
    signal q[2];

    var temp[100] = getProperRepresentation(m + 35, 64, 4, reduced);
    var proper[8];
    for (var i = 0; i < 8; i++) {
        proper[i] = temp[i];
    }

    var qVarTemp[2][100] = long_div(64, 4, 4, proper, p);
    for (var i = 0; i < 2; i++) {
        q[i] <-- qVarTemp[0][i];
    }

    // we need to constrain that q is in proper (2x64) representation
    component qRangeChecks[2];
    for (var i = 0; i < 2; i++) {
        qRangeChecks[i] = Num2Bits(64);
        qRangeChecks[i].in <== q[i];
    }

    // now we compute a representation qpProd = q * p
    signal qpProd[5];
    component qpProdComp = BigMultNoCarry(64, 64, 64, 2, 4);
    for (var i = 0; i < 2; i++) {
        qpProdComp.a[i] <== q[i];
    }
    for (var i = 0; i < 4; i++) {
        qpProdComp.b[i] <== p[i];
    }
    for (var i = 0; i < 5; i++) {
        qpProd[i] <== qpProdComp.out[i]; // 130 bits
    }

    // finally, check that qpProd == reduced
    component zeroCheck = CheckCarryToZero(64, m + 36, 5);
    for (var i = 0; i < 5; i++) {
        if (i < 4) { // reduced only has 4 registers
            zeroCheck.in[i] <== qpProd[i] - reduced[i]; // (m + 35) + 1 bits
        } else {
            zeroCheck.in[i] <== qpProd[i];
        }
    }
}