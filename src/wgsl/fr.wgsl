fn fr_get_p() -> BigInt256 {
    var p: BigInt256;
    p.limbs[0] = 1u;
    p.limbs[1] = 61440u;
    p.limbs[2] = 62867u;
    p.limbs[3] = 17377u;
    p.limbs[4] = 28817u;
    p.limbs[5] = 31161u;
    p.limbs[6] = 59464u;
    p.limbs[7] = 10291u;
    p.limbs[8] = 22621u;
    p.limbs[9] = 33153u;
    p.limbs[10] = 17846u;
    p.limbs[11] = 47184u;
    p.limbs[12] = 41001u;
    p.limbs[13] = 57649u;
    p.limbs[14] = 20082u;
    p.limbs[15] = 12388u;
    return p;
}

fn gen_p_medium_wide() -> BigInt272 {
    var p: BigInt272;
    p.limbs[0] = 1u;
    p.limbs[1] = 61440u;
    p.limbs[2] = 62867u;
    p.limbs[3] = 17377u;
    p.limbs[4] = 28817u;
    p.limbs[5] = 31161u;
    p.limbs[6] = 59464u;
    p.limbs[7] = 10291u;
    p.limbs[8] = 22621u;
    p.limbs[9] = 33153u;
    p.limbs[10] = 17846u;
    p.limbs[11] = 47184u;
    p.limbs[12] = 41001u;
    p.limbs[13] = 57649u;
    p.limbs[14] = 20082u;
    p.limbs[15] = 12388u;
    return p;
}

fn fr_add(a: ptr<function, BigInt256>, b: ptr<function, BigInt256>) -> BigInt256 { 
    var res: BigInt256;
    /*var res = bigint_add(a, b);*/
    bigint_add(a, b, &res);
    return fr_reduce(&res);
}

/*// once reduces once (assumes that 0 <= a < 2 * mod)*/
fn fr_reduce(a: ptr<function, BigInt256>) -> BigInt256 {
    var res: BigInt256;
    var p: BigInt256 = fr_get_p();
    var underflow = bigint_sub(a, &p, &res);
    if (underflow == 1u) {
        return *a;
    }

    return res;
}

fn hi(val: u32) -> u32 {
    return val >> 16u;
}

fn lo(val: u32) -> u32 {
    return val & 65535u;
}

fn cios_mon_pro(a: ptr<function, BigInt256>, b: ptr<function, BigInt256>) -> BigInt256 {
    var n = gen_p_medium_wide();
    var n0 = 65535u;
    var num_words = 16u;

    var t: array<u32, 18u>;
    var x: BigInt256;

    for (var i = 0u; i < num_words; i ++) {
        var c = 0u;
        for (var j = 0u; j < num_words; j ++) {
            var r = t[j] + (*a).limbs[j] * (*b).limbs[i] + c;
            c = hi(r);
            t[j] = lo(r);
        }
        var r = t[num_words] + c;
        t[num_words + 1u] = hi(r);
        t[num_words] = lo(r);

        var m = (t[0] * n0) % 65536u;
        r = t[0] + m * n.limbs[0];
        c = hi(r);

        for (var j = 1u; j < num_words; j ++) {
            r = t[j] + m * n.limbs[j] + c;
            c = hi(r);
            t[j - 1u] = lo(r);
        }

        r = t[num_words] + c;
        c = hi(r);
        t[num_words - 1u] = lo(r);
        t[num_words] = t[num_words + 1u] + c;
    }

    // Check if t < n. If so, return t. Else, return n - t.
    var t_lt_n = false;
    for (var idx = 0u; idx < num_words + 1u; idx ++) {
        var i = num_words - 1u - idx;
        if (t[i] < n.limbs[i]) {
            t_lt_n = true;
            break;
        } else if (t[i] > n.limbs[i]) {
            break;
        }
    }

    var r: BigInt256;
    if (t_lt_n) {
        for (var i = 0u; i < num_words; i ++) {
            r.limbs[i] = t[i];
        }
        return r;
    } else {
        var borrow = 0u;
        var t_minus_n: BigInt272;
        for (var i = 0u; i < num_words; i ++) {
            t_minus_n.limbs[i] = t[i] - n.limbs[i] - borrow;
            if (t[i] < (n.limbs[i] + borrow)) {
                t_minus_n.limbs[i] = t_minus_n.limbs[i] + 65536u;
                borrow = 1u;
            } else {
                borrow = 0u;
            }
            x.limbs[i] = t_minus_n.limbs[i];
        }
        return x;
    }
}
