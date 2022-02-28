pragma circom 2.0.2;

include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/multiplexer.circom";

include "bigint.circom";
include "bigint_func.circom";
include "secp256k1_func.circom";

// requires a[0] != b[0]
//
// Implements:
// lamb = (b[1] - a[1]) / (b[0] - a[0]) % p
// out[0] = lamb ** 2 - a[0] - b[0] % p
// out[1] = lamb * (a[0] - out[0]) - a[1] % p
template Secp256k1AddUnequal(n, k) {
    signal input a[2][k];
    signal input b[2][k];

    signal output out[2][k];

    var p[100] = get_secp256k1_prime(n, k);

    // b[1] - a[1]
    component sub1 = BigSubModP(n, k);
    for (var i = 0; i < k; i++) {
        sub1.a[i] <== b[1][i];
        sub1.b[i] <== a[1][i];
        sub1.p[i] <== p[i];
    }

    // b[0] - a[0]
    component sub0 = BigSubModP(n, k);
    for (var i = 0; i < k; i++) {
        sub0.a[i] <== b[0][i];
        sub0.b[i] <== a[0][i];
        sub0.p[i] <== p[i];
    }

    signal lambda[k];
    var sub0inv[100] = mod_inv(n, k, sub0.out, p);
    var sub1_sub0inv[100] = prod(n, k, sub1.out, sub0inv);
    var lamb_arr[2][100] = long_div(n, k, sub1_sub0inv, p);
    for (var i = 0; i < k; i++) {
        lambda[i] <-- lamb_arr[1][i];
    }
    component range_checks[k];
    for (var i = 0; i < k; i++) {
        range_checks[i] = Num2Bits(n);
        range_checks[i].in <== lambda[i];
    }
    component lt = BigLessThan(n, k);
    for (var i = 0; i < k; i++) {
        lt.a[i] <== lambda[i];
        lt.b[i] <== p[i];
    }
    lt.out === 1;

    component lambda_check = BigMultModP(n, k);
    for (var i = 0; i < k; i++) {
        lambda_check.a[i] <== sub0.out[i];
        lambda_check.b[i] <== lambda[i];
        lambda_check.p[i] <== p[i];
    }
    for (var i = 0; i < k; i++) {
        lambda_check.out[i] === sub1.out[i];
    }

    component lambdasq = BigMultModP(n, k);
    for (var i = 0; i < k; i++) {
        lambdasq.a[i] <== lambda[i];
        lambdasq.b[i] <== lambda[i];
        lambdasq.p[i] <== p[i];
    }
    component out0_pre = BigSubModP(n, k);
    for (var i = 0; i < k; i++) {
        out0_pre.a[i] <== lambdasq.out[i];
        out0_pre.b[i] <== a[0][i];
        out0_pre.p[i] <== p[i];
    }
    component out0 = BigSubModP(n, k);
    for (var i = 0; i < k; i++) {
        out0.a[i] <== out0_pre.out[i];
        out0.b[i] <== b[0][i];
        out0.p[i] <== p[i];
    }
    for (var i = 0; i < k; i++) {
        out[0][i] <== out0.out[i];
    }

    component out1_0 = BigSubModP(n, k);
    for (var i = 0; i < k; i++) {
        out1_0.a[i] <== a[0][i];
        out1_0.b[i] <== out[0][i];
        out1_0.p[i] <== p[i];
    }
    component out1_1 = BigMultModP(n, k);
    for (var i = 0; i < k; i++) {
        out1_1.a[i] <== lambda[i];
        out1_1.b[i] <== out1_0.out[i];
        out1_1.p[i] <== p[i];
    }
    component out1 = BigSubModP(n, k);
    for (var i = 0; i < k; i++) {
        out1.a[i] <== out1_1.out[i];
        out1.b[i] <== a[1][i];
        out1.p[i] <== p[i];
    }
    for (var i = 0; i < k; i++) {
        out[1][i] <== out1.out[i];
    }
}

// Implements:
// lamb = (3 / 2) * in[0] ** 2 / in[1] % p
// out[0] = lamb ** 2 - 2 * a[0] % p
// out[1] = lamb * (in[0] - out[0]) - in[1] % p
template Secp256k1Double(n, k) {
    signal input in[2][k];

    signal output out[2][k];

    var p[100] = get_secp256k1_prime(n, k);

    component in0_sq = BigMultModP(n, k);
    for (var i = 0; i < k; i++) {
        in0_sq.a[i] <== in[0][i];
        in0_sq.b[i] <== in[0][i];
        in0_sq.p[i] <== p[i];
    }

    var long_2[100];
    var long_3[100];
    long_2[0] = 2;
    long_3[0] = 3;
    for (var i = 1; i < k; i++) {
        long_2[i] = 0;
        long_3[i] = 0;
    }
    var inv_2[100] = mod_inv(n, k, long_2, p);
    var long_3_div_2[100] = prod(n, k, long_3, inv_2);
    var long_3_div_2_mod_p[2][100] = long_div(n, k, long_3_div_2, p);

    component numer = BigMultModP(n, k);
    for (var i = 0; i < k; i++) {
        numer.a[i] <== long_3_div_2_mod_p[1][i];
        numer.b[i] <== in0_sq.out[i];
        numer.p[i] <== p[i];
    }

    signal lambda[k];
    var denom_inv[100] = mod_inv(n, k, in[1], p);
    var product[100] = prod(n, k, numer.out, denom_inv);
    var lamb_arr[2][100] = long_div(n, k, product, p);
    for (var i = 0; i < k; i++) {
        lambda[i] <-- lamb_arr[1][i];
    }
    component lt = BigLessThan(n, k);
    for (var i = 0; i < k; i++) {
        lt.a[i] <== lambda[i];
        lt.b[i] <== p[i];
    }
    lt.out === 1;

    component lambda_range_checks[k];
    component lambda_check = BigMultModP(n, k);
    for (var i = 0; i < k; i++) {
        lambda_range_checks[i] = Num2Bits(n);
        lambda_range_checks[i].in <== lambda[i];

        lambda_check.a[i] <== in[1][i];
        lambda_check.b[i] <== lambda[i];
        lambda_check.p[i] <== p[i];
    }
    for (var i = 0; i < k; i++) {
        lambda_check.out[i] === numer.out[i];
    }

    component lambdasq = BigMultModP(n, k);
    for (var i = 0; i < k; i++) {
        lambdasq.a[i] <== lambda[i];
        lambdasq.b[i] <== lambda[i];
        lambdasq.p[i] <== p[i];
    }
    component out0_pre = BigSubModP(n, k);
    for (var i = 0; i < k; i++) {
        out0_pre.a[i] <== lambdasq.out[i];
        out0_pre.b[i] <== in[0][i];
        out0_pre.p[i] <== p[i];
    }
    component out0 = BigSubModP(n, k);
    for (var i = 0; i < k; i++) {
        out0.a[i] <== out0_pre.out[i];
        out0.b[i] <== in[0][i];
        out0.p[i] <== p[i];
    }
    for (var i = 0; i < k; i++) {
        out[0][i] <== out0.out[i];
    }

    component out1_0 = BigSubModP(n, k);
    for (var i = 0; i < k; i++) {
        out1_0.a[i] <== in[0][i];
        out1_0.b[i] <== out[0][i];
        out1_0.p[i] <== p[i];
    }
    component out1_1 = BigMultModP(n, k);
    for (var i = 0; i < k; i++) {
        out1_1.a[i] <== lambda[i];
        out1_1.b[i] <== out1_0.out[i];
        out1_1.p[i] <== p[i];
    }
    component out1 = BigSubModP(n, k);
    for (var i = 0; i < k; i++) {
        out1.a[i] <== out1_1.out[i];
        out1.b[i] <== in[1][i];
        out1.p[i] <== p[i];
    }
    for (var i = 0; i < k; i++) {
        out[1][i] <== out1.out[i];
    }
}

template Secp256k1ScalarMult(n, k) {
    signal input scalar[k];
    signal input point[2][k];

    signal output out[2][k];

    component n2b[k];
    for (var i = 0; i < k; i++) {
        n2b[i] = Num2Bits(n);
        n2b[i].in <== scalar[i];
    }

    // has_prev_non_zero[n * i + j] == 1 if there is a nonzero bit in location [i][j] or higher order bit
    component has_prev_non_zero[k * n];
    for (var i = k - 1; i >= 0; i--) {
        for (var j = n - 1; j >= 0; j--) {
            has_prev_non_zero[n * i + j] = OR();
            if (i == k - 1 && j == n - 1) {
                has_prev_non_zero[n * i + j].a <== 0;
                has_prev_non_zero[n * i + j].b <== n2b[i].out[j];
            } else {
                has_prev_non_zero[n * i + j].a <== has_prev_non_zero[n * i + j + 1].out;
                has_prev_non_zero[n * i + j].b <== n2b[i].out[j];
            }
        }
    }

    signal partial[n * k][2][k];
    signal intermed[n * k - 1][2][k];
    component adders[n * k - 1];
    component doublers[n * k - 1];
    for (var i = k - 1; i >= 0; i--) {
        for (var j = n - 1; j >= 0; j--) {
            if (i == k - 1 && j == n - 1) {
                for (var idx = 0; idx < k; idx++) {
                    partial[n * i + j][0][idx] <== point[0][idx];
                    partial[n * i + j][1][idx] <== point[1][idx];
                }
            }
            if (i < k - 1 || j < n - 1) {
                adders[n * i + j] = Secp256k1AddUnequal(n, k);
                doublers[n * i + j] = Secp256k1Double(n, k);
                for (var idx = 0; idx < k; idx++) {
                    doublers[n * i + j].in[0][idx] <== partial[n * i + j + 1][0][idx];
                    doublers[n * i + j].in[1][idx] <== partial[n * i + j + 1][1][idx];
                }
                for (var idx = 0; idx < k; idx++) {
                    adders[n * i + j].a[0][idx] <== doublers[n * i + j].out[0][idx];
                    adders[n * i + j].a[1][idx] <== doublers[n * i + j].out[1][idx];
                    adders[n * i + j].b[0][idx] <== point[0][idx];
                    adders[n * i + j].b[1][idx] <== point[1][idx];
                }
                // partial[n * i + j]
                // = has_prev_non_zero[n * i + j + 1] * ((1 - n2b[i].out[j]) * doublers[n * i + j] + n2b[i].out[j] * adders[n * i + j])
                //   + (1 - has_prev_non_zero[n * i + j + 1]) * point
                for (var idx = 0; idx < k; idx++) {
                    intermed[n * i + j][0][idx] <== n2b[i].out[j] * (adders[n * i + j].out[0][idx] - doublers[n * i + j].out[0][idx]) + doublers[n * i + j].out[0][idx];
                    intermed[n * i + j][1][idx] <== n2b[i].out[j] * (adders[n * i + j].out[1][idx] - doublers[n * i + j].out[1][idx]) + doublers[n * i + j].out[1][idx];
                    partial[n * i + j][0][idx] <== has_prev_non_zero[n * i + j + 1].out * (intermed[n * i + j][0][idx] - point[0][idx]) + point[0][idx];
                    partial[n * i + j][1][idx] <== has_prev_non_zero[n * i + j + 1].out * (intermed[n * i + j][1][idx] - point[1][idx]) + point[1][idx];
                }
            }
        }
    }

    for (var idx = 0; idx < k; idx++) {
        out[0][idx] <== partial[0][0][idx];
        out[1][idx] <== partial[0][1][idx];
    }
}

template Secp256k1ScalarMultWindow(n, k, stride) {
    signal input scalar[k];
    signal input point[2][k];

    signal output out[2][k];

    var BITS = n * k;
    var num_strides = BITS \ stride;
    if (BITS % stride > 0) {
	num_strides = num_strides + 1;
    } 
    
    // compute dynamic window of: 2 * point, 3 * point, .. (2 ** stride - 1) * point
    signal cache[(1 << stride) - 2][2][k];
    component cache_doublers[(1 << (stride - 1)) - 1];
    component cache_adders[(1 << (stride - 1)) - 1];
    var cd_cnt = 0;
    var ca_cnt = 0;
    for (var i = 1; i < stride; i++) {
	for (var j = (1 << i) \ 2; j < (1 << i); j++) {
	    cache_doublers[cd_cnt] = Secp256k1Double(n, k);
	    cache_adders[ca_cnt] = Secp256k1AddUnequal(n, k);

	    for (var idx = 0; idx < k; idx++) {
		if (j > 1) {
		    cache_doublers[cd_cnt].in[0][idx] <== cache[j - 2][0][idx];
		    cache_doublers[cd_cnt].in[1][idx] <== cache[j - 2][1][idx];
		} else {
		    cache_doublers[cd_cnt].in[0][idx] <== point[0][idx];
		    cache_doublers[cd_cnt].in[1][idx] <== point[1][idx];
		}
	    }
	    for (var idx = 0; idx < k; idx++) {
		cache[2 * j - 2][0][idx] <== cache_doublers[cd_cnt].out[0][idx];
		cache[2 * j - 2][1][idx] <== cache_doublers[cd_cnt].out[1][idx];
	    }

	    for (var idx = 0; idx < k; idx++) {
		cache_adders[ca_cnt].a[0][idx] <== cache[2 * j - 2][0][idx];
		cache_adders[ca_cnt].a[1][idx] <== cache[2 * j - 2][1][idx];
		cache_adders[ca_cnt].b[0][idx] <== point[0][idx];
		cache_adders[ca_cnt].b[1][idx] <== point[1][idx];
	    }
	    for (var idx = 0; idx < k; idx++) {
		cache[2 * j + 1 - 2][0][idx] <== cache_adders[ca_cnt].out[0][idx];
		cache[2 * j + 1 - 2][1][idx] <== cache_adders[ca_cnt].out[1][idx];
	    }
	    
	    cd_cnt = cd_cnt + 1;
	    ca_cnt = ca_cnt + 1;
	}
    }

    component n2b[k];
    for (var i = 0; i < k; i++) {
        n2b[i] = Num2Bits(n);
        n2b[i].in <== scalar[i];
    }
    
    // selector[i] contains a value in [0, ..., 2**stride - 1]
    component selectors[num_strides];
    for (var i = 0; i < num_strides; i++) {
        selectors[i] = Bits2Num(stride);
        for (var j = 0; j < stride; j++) {
            var bit_idx1 = (i * stride + j) \ n;
            var bit_idx2 = (i * stride + j) % n;
            if (bit_idx1 < k) {
                selectors[i].in[j] <== n2b[bit_idx1].out[bit_idx2];
            } else {
                selectors[i].in[j] <== 0;
            }
        }
    }

    // select from 2 concatenated k-register outputs using a 2 ** stride bit selector
    component multiplexers[num_strides];
    for (var i = 0; i < num_strides; i++) {
	multiplexers[i] = Multiplexer(2 * k, (1 << stride));
        multiplexers[i].sel <== selectors[i].out;
        for (var l = 0; l < 2; l++) {
            for (var idx = 0; idx < k; idx++) {
                multiplexers[i].inp[0][l * k + idx] <== point[l][idx];
		multiplexers[i].inp[1][l * k + idx] <== point[l][idx];
                for (var j = 2; j < (1 << stride); j++) {
                    multiplexers[i].inp[j][l * k + idx] <== cache[j - 2][l][idx];
                }
            }
        }
    }

    component is_zero[num_strides];
    for (var i = 0; i < num_strides; i++) {
        is_zero[i] = IsZero();
        is_zero[i].in <== selectors[i].out;
    }

    // has_prev_nonzero[i] = 1 if at least one of the selections in privkey in strides i+1, i+2, .. is non-zero
    component has_prev_nonzero[num_strides - 1];
    for (var i = num_strides - 2; i >= 0; i--) {
        has_prev_nonzero[i] = OR();
	if (i == num_strides - 2) {
            has_prev_nonzero[i].a <== 0;
	} else {
	    has_prev_nonzero[i].a <== has_prev_nonzero[i + 1].out;
	}
        has_prev_nonzero[i].b <== 1 - is_zero[i + 1].out;
    }
        
    signal partial[num_strides][2][k];
    signal intermed[num_strides - 1][2][k];
    component adders[num_strides - 1];
    component doublers[(num_strides - 1) * stride];
    for (var i = num_strides - 1; i >= 0; i--) {
	if (i == num_strides - 1) {
	    for (var idx = 0; idx < k; idx++) {
		partial[i][0][idx] <== multiplexers[i].out[idx];
		partial[i][1][idx] <== multiplexers[i].out[k + idx];
	    }
	} else {
	    for (var j = 0; j < stride; j++) {
		doublers[i * stride + j] = Secp256k1Double(n, k);
		if (j == 0) {
		    for (var idx = 0; idx < k; idx++) {
			doublers[i * stride].in[0][idx] <== partial[i + 1][0][idx];
			doublers[i * stride].in[1][idx] <== partial[i + 1][1][idx];
		    }
		} else {
		    for (var idx = 0; idx < k; idx++) {
			doublers[i * stride + j].in[0][idx] <== doublers[i * stride + j - 1].out[0][idx];
			doublers[i * stride + j].in[1][idx] <== doublers[i * stride + j - 1].out[1][idx];
		    }
		}
	    }

	    adders[i] = Secp256k1AddUnequal(n, k);	    
	    for (var idx = 0; idx < k; idx++) {
		adders[i].a[0][idx] <== doublers[i * stride + stride - 1].out[0][idx];
		adders[i].a[1][idx] <== doublers[i * stride + stride - 1].out[1][idx];
		adders[i].b[0][idx] <== multiplexers[i].out[idx];
		adders[i].b[1][idx] <== multiplexers[i].out[k + idx];
	    }

	    // partial[i] = has_prev_nonzero[i] * (is_zero[i] * doublers[i * stride + stride - 1] + (1 - is_zero[i]) * adders[i])
            //              + (1 - has_prev_nonzero[i]) * multiplexers[i]
	    for (var idx = 0; idx < k; idx++) {
		intermed[i][0][idx] <== is_zero[i].out * (doublers[i * stride + stride - 1].out[0][idx] - adders[i].out[0][idx]) + adders[i].out[0][idx];
		intermed[i][1][idx] <== is_zero[i].out * (doublers[i * stride + stride - 1].out[1][idx] - adders[i].out[1][idx]) + adders[i].out[1][idx];
		partial[i][0][idx] <== has_prev_nonzero[i].out * (intermed[i][0][idx] - multiplexers[i].out[idx]) + multiplexers[i].out[idx];
		partial[i][1][idx] <== has_prev_nonzero[i].out * (intermed[i][1][idx] - multiplexers[i].out[k + idx]) + multiplexers[i].out[k + idx];
	    }
	}
    }

    for (var idx = 0; idx < k; idx++) {
        out[0][idx] <== partial[0][0][idx];
        out[1][idx] <== partial[0][1][idx];
    }
}


// Implements:
// out = (y^2 == x^3 + 7 (mod p))
template Secp256k1PointOnCurve(n, k) {
    signal input x[k];
    signal input y[k];
    signal output out;

    var p[100] = get_secp256k1_prime(n, k);

    // compute y^2 = y * y
    component muly2 = BigMultModP(n, k);
    for (var i = 0; i < k; i++) {
        muly2.a[i] <== y[i];
        muly2.b[i] <== y[i];
        muly2.p[i] <== p[i];
    }

    // compute x^2 = x * x
    component mulx2 = BigMultModP(n, k);
    for (var i = 0; i < k; i++) {
        mulx2.a[i] <== x[i];
        mulx2.b[i] <== x[i];
        mulx2.p[i] <== p[i];
    }

    // compute x^3 = x^2 * x
    component mulx3 = BigMultModP(n, k);
    for (var i = 0; i < k; i++) {
        mulx3.a[i] <== mulx2.out[i];
        mulx3.b[i] <== x[i];
        mulx3.p[i] <== p[i];
    }

    // compute diff = y^2 - x^3
    component diff = BigSubModP(n, k);
    for (var i = 0; i < k; i++) {
        diff.a[i] <== muly2.out[i];
        diff.b[i] <== mulx3.out[i];
        diff.p[i] <== p[i];
    }

    // check diff == 7
    component compare[k];
    signal num_equal[k - 1];
    for (var i = 0; i < k; i++) {
        compare[i] = IsEqual();
        if (i == 0) {
            compare[i].in[0] <== 7;
        }
        else {
            compare[i].in[0] <== 0;
        }
        compare[i].in[1] <== diff.out[i];

        if (i == 1) {
            num_equal[i - 1] <== compare[0].out + compare[1].out;
        }
        else if (i > 1) {
            num_equal[i - 1] <== num_equal[i - 2] + compare[i].out;
        }
    }
    component compare_total = IsEqual();
    compare_total.in[0] <== k;
    compare_total.in[1] <== num_equal[k - 2];

    out <== compare_total.out;
}

