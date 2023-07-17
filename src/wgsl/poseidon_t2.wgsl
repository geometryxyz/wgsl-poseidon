@compute
@workgroup_size(64)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    var a: BigInt256 = buf[global_id.x];
    var state_0: BigInt256;
    var state_1 = a;

    /*var n_rounds_f = 8u;*/
    /*var n_rounds_p = 56u;*/

    var m_0_0 = constants[global_id.y + 128u];
    var m_0_1 = constants[global_id.y + 129u];
    var m_1_0 = constants[global_id.y + 130u];
    var m_1_1 = constants[global_id.y + 131u];

    // for t == 2, n_rounds_f + n_rounds_p = 64
    for (var i = 0u; i < 64u; i ++) {
        // Add round constants (also known as "arc" or "ark")
        var c_0 = constants[global_id.y + i * 2u];
        var c_1 = constants[global_id.y + i * 2u + 1u];
        state_0 = fr_add(&state_0, &c_0);
        state_1 = fr_add(&state_1, &c_1);

        // S-Box
        var s0 = state_0;
        state_0 = fr_mul(&state_0, &state_0);
        state_0 = fr_mul(&state_0, &state_0);
        state_0 = fr_mul(&s0, &state_0);

        if (i < 4u || i >= 60u) {
            var s1 = state_1;
            state_1 = fr_mul(&state_1, &state_1);
            state_1 = fr_mul(&state_1, &state_1);
            state_1 = fr_mul(&s1, &state_1);
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
