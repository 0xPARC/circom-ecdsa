import path = require("path");

import { expect, assert } from 'chai';
import { getPublicKey, sign, Point } from '@noble/secp256k1';
const circom_tester = require('circom_tester');
const wasm_tester = circom_tester.wasm;

const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);

function bigint_to_tuple(x: bigint) {
    let mod: bigint = 2n ** 64n;
    let ret: [bigint, bigint, bigint, bigint] = [0n, 0n, 0n, 0n];

    var x_temp: bigint = x;
    for (var idx = 0; idx < ret.length; idx++) {
        ret[idx] = x_temp % mod;
        x_temp = x_temp / mod;
    }
    return ret;
}

function bigint_to_array(n: number, k: number, x: bigint) {
    let mod: bigint = 1n;
    for (var idx = 0; idx < n; idx++) {
        mod = mod * 2n;
    }

    let ret: bigint[] = [];
    var x_temp: bigint = x;
    for (var idx = 0; idx < k; idx++) {
        ret.push(x_temp % mod);
        x_temp = x_temp / mod;
    }
    return ret;
}

// converts x = sum of a[i] * 2 ** (small_stride * i) for 0 <= 2 ** small_stride - 1
//      to:     sum of a[i] * 2 ** (stride * i)
function get_strided_bigint(stride: bigint, small_stride: bigint, x: bigint) {
    var ret: bigint = 0n;
    var exp: bigint = 0n;
    while (x > 0) {
        var mod: bigint = x % (2n ** small_stride);
        ret = ret + mod * (2n ** (stride * exp));
        x = x / (2n ** small_stride);
        exp = exp + 1n;
    }
    return ret;
}

describe("ECDSAPrivToPub", function () {
    this.timeout(1000 * 1000);

    // runs circom compilation
    let circuit: any;
    before(async function () {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "test_ecdsa.circom"));
    });

    // privkey, pub0, pub1
    var test_cases: Array<[bigint, bigint, bigint]> = [];

    // 4 randomly generated privkeys
    var privkeys: Array<bigint> = [88549154299169935420064281163296845505587953610183896504176354567359434168161n,
                                   37706893564732085918706190942542566344879680306879183356840008504374628845468n,
                                   90388020393783788847120091912026443124559466591761394939671630294477859800601n,
                                   110977009687373213104962226057480551605828725303063265716157300460694423838923n];


    // 16 more keys
    for (var cnt = 1n; cnt < 2n ** 4n; cnt++) {
        var privkey: bigint = get_strided_bigint(10n, 1n, cnt);
        privkeys.push(privkey);
    }

    for (var idx = 0; idx < privkeys.length; idx++) {
        var pubkey: Point = Point.fromPrivateKey(privkeys[idx]);
        test_cases.push([privkeys[idx], pubkey.x, pubkey.y]);
    }

    var test_ecdsa_instance = function (keys: [bigint, bigint, bigint]) {
        let privkey = keys[0];
        let pub0 = keys[1];
        let pub1 = keys[2];

        var priv_tuple: [bigint, bigint, bigint, bigint] = bigint_to_tuple(privkey);
        var pub0_tuple: [bigint, bigint, bigint, bigint] = bigint_to_tuple(pub0);
        var pub1_tuple: [bigint, bigint, bigint, bigint] = bigint_to_tuple(pub1);

        it('Testing privkey: ' + privkey + ' pubkey.x: ' + pub0 + ' pubkey.y: ' + pub1, async function() {
            let witness = await circuit.calculateWitness({"privkey": priv_tuple});
            expect(witness[1]).to.equal(pub0_tuple[0]);
            expect(witness[2]).to.equal(pub0_tuple[1]);
            expect(witness[3]).to.equal(pub0_tuple[2]);
            expect(witness[4]).to.equal(pub0_tuple[3]);
            expect(witness[5]).to.equal(pub1_tuple[0]);
            expect(witness[6]).to.equal(pub1_tuple[1]);
            expect(witness[7]).to.equal(pub1_tuple[2]);
            expect(witness[8]).to.equal(pub1_tuple[3]);
            await circuit.checkConstraints(witness);
        });
    }

    test_cases.forEach(test_ecdsa_instance);
});

// bigendian
function bigint_to_Uint8Array(x: bigint) {
    var ret: Uint8Array = new Uint8Array(32);
    for (var idx = 31; idx >= 0; idx--) {
        ret[idx] = Number(x % 256n);
        x = x / 256n;
    }
    return ret;
}

// bigendian
function Uint8Array_to_bigint(x: Uint8Array) {
    var ret: bigint = 0n;
    for (var idx = 0; idx < x.length; idx++) {
        ret = ret * 256n;
        ret = ret + BigInt(x[idx]);
    }
    return ret;
}

describe("ECDSAVerifyNoPubkeyCheck", function () {
    this.timeout(1000 * 1000);

    // privkey, msghash, pub0, pub1
    var test_cases: Array<[bigint, bigint, bigint, bigint]> = [];
    var privkeys: Array<bigint> = [88549154299169935420064281163296845505587953610183896504176354567359434168161n,
                                   37706893564732085918706190942542566344879680306879183356840008504374628845468n,
                                   90388020393783788847120091912026443124559466591761394939671630294477859800601n,
                                   110977009687373213104962226057480551605828725303063265716157300460694423838923n];
    for (var idx = 0; idx < privkeys.length; idx++) {
        var pubkey: Point = Point.fromPrivateKey(privkeys[idx]);
        var msghash_bigint: bigint = 1234n;
            test_cases.push([privkeys[idx], msghash_bigint, pubkey.x, pubkey.y]);
    }

    let circuit: any;
    before(async function () {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "test_ecdsa_verify.circom"));
    });

    var test_ecdsa_verify = function (test_case: [bigint, bigint, bigint, bigint]) {
        let privkey = test_case[0];
        let msghash_bigint = test_case[1];
        let pub0 = test_case[2];
        let pub1 = test_case[3];

        var msghash: Uint8Array = bigint_to_Uint8Array(msghash_bigint);

        it('Testing correct sig: privkey: ' + privkey + ' msghash: ' + msghash_bigint + ' pub0: ' + pub0 + ' pub1: ' + pub1, async function() {
            // in compact format: r (big-endian), 32-bytes + s (big-endian), 32-bytes
            var sig: Uint8Array = await sign(msghash, bigint_to_Uint8Array(privkey), {canonical: true, der: false})
            var r: Uint8Array = sig.slice(0, 32);
            var r_bigint: bigint = Uint8Array_to_bigint(r);
            var s: Uint8Array = sig.slice(32, 64);
            var s_bigint:bigint = Uint8Array_to_bigint(s);

            var priv_array: bigint[] = bigint_to_array(64, 4, privkey);
            var r_array: bigint[] = bigint_to_array(64, 4, r_bigint);
            var s_array: bigint[] = bigint_to_array(64, 4, s_bigint);
            var msghash_array: bigint[] = bigint_to_array(64, 4, msghash_bigint);
            var pub0_array: bigint[] = bigint_to_array(64, 4, pub0);
            var pub1_array: bigint[] = bigint_to_array(64, 4, pub1);
            var res = 1n;

            console.log('r', r_bigint);
            console.log('s', s_bigint);
            let witness = await circuit.calculateWitness({"r": r_array,
                                                          "s": s_array,
                                                          "msghash": msghash_array,
                                                          "pubkey": [pub0_array, pub1_array]});
            expect(witness[1]).to.equal(res);
            await circuit.checkConstraints(witness);
        });

        it('Testing incorrect sig: privkey: ' + privkey + ' msghash: ' + msghash_bigint + ' pub0: ' + pub0 + ' pub1: ' + pub1, async function() {
            // in compact format: r (big-endian), 32-bytes + s (big-endian), 32-bytes
            var sig: Uint8Array = await sign(msghash, bigint_to_Uint8Array(privkey), {canonical: true, der: false})
            var r: Uint8Array = sig.slice(0, 32);
            var r_bigint: bigint = Uint8Array_to_bigint(r);
            var s: Uint8Array = sig.slice(32, 64);
            var s_bigint:bigint = Uint8Array_to_bigint(s);

            var priv_array: bigint[] = bigint_to_array(64, 4, privkey);
            var r_array: bigint[] = bigint_to_array(64, 4, r_bigint + 1n);
            var s_array: bigint[] = bigint_to_array(64, 4, s_bigint);
            var msghash_array: bigint[] = bigint_to_array(64, 4, msghash_bigint);
            var pub0_array: bigint[] = bigint_to_array(64, 4, pub0);
            var pub1_array: bigint[] = bigint_to_array(64, 4, pub1);
            var res = 0n;

            console.log('r', r_bigint + 1n);
            console.log('s', s_bigint);
            let witness = await circuit.calculateWitness({"r": r_array,
                                                          "s": s_array,
                                                          "msghash": msghash_array,
                                                          "pubkey": [pub0_array, pub1_array]});
            expect(witness[1]).to.equal(res);
            await circuit.checkConstraints(witness);
        });
    }

    test_cases.forEach(test_ecdsa_verify);
});
