/*
@group(0)
@binding(0)
var<storage, read_write> buf: array<u32>;

@compute
@workgroup_size(1)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    buf[global_id.x] = buf[global_id.x] + 1u;
}
*/
//---- src/wgsl/structs.wgsl

struct BigInt256 {
    limbs: array<u32, 16>
}

struct BigInt512 {
    limbs: array<u32, 32>
}

//---- src/wgsl/storage.wgsl

@group(0)
@binding(0)
var<storage, read_write> buf: array<BigInt256>;

//---- src/wgsl/bigint.wgsl

fn bigint_add(a: ptr<function, BigInt256>, b: ptr<function, BigInt256>, res: ptr<function, BigInt256>) -> u32 {
    var carry: u32 = 0u;
    for (var j: u32 = 0u; j < 16u; j ++) {
        let c: u32 = (*a).limbs[j] + (*b).limbs[j] + carry;
        (*res).limbs[j] = c & 65535u;
        carry = c >> 16u;
    }
    return carry;
}

fn bigint_mul(a: ptr<function, BigInt256>, b: ptr<function, BigInt256>) -> BigInt512 {
    var N = 16u;
    var W = 16u;
    var W_mask = 65535u;
    var res: BigInt512;
    for (var i = 0u; i < N; i = i + 1u) {
        for (var j = 0u; j < N; j = j + 1u) {
            let c = (*a).limbs[i] * (*b).limbs[j];
            res.limbs[i+j] += c & W_mask;
            res.limbs[i+j+1u] += c >> W;
        }   
    }
    // start from 0 and carry the extra over to the next index
    for (var i = 0u; i < 2u*N - 1u; i = i + 1u) {
        res.limbs[i+1u] += res.limbs[i] >> W;
        res.limbs[i] = res.limbs[i] & W_mask;
    }
    return res;
}

fn bigint_sub(a: ptr<function, BigInt256>, b: ptr<function, BigInt256>, res: ptr<function, BigInt256>) -> u32 {
    var borrow: u32 = 0u;
    for (var i: u32 = 0u; i < 16u; i = i + 1u) {
        (*res).limbs[i] = (*a).limbs[i] - (*b).limbs[i] - borrow;
        if ((*a).limbs[i] < ((*b).limbs[i] + borrow)) {
            (*res).limbs[i] += 65536u;
            borrow = 1u;
        } else {
            borrow = 0u;
        }
    }
    return borrow;
}

// assumes a >= b
fn bigint_512_sub(a: ptr<function, BigInt512>, b: ptr<function, BigInt512>, res: ptr<function, BigInt512>) -> u32 {
    var W_mask = 65535u;
    var N = 16u;

    var borrow: u32 = 0u;
    for (var i: u32 = 0u; i < (2u*N); i = i + 1u) {
        (*res).limbs[i] = (*a).limbs[i] - (*b).limbs[i] - borrow;
        if ((*a).limbs[i] < ((*b).limbs[i] + borrow)) {
            (*res).limbs[i] += W_mask + 1u;
            borrow = 1u;
        } else {
            borrow = 0u;
        }
    }
    return borrow;
}

//---- src/wgsl/fr.wgsl

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
    /*var slack = 2u; // 256 minus the bitwidth of the Fr modulus*/
    /*var W = 16u;*/
    /*var W_mask = 65535u;*/
    for (var i = 0u; i < 16u; i ++) {
        /*
          This loop operates on the most significant bits of the bigint.
          It discards the least significant bits.
        */ 
        //                       mul by 2 ** 1         divide by 2 ** 15
        /*out.limbs[i] = (((*a).limbs[i + 16u] << slack) + ((*a).limbs[i + 15u] >> (W - slack))) & W_mask;*/
        out.limbs[i] = (((*a).limbs[i + 16u] << 2u) + ((*a).limbs[i + 15u] >> 14u)) & 65535u;
    }
    return out;
}


fn fr_mul(a: ptr<function, BigInt256>, b: ptr<function, BigInt256>) -> BigInt256 {
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
    for (var i = 0u; i < 16u; i ++) {
        r.limbs[i] = r_wide.limbs[i];
    }
    return fr_reduce(&r);
}

fn fr_sqr(a: ptr<function, BigInt256>) -> BigInt256 {
    return fr_mul(a, a);
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

//---- src/wgsl/poseidon_t2.wgsl

fn pow_5(a: ptr<function, BigInt256>) -> BigInt256 {
    var a2: BigInt256 = fr_mul(a, a);
    var a4: BigInt256 = fr_mul(&a2, &a2);
    return fr_mul(&a4, a);
}

@compute
@workgroup_size(64)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    var a: BigInt256 = buf[global_id.x];
    var state_0: BigInt256;
    var state_1 = a;

    /*var n_rounds_f = 8u;*/
    /*var n_rounds_p = 56u;*/

    var m_0_0 = buf[global_id.x + 129u];
    var m_0_1 = buf[global_id.x + 129u + 1u];
    var m_1_0 = buf[global_id.x + 129u + 2u];
    var m_1_1 = buf[global_id.x + 129u + 3u];

    // for t == 2, n_rounds_f + n_rounds_p = 64
    for (var i = 0u; i < 64u; i ++) {
        // Add round constants (also known as "arc" or "ark")
        var c_0 = buf[global_id.x + 1u + i * 2u];
        var c_1 = buf[global_id.x + 1u + i * 2u + 1u];
        state_0 = fr_add(&state_0, &c_0);
        state_1 = fr_add(&state_1, &c_1);

        // S-Box
        if (i < 4u || i >= 60u) {
            state_0 = pow_5(&state_0);
            state_1 = pow_5(&state_1);
        } else {
            state_0 = pow_5(&state_0);
        }

        // Mix
        var m00s0 = fr_mul(&m_0_0, &state_0);
        var m01s1 = fr_mul(&m_0_1, &state_1);
        var m10s0 = fr_mul(&m_1_0, &state_0);
        var m11s1 = fr_mul(&m_1_1, &state_1);

        var new_state_0: BigInt256 = fr_add(&m00s0, &m01s1);
        var new_state_1: BigInt256 = fr_add(&m10s0, &m11s1);

        state_0 = new_state_0;
        state_1 = new_state_1;
    }

    buf[global_id.x] = state_0;
}
