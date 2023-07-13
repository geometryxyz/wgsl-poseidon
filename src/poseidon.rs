use rand::Rng;
use ark_bn254::Fr;
use stopwatch::Stopwatch;
use num_bigint::BigUint;
use std::str::FromStr;
use crate::bn254::get_fr;
use crate::gpu::single_buffer_compute;
use crate::wgsl::concat_files;
use crate::utils::{ bigints_to_bytes, u32s_to_bigints };
use crate::codegen::{ append_from_file, gen_c_definitions };
use poseidon_ark::{ Poseidon, load_constants };

pub fn n_rounds(t: usize) -> (usize, usize) {
    let n_rounds_f: usize = 8;
    let n_rounds_p: Vec<usize> = vec![
        56, 57, 56, 60, 60, 63, 64, 63, 60, 66, 60, 65, 70, 60, 64, 68,
    ];

    (n_rounds_f, n_rounds_p[t - 2])
}

pub fn load_constants_c(num_inputs: usize) -> Vec<Fr> {
    let (n_rounds_f, n_rounds_p) = n_rounds(num_inputs + 1);
    let t = num_inputs + 1;
    let num_constants = (n_rounds_f + n_rounds_p) * 2;
    let mut constants_c_to_use = Vec::with_capacity(num_constants);

    let constants = load_constants();

    for i in 0..num_constants {
        constants_c_to_use.push(constants.c[t - 2][i]);
    }
    constants_c_to_use
}

pub fn fr_vec_to_biguint_vec(vals: &Vec<Fr>) -> Vec<BigUint> {
    vals.iter().map(|v| (*v).into()).collect()
}

#[test]
pub fn test_poseidon() {
    // The BN254 scalar field modulus
    let p = get_fr();

    let b0: Fr = Fr::from_str("0").unwrap();

    //let mut rng = rand::thread_rng();
    //let random_bytes = rng.gen::<[u8; 32]>();
    //let a = BigUint::from_bytes_be(random_bytes.as_slice()) % &p;
    let a = BigUint::from_slice(&[1]);

    // Number of inputs: 1
    // t = 1 + 1 = 2

    let mut inputs: Vec<BigUint> = vec![a.clone().into()];
    let t = inputs.len() + 1;
    let _n_rounds_f = 8;
    let _n_rounds_p = 56;
    let state = vec![b0.clone(), a.clone().into()];
    //let mut state = vec![b0.clone(), a.clone().into()];

    let poseidon = Poseidon::new();
    let constants = load_constants();

    // Append the C constants
    for val in fr_vec_to_biguint_vec(&constants.c[t - 2]) {
        inputs.push(val);
    }

    // Append the M constants
    for vec in &constants.m[t - 2] {
        for val in fr_vec_to_biguint_vec(&vec) {
            inputs.push(val.clone());
        }
    }

    let expected_hash: BigUint = poseidon.hash(vec![a.clone().into()]).unwrap().into();

    // For debugging:
    //for i in 0..(n_rounds_f + n_rounds_p) {
        //poseidon.ark(&mut state, &constants.c[t - 2], i * t);
        //poseidon.sbox(n_rounds_f, n_rounds_p, &mut state, i);
        //state = poseidon.mix(&state, &constants.m[t - 2]);
    //}
    //let expected_final_state = fr_vec_to_biguint_vec(&state);
    //println!("expected final state: {:?}", expected_final_state);

    //let input_to_gpu = bigints_to_bytes(fr_vec_to_biguint_vec(&inputs));
    let input_to_gpu = bigints_to_bytes(inputs);

    // Passing the constants as hardcoded WGSL code is to inefficient
    //let wgsl = gen_poseidon_t2_wgsl();
    let wgsl = concat_files(
        vec![
            "src/wgsl/structs.wgsl",
            "src/wgsl/storage.wgsl",
            "src/wgsl/bigint.wgsl",
            "src/wgsl/fr.wgsl",
            "src/wgsl/poseidon_t2.wgsl"
        ]
    );

    //println!("{}", wgsl);

    // Send to the GPU
    let sw = Stopwatch::start_new();
    let result = pollster::block_on(single_buffer_compute(&wgsl, &input_to_gpu, 1)).unwrap();
    println!("GPU took {}ms", sw.elapsed_ms());

    let result = u32s_to_bigints(result);
    println!("Input: {:?}", a.clone());
    println!("Result from GPU: {:?}", result[0]);
    //assert_eq!(result[0], expected_final_state[0]);
    assert_eq!(result[0], expected_hash);

}
