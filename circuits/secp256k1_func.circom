pragma circom 2.0.2;

// from https://github.com/ethereum/py_ecc/blob/master/py_ecc/secp256k1/secp256k1.py
function get_gx(n, k) {
    assert(n == 86 && k == 3);
    var ret[100];
    if (n == 86 && k == 3) {
        ret[0] = 17117865558768631194064792;
        ret[1] = 12501176021340589225372855;
        ret[2] = 9198697782662356105779718;
    }
    return ret;
}

function get_gy(n, k) {
    assert(n == 86 && k == 3);
    var ret[100];
    if (n == 86 && k == 3) {
        ret[0] = 6441780312434748884571320;
        ret[1] = 57953919405111227542741658;
        ret[2] = 5457536640262350763842127;
    }
    return ret;
}

function get_secp256k1_prime(n, k) {
     assert((n == 86 && k == 3) || (n == 64 && k == 4));
     var ret[100];
     if (n == 86 && k == 3) {
         ret[0] = 77371252455336262886226991;
         ret[1] = 77371252455336267181195263;
         ret[2] = 19342813113834066795298815;
     }
     if (n == 64 && k == 4) {
         ret[0] = 18446744069414583343;
         ret[1] = 18446744073709551615;
         ret[2] = 18446744073709551615;
         ret[3] = 18446744073709551615;
     }
     return ret;
}

function get_secp256k1_order(n, k) {
    assert((n == 86 && k == 3) || (n == 64 && k == 4));
    var ret[100];
    if (n == 86 && k == 3) {
        ret[0] = 10428087374290690730508609;
        ret[1] = 77371252455330678278691517;
        ret[2] = 19342813113834066795298815;
    }
    if (n == 64 && k == 4) {
        ret[0] = 13822214165235122497;
        ret[1] = 13451932020343611451;
        ret[2] = 18446744073709551614;
        ret[3] = 18446744073709551615;
    }
    return ret;
}

// returns G * 2 ** 255
// TODO check that this is correct...
function get_dummy_point(n, k) {
    assert(n == 86 && k == 3 || n == 64 && k == 4);
    var ret[2][100]; // should be [2][k]
    if (k == 3) {
        ret[0][0] = 34318960048412842733519232;
        ret[0][1] = 3417427387252098100392906;
        ret[0][2] = 2056756886390887154635856;
        ret[1][0] = 35848273954982567597050105;
        ret[1][1] = 74802087901123421621824957;
        ret[1][2] = 4851915413831746153124691;
    } else {
        ret[0][0] = 10184385086782357888;
        ret[0][1] = 16068507144229249874;
        ret[0][2] = 17097072337414981695;
        ret[0][3] = 1961476217642676500;
        ret[1][0] = 15220267994978715897;
        ret[1][1] = 2812694141792528170;
        ret[1][2] = 9886878341545582154;
        ret[1][3] = 4627147115546938088;
    }
    return ret;
}

// a[0], a[1] = x1, y1
// b[0], b[1] = x2, y2
// lamb = (b[1] - a[1]) / (b[0] - a[0]) % p
// out[0] = lamb ** 2 - a[0] - b[0] % p
// out[1] = lamb * (a[0] - out[0]) - a[1] % p
function secp256k1_addunequal_func(n, k, x1, y1, x2, y2){
    var a[2][100];
    var b[2][100];

    for(var i = 0; i < k; i++){
        a[0][i] = x1[i];
        a[1][i] = y1[i];
        b[0][i] = x2[i];
        b[1][i] = y2[i];
    }

    var out[2][100];

    var p[100] = get_secp256k1_prime(n, k);

    // b[1] - a[1]
    var sub1_out[100] = long_sub_mod_p(n, k, b[1], a[1], p);

    // b[0] - a[0]
    var sub0_out[100]= long_sub_mod_p(n, k, b[0], a[0], p);

    // lambda = (b[1] - a[1]) * inv(b[0] - a[0])
    var sub0inv[100] = mod_inv(n, k, sub0_out, p);
    var lambda[100] = prod_mod_p(n, k, sub1_out, sub0inv, p);

    // out[0] = lambda ** 2 - a[0] - b[0]
    var lambdasq_out[100] = prod_mod_p(n, k, lambda, lambda, p);
    var out0_pre_out[100] = long_sub_mod_p(n, k, lambdasq_out, a[0], p);
    var out0_out[100] = long_sub_mod_p(n, k, out0_pre_out, b[0], p);
    for (var i = 0; i < k; i++) {
        out[0][i] = out0_out[i];
    }

    // out[1] = lambda * (a[0] - out[0]) - a[1]
    var out1_0_out[100] = long_sub_mod_p(n, k, a[0], out[0], p);
    var out1_1_out[100] = prod_mod_p(n, k, lambda, out1_0_out, p);
    var out1_out[100] = long_sub_mod_p(n, k, out1_1_out, a[1], p);
    for (var i = 0; i < k; i++) {
        out[1][i] = out1_out[i];
    }

    return out;
}

// a[0], a[1] = x1, y1
// lamb = (3 * a[0] ** 2) / (2 * a[1]) % p
// out[0] = lamb ** 2 - (2 * a[0]) % p
// out[1] = lamb * (a[0] - out[0]) - a[1] % p
function secp256k1_double_func(n, k, x1, y1){
    var a[2][100];
    var b[2][100];

    for(var i = 0; i < k; i++){
        a[0][i] = x1[i];
        a[1][i] = y1[i];
    }

    var out[2][100];

    var p[100] = get_secp256k1_prime(n, k);

    // lamb_numer = 3 * a[0] ** 2
    var x1_sq[100] = prod_mod_p(n, k, a[0], a[0], p);
    var three[100];
    for (var i = 0; i < 100; i++) three[i] = i == 0 ? 3 : 0;
    var lamb_numer[100] = prod_mod_p(n, k, x1_sq, three, p);

    // lamb_denom = 2 * a[1]
    var two[100];
    for (var i = 0; i < 100; i++) two[i] = i == 0 ? 2 : 0;
    var lamb_denom[100] = prod_mod_p(n, k, a[1], two, p);

    // lambda = lamb_numer * inv(lamb_denom)
    var lamb_denom_inv[100] = mod_inv(n, k, lamb_denom, p);
    var lambda[100] = prod_mod_p(n, k, lamb_numer, lamb_denom_inv, p);

    // out[0] = lambda ** 2 - 2 * a[0]
    var lambdasq_out[100] = prod_mod_p(n, k, lambda, lambda, p);
    var out0_pre_out[100] = long_sub_mod_p(n, k, lambdasq_out, a[0], p);
    var out0_out[100] = long_sub_mod_p(n, k, out0_pre_out, a[0], p);
    for (var i = 0; i < k; i++) {
        out[0][i] = out0_out[i];
    }

    // out[1] = lambda * (a[0] - out[0]) - a[1]
    var out1_0_out[100] = long_sub_mod_p(n, k, a[0], out[0], p);
    var out1_1_out[100] = prod_mod_p(n, k, lambda, out1_0_out, p);
    var out1_out[100] = long_sub_mod_p(n, k, out1_1_out, a[1], p);
    for (var i = 0; i < k; i++) {
        out[1][i] = out1_out[i];
    }

    return out;
}
