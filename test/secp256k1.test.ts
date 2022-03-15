import path = require("path");

import { expect, assert } from 'chai';
import { getPublicKey, Point } from '@noble/secp256k1';
const circom_tester = require('circom_tester');
const wasm_tester = circom_tester.wasm;

const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);

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

describe("Secp256k1AddUnequal", function () {
    this.timeout(1000 * 1000);

    // runs circom compilation
    let circuit: any;
    before(async function () {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "test_secp256k1_add.circom"));
    });

    // pub0x, pub0y, pub1x, pub0y, sumx, sumy
    var test_cases: Array<[bigint, bigint, bigint, bigint, bigint, bigint]> = [];

    // 4 randomly chosen private keys
    var privkeys: Array<bigint> = [88549154299169935420064281163296845505587953610183896504176354567359434168161n,
                                   37706893564732085918706190942542566344879680306879183356840008504374628845468n,
                                   90388020393783788847120091912026443124559466591761394939671630294477859800601n,
                                   110977009687373213104962226057480551605828725303063265716157300460694423838923n];
    var pubkeys: Array<Point> = [];
    for (var idx = 0; idx < 4; idx++) {
        var pubkey: Point = Point.fromPrivateKey(privkeys[idx]);
        pubkeys.push(pubkey);
    }

    for (var idx = 0; idx < 4; idx++) {
        for (var idx2 = idx + 1; idx2 < 4; idx2++) {
            var sum: Point = pubkeys[idx].add(pubkeys[idx2]);
            test_cases.push([pubkeys[idx].x, pubkeys[idx].y,
                             pubkeys[idx2].x, pubkeys[idx2].y,
                             sum.x, sum.y]);
        }
    }

    var test_secp256k1_add_instance = function (test_case: [bigint, bigint, bigint, bigint, bigint, bigint]) {
        let pub0x = test_case[0];
        let pub0y = test_case[1];
        let pub1x = test_case[2];
        let pub1y = test_case[3];
        let sumx = test_case[4];
        let sumy = test_case[5];

        var pub0x_array: bigint[] = bigint_to_array(86, 3, pub0x);
        var pub0y_array: bigint[] = bigint_to_array(86, 3, pub0y);
        var pub1x_array: bigint[] = bigint_to_array(86, 3, pub1x);
        var pub1y_array: bigint[] = bigint_to_array(86, 3, pub1y);
        var sumx_array: bigint[] = bigint_to_array(86, 3, sumx);
        var sumy_array: bigint[] = bigint_to_array(86, 3, sumy);

        it('Testing pub0x: ' + pub0x + ' pub0y: ' + pub0y + ' pub1x: ' + pub1x + ' pub1y: ' + pub1y + ' sumx: ' + sumx + ' sumy: ' + sumy, async function() {
            let witness = await circuit.calculateWitness({"a": [pub0x_array, pub0y_array],
                                                          "b": [pub1x_array, pub1y_array]});
            expect(witness[1]).to.equal(sumx_array[0]);
            expect(witness[2]).to.equal(sumx_array[1]);
            expect(witness[3]).to.equal(sumx_array[2]);
            expect(witness[4]).to.equal(sumy_array[0]);
            expect(witness[5]).to.equal(sumy_array[1]);
            expect(witness[6]).to.equal(sumy_array[2]);
            await circuit.checkConstraints(witness);
        });
    }

    test_cases.forEach(test_secp256k1_add_instance);
});

// TODO: figure out some way to test that if point is not on curve, pf gen should fail
describe("Secp256k1PointOnCurve", function () {
    this.timeout(1000 * 1000);

    // runs circom compilation
    let circuit: any;
    before(async function () {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "test_secp256k1_poc.circom"));
    });

    // x, y, on/off
    var test_cases: Array<[bigint, bigint]> = [];

    // base point G on curve
    test_cases.push([
        55066263022277343669578718895168534326250603453777594175500187360389116729240n,
        32670510020758816978083085130507043184471273380659243275938904335757337482424n
    ]);

    // TODO: figure out how to test that circuit fails on this input
    /*
    // modified point not on curve
    test_cases.push([
        45066263022277343669578718895168534326250603453777594175500187360389116729240n,
        22670510020758816978083085130507043184471273380659243275938904335757337482424n
    ]);
    */

    var test_secp256k1_poc_instance = function (test_case: [bigint, bigint]) {
        let x = test_case[0];
        let y = test_case[1];

        var x_array: bigint[] = bigint_to_array(86, 3, x);
        var y_array: bigint[] = bigint_to_array(86, 3, y);

        it('Testing x: ' + x + ' y: ' + y,
                async function() {
                    let witness = await circuit.calculateWitness({
                        "x": x_array, "y": y_array,
                    });
                    await circuit.checkConstraints(witness);
                });
    }

    test_cases.forEach(test_secp256k1_poc_instance);
});
