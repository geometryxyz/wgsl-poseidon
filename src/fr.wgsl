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

fn fr_get_mu() -> BigInt256 {
    var p: BigInt256;
    p.limbs[0] = 59685u;
    p.limbs[1] = 48669u;
    p.limbs[2] = 934u;
    p.limbs[3] = 25095u;
    p.limbs[4] = 32942u;
    p.limbs[5] = 2536u;
    p.limbs[6] = 34080u;
    p.limbs[7] = 28996u;
    p.limbs[8] = 12308u;
    p.limbs[9] = 26631u;
    p.limbs[10] = 19032u;
    p.limbs[11] = 43783u;
    p.limbs[12] = 1191u;
    p.limbs[13] = 25146u;
    p.limbs[14] = 29794u;
    p.limbs[15] = 21668u;

    return p;
}

fn fr_get_p_wide() -> BigInt512 {
    var p: BigInt512;
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
    p.limbs[16] = 0u;
    p.limbs[17] = 0u;
    p.limbs[18] = 0u;
    p.limbs[19] = 0u;
    p.limbs[20] = 0u;
    p.limbs[21] = 0u;
    p.limbs[22] = 0u;
    p.limbs[23] = 0u;
    p.limbs[24] = 0u;
    p.limbs[25] = 0u;
    p.limbs[26] = 0u;
    p.limbs[27] = 0u;
    p.limbs[28] = 0u;
    p.limbs[29] = 0u;
    p.limbs[30] = 0u;
    p.limbs[31] = 0u;
    return p;
}

fn get_higher_with_slack(a: ptr<function, BigInt512>) -> BigInt256 {
    var out: BigInt256;
    var slack = 2u; // 256 minus the bitwidth of the Fr modulus
    var W = 16u;
    var W_mask = 65535u;
    for (var i = 0u; i < 16u; i ++) {
        /*
          This loop operates on the most significant bits of the bigint.
          It discards the least significant bits.
        */ 
        //                       mul by 2 ** 1         divide by 2 ** 15
        out.limbs[i] = (((*a).limbs[i + 16u] << slack) + ((*a).limbs[i + 15u] >> (W - slack))) & W_mask;
    }
    return out;
}


fn fr_mul(a: ptr<function, BigInt256>, b: ptr<function, BigInt256>) -> BigInt256 {
    var N = 16u;
    var mu = fr_get_mu();
    var p = fr_get_p();
    var p_wide = fr_get_p_wide();

    var xy: BigInt512 = bigint_mul(a, b);
    var xy_hi: BigInt256 = get_higher_with_slack(&xy);
    var l: BigInt512 = bigint_mul(&xy_hi, &mu);
    var l_hi: BigInt256 = get_higher_with_slack(&l);
    var lp: BigInt512 = bigint_mul(&l_hi, &p);
    var r_wide: BigInt512;
    bigint_512_sub(&xy, &lp, &r_wide);

    var r_wide_reduced: BigInt512;
    var underflow = bigint_512_sub(&r_wide, &p_wide, &r_wide_reduced);
    if (underflow == 0u) {
        r_wide = r_wide_reduced;
    }
    var r: BigInt256;
    for (var i = 0u; i < N; i ++) {
        r.limbs[i] = r_wide.limbs[i];
    }
    return fr_reduce(&r);
}

fn fr_sqr(a: ptr<function, BigInt256>) -> BigInt256 {
    return fr_mul(a, a);
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
