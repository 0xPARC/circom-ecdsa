import path = require("path");
import { expect, assert } from 'chai';
const circom_tester = require('circom_tester');
const wasm_tester = circom_tester.wasm;

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

let P = BigInt("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F");
let n = 64;
let k = 4
let p_arr = bigint_to_array(n, k, P);

let rands: Array<bigint> = [
    37341064718519768n, 80197949145034304n, 52311183102518480n, 79170924519984336n,
    72040116375830584n, 96811527250814784n, 83704621808075920n, 97335777836843424n,
    36191564228607768n, 68640101432687264n, 83088292537602432n, 85829122398627552n,
    76037297289358544n, 58257037970984608n, 12372783206242798n, 62671901797711336n,
    48726329364784608n, 77742828232298384n, 12962932632943170n, 34319361389693960n,
];

let circuit: any

describe("secp256k1 field", function () {
    it("p should be correct", function () {
        expect(p_arr[0]).to.equal(18446744069414583343n);
        expect(p_arr[1]).to.equal(18446744073709551615n);
        expect(p_arr[2]).to.equal(18446744073709551615n);
        expect(p_arr[3]).to.equal(18446744073709551615n);
    });
});

describe("secp256k1 Fp modulo", function () {
    // runs circom compilation
    let circuit: any;
    before(async function () {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "test_secp256k1_fp_mod.circom"));
    });

    // v, v mod P
    var test_cases: Array<[bigint, bigint]> = [];

    for (let i = -5; i < 5; i ++) {
        let v = P + BigInt(i);
        let v_mod_p = v % P;
        test_cases.push([v, v_mod_p]);
    }
    
    var test_fp_mod = function(x: [bigint, bigint]) {
        const [v, v_mod_p] = x;
        const a_array = bigint_to_array(n, k, v);
        const expected_mod = bigint_to_array(n, k, v_mod_p);

        it('Testing a: ' + v, async function() {
            let witness = await circuit.calculateWitness({"a": a_array });
            let mod_output = witness.slice(1, 1 + k);

            for (let i = 0; i < expected_mod.length; i ++) {
                expect(mod_output[i]).to.equal(expected_mod[i]);
            }
        });
    }

    test_cases.forEach(test_fp_mod);
});

describe("secp256k1 Fp addition", function () {
    let circuit: any;
    before(async function () {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "test_secp256k1_fp_add.circom"));
    });

    // a, b, (a + b) mod P
    var test_cases: Array<[bigint, bigint, bigint]> = [];

    for (let rand of rands) {
        const a = (P - (rand)) % P;
        const b = (P + (rand * 123456n * 987654n * 92748572n)) % P;
        assert((a + b) > P);
        let res = (a + b) % P;

        // test cases where a+b will overflow
        test_cases.push([a, b, res]);

        // test cases where a+b will not overflow
        test_cases.push([rand, rand, (rand + rand) % P]);
    }

    var test_fp_add = function(x: [bigint, bigint, bigint]) {
        let [a, b, res] = x;
        let a_array = bigint_to_array(n, k, a);
        let b_array = bigint_to_array(n, k, b);
        let res_array = bigint_to_array(n, k, res);

        it('Testing ' + a + ' + ' + b, async function() {
            let witness = await circuit.calculateWitness({ a: a_array, b: b_array });
            let output = witness.slice(1, 1 + k);
            for (let i = 0; i < res_array.length; i ++) {
                expect(output[i]).to.equal(res_array[i]);
            }
        });
    }

    test_cases.forEach(test_fp_add);
})

describe("secp256k1 Fp subtraction", function () {
    let circuit: any;
    before(async function () {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "test_secp256k1_fp_sub.circom"));
    });

    // a, b, (a - b) mod P
    var test_cases: Array<[bigint, bigint, bigint]> = [];

    for (let i = 0; i < rands.length; i += 2){ 
        // roughly half of these test cases will underflow
        const rand = rands[i];
        const rand2 = rands[i + 1];
        const a = (P - (rand * 3n)) % P;
        const b = (P - (rand2 * 2n)) % P;

        let a_minus_b = a - b;
        if (a_minus_b < 0n) {
            a_minus_b = P - (-1n * a_minus_b);
        } else {
            a_minus_b = a_minus_b % P;
        }
        assert(a_minus_b >= 0n);

        test_cases.push([a, b, a_minus_b]);
    }

    var test_fp_sub = function(x: [bigint, bigint, bigint]) {
        let [a, b, res] = x;
        let a_array = bigint_to_array(n, k, a);
        let b_array = bigint_to_array(n, k, b);
        let res_array = bigint_to_array(n, k, res);

        it('Testing ' + a + ' - ' + b, async function() {
            let witness = await circuit.calculateWitness({ a: a_array, b: b_array });
            let output = witness.slice(1, 1 + k);
            for (let i = 0; i < res_array.length; i ++) {
                expect(output[i]).to.equal(res_array[i]);
            }
        });
    }

    test_cases.forEach(test_fp_sub);
})

describe("secp256k1 Fp multiplication", function () {
    let circuit: any;
    before(async function () {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "test_secp256k1_fp_mul.circom"));
    });

    // a, b, (a * b) mod P
    var test_cases: Array<[bigint, bigint, bigint]> = [];

    for (let i = 0; i < rands.length; i += 2){ 
        const rand = rands[i];
        const rand2 = rands[i + 1];
        const a = (P - (rand * 3n)) % P;
        const b = (P - (rand2 * 2n)) % P;

        let a_mul_b = (a * b) % P;

        // test cases where a*b will probably overflow
        test_cases.push([a, b, a_mul_b]);

        // test cases where a*b will probably not overflow
        test_cases.push([rand, rand2, (rand * rand2) % P]);
    }

    var test_fp_mul = function(x: [bigint, bigint, bigint]) {
        let [a, b, res] = x;
        let a_array = bigint_to_array(n, k, a);
        let b_array = bigint_to_array(n, k, b);
        let res_array = bigint_to_array(n, k, res);

        it('Testing ' + a + ' * ' + b, async function() {
            let witness = await circuit.calculateWitness({ a: a_array, b: b_array });
            let output = witness.slice(1, 1 + k);
            for (let i = 0; i < res_array.length; i ++) {
                expect(output[i]).to.equal(res_array[i]);
            }
        });
    }

    test_cases.forEach(test_fp_mul);
})
