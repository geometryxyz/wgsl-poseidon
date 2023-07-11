fn get_constant(index: u32) -> BigInt256 {
    var p: BigInt256;
    p.limbs[0] = 1u; p.limbs[1] = 61440u; p.limbs[2] = 62867u; p.limbs[3] = 17377u; p.limbs[4] = 28817u; p.limbs[5] = 31161u; p.limbs[6] = 59464u; p.limbs[7] = 10291u; p.limbs[8] = 22621u; p.limbs[9] = 33153u; p.limbs[10] = 17846u; p.limbs[11] = 47184u; p.limbs[12] = 41001u; p.limbs[13] = 57649u; p.limbs[14] = 20082u; p.limbs[15] = 12388u;
    var constants = array(p, p);
    return constants[index];
}

@compute
@workgroup_size(1)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    var a: BigInt256 = buf[global_id.x];
    buf[global_id.x] = get_constant(1u);
}
