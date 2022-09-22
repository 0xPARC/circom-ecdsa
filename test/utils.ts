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

export { bigint_to_array, bigint_to_tuple, get_strided_bigint }
