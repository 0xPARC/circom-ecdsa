import path = require("path");
import { expect, assert } from 'chai';
const circom_tester = require('circom_tester');
const wasm_tester = circom_tester.wasm;

// TODO: Factor this out into some common code among all the tests
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

describe("BigMod n = 2, k = 2 exhaustive", function() {
    this.timeout(1000 * 1000);
    // runs circom compilation
    let circuit: any;
    before(async function () {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "test_bigmod_22.circom"));
    });

    // a, b, div, mod
    var test_cases: Array<[bigint, bigint, bigint, bigint]> = [];
    for (var a = 0n; a < 4 * 4 * 4 * 4; a++) {
        for (var b = 4n; b < 4 * 4; b++) {
	    var div = a / b;
	    var mod = a % b;
	    test_cases.push([a, b, div, mod]);
	}
    }

    var test_bigmod_22 = function (x: [bigint, bigint, bigint, bigint]) {
        const [a, b, div, mod] = x;

        var a_array: bigint[] = bigint_to_array(2, 4, a);
	var b_array: bigint[] = bigint_to_array(2, 2, b);
        var div_array: bigint[] = bigint_to_array(2, 3, div);
        var mod_array: bigint[] = bigint_to_array(2, 2, mod);	

    	it('Testing a: ' + a + ' b: ' + b, async function() {
	    let witness = await circuit.calculateWitness({"a": a_array, "b": b_array});
	    expect(witness[1]).to.equal(div_array[0]);
	    expect(witness[2]).to.equal(div_array[1]);
   	    expect(witness[3]).to.equal(div_array[2]);
	    expect(witness[4]).to.equal(mod_array[0]);
	    expect(witness[5]).to.equal(mod_array[1]);
	});
    }

    test_cases.forEach(test_bigmod_22);
});