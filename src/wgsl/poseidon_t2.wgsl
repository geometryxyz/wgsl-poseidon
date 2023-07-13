/*fn poseidon_t2(a: ptr<function, BigInt256>) -> BigInt256 {*/
    /*var t = 2u;*/
    /*var n_rounds_f = 8u;*/
    /*var n_rounds_p = 56u;*/
    /*var state_0: BigInt256;*/
    /*var state_1 = *a;*/
/*}*/

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
    var n_rounds_f = 8u;
    var n_rounds_p = 56u;

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
