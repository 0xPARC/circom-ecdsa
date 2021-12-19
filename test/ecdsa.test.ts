import path = require("path");

import { expect, assert } from 'chai';
const circom_tester = require('circom_tester');
const wasm_tester = circom_tester.wasm;

const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);

describe("ECDSAPrivToPubStride Test", function () {
    this.timeout(1000 * 1000);
    
    it("Sample", async() => {
        const circuit = await wasm_tester(path.join(__dirname, "circuits", "test_ecdsa.circom"));
	let witness;
	witness = await circuit.calculateWitness({"privkey": ["7", "0", "0"]});
	expect(Fr.e(Scalar.fromString(witness[1]))).to.equal(Fr.e(Scalar.fromString("59103311026955956754119100")));
	expect(Fr.e(Scalar.fromString(witness[2]))).to.equal(Fr.e(Scalar.fromString("16432869926048670770133004")));
	expect(Fr.e(Scalar.fromString(witness[3]))).to.equal(Fr.e(Scalar.fromString("7007383570325663759612303")));
	expect(Fr.e(Scalar.fromString(witness[4]))).to.equal(Fr.e(Scalar.fromString("74838692406509378584339674")));
	expect(Fr.e(Scalar.fromString(witness[5]))).to.equal(Fr.e(Scalar.fromString("64932989450846822570582095")));
	expect(Fr.e(Scalar.fromString(witness[6]))).to.equal(Fr.e(Scalar.fromString("8078726494313086148292984")));
    });
});

describe("Sample test set", function () {
    it('should run a test properly', function () {
        const myNumber = 12;
        expect(myNumber).to.equal(12);
    });
});