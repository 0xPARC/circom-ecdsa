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
    assert(n == 86 && k == 3);
    var ret[100];
    if (n == 86 && k == 3) {
        ret[0] = 10428087374290690730508609;
        ret[1] = 77371252455330678278691517;
        ret[2] = 19342813113834066795298815;
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

    var lambda[100];
    var sub0inv[100] = mod_inv(n, k, sub0_out, p);
    var sub1_sub0inv[100] = prod(n, k, sub1_out, sub0inv);
    var lamb_arr[2][100] = long_div(n, k, sub1_sub0inv, p);
    for (var i = 0; i < k; i++) {
        lambda[i] = lamb_arr[1][i];
    }

    var lambdasq_out[100] = prod_mod_p(n, k, lambda, lambda, p);

    var out0_pre_out[100] = long_sub_mod_p(n, k, lambdasq_out, a[0], p);

    var out0_out[100] = long_sub_mod_p(n, k, out0_pre_out, b[0], p);

    for (var i = 0; i < k; i++) {
        out[0][i] = out0_out[i];
    }

    var out1_0_out[100] = long_sub_mod_p(n, k, a[0], out[0], p);

    var out1_1_out[100] = prod_mod_p(n, k, lambda, out1_0_out, p);

    var out1_out[100] = long_sub_mod_p(n, k, out1_1_out, a[1], p);

    for (var i = 0; i < k; i++) {
        out[1][i] = out1_out[i];
    }
    return out;
}
