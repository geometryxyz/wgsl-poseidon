// This code is adapted from https://github.com/sampritipanda/msm-webgpu/blob/main/bigint.wgsl

fn pow_5(a: ptr<function, BigInt256>) -> BigInt256 {
    var a2: BigInt256 = fr_mul(a, a);
    var a4: BigInt256 = fr_mul(&a2, &a2);
    return fr_mul(&a4, a);
}

@compute
@workgroup_size(256)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    var a: BigInt256 = buf[global_id.x];
    var times_to_pow = 512u;
    for (var i = 0u; i < times_to_pow; i++) {
        a = pow_5(&a);
    }
    buf[global_id.x] = a;
}
