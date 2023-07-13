// This code is adapted from https://github.com/sampritipanda/msm-webgpu/blob/main/bigint.wgsl

fn pow_5(a: ptr<function, BigInt256>) -> BigInt256 {
    var a2: BigInt256 = fr_mul(a, a);
    var a4: BigInt256 = fr_mul(&a2, &a2);
    return fr_mul(&a4, a);
}

@compute
@workgroup_size(1)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    var a: BigInt256 = buf[global_id.x];
    buf[global_id.x] = pow_5(&a);
}
