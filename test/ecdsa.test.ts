import path = require("path");

import { expect, assert } from 'chai';
import { getPublicKey, Point } from '@noble/secp256k1';
const circom_tester = require('circom_tester');
const wasm_tester = circom_tester.wasm;

const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);

function bigint_to_tuple(x: bigint) {
    // 2 ** 86
    let mod: bigint = 77371252455336267181195264n;
    let ret: [bigint, bigint, bigint] = [0n, 0n, 0n];

    var x_temp: bigint = x;
    for (var idx = 0; idx < 3; idx++) {
        ret[idx] = x_temp % mod;
        x_temp = x_temp / mod;
    }
    return ret;
}

describe("ECDSAPrivToPubStride", function () {
    this.timeout(1000 * 1000);

    // runs circom compilation
    let circuit: any;
    before(async function () {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "test_ecdsa.circom"));
    });

    // each incremental witness computation does not require compilation
    it("Default sample", async() => {
        let witness = await circuit.calculateWitness({"privkey": ["7", "0", "0"]});
        expect(Fr.e(Scalar.fromString(witness[1]))).to.equal(Fr.e(Scalar.fromString("59103311026955956754119100")));
        expect(Fr.e(Scalar.fromString(witness[2]))).to.equal(Fr.e(Scalar.fromString("16432869926048670770133004")));
        expect(Fr.e(Scalar.fromString(witness[3]))).to.equal(Fr.e(Scalar.fromString("7007383570325663759612303")));
        expect(Fr.e(Scalar.fromString(witness[4]))).to.equal(Fr.e(Scalar.fromString("74838692406509378584339674")));
        expect(Fr.e(Scalar.fromString(witness[5]))).to.equal(Fr.e(Scalar.fromString("64932989450846822570582095")));
        expect(Fr.e(Scalar.fromString(witness[6]))).to.equal(Fr.e(Scalar.fromString("8078726494313086148292984")));
    });

    // privkey, pub0, pub1
    var test_cases: Array<[bigint, bigint, bigint]> = [];

    // 4 randomly chosen private keys
    var privkeys: Array<bigint> = [88549154299169935420064281163296845505587953610183896504176354567359434168161n,
                                   37706893564732085918706190942542566344879680306879183356840008504374628845468n,
				   90388020393783788847120091912026443124559466591761394939671630294477859800601n,
				   110977009687373213104962226057480551605828725303063265716157300460694423838923n];
    for (var idx = 0; idx < 4; idx++) {
        var pubkey: Point = Point.fromPrivateKey(privkey);
        test_cases.push([privkey, pubkey.x, pubkey.y]);
    }

    for (var privkey = 1n; privkey <= 5n; privkey++) {
        var pubkey: Point = Point.fromPrivateKey(privkey);
        test_cases.push([privkey, pubkey.x, pubkey.y]);
    }

    var test_ecdsa_instance = function (keys: [bigint, bigint, bigint]) {
        let privkey = keys[0];
        let pub0 = keys[1];
        let pub1 = keys[2];

        var priv_tuple: [bigint, bigint, bigint] = bigint_to_tuple(privkey);
        var pub0_tuple: [bigint, bigint, bigint] = bigint_to_tuple(pub0);
        var pub1_tuple: [bigint, bigint, bigint] = bigint_to_tuple(pub1);

        it('Testing privkey: ' + privkey + ' pubkey.x: ' + pub0 + ' pubkey.y: ' + pub1, async function() {
            let witness = await circuit.calculateWitness({"privkey": priv_tuple});
            expect(witness[1]).to.equal(pub0_tuple[0]);
            expect(witness[2]).to.equal(pub0_tuple[1]);
            expect(witness[3]).to.equal(pub0_tuple[2]);
            expect(witness[4]).to.equal(pub1_tuple[0]);
            expect(witness[5]).to.equal(pub1_tuple[1]);
            expect(witness[6]).to.equal(pub1_tuple[2]);
        });
    }

    test_cases.forEach(test_ecdsa_instance);
});

describe("Sample test set", function () {
    it('should run a test properly', function () {
        const myNumber = 12;
        expect(myNumber).to.equal(12);
    });
});
