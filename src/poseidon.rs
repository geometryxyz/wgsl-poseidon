use rand::Rng;
use ark_bn254::Fr;
use stopwatch::Stopwatch;
use num_bigint::BigUint;
use std::str::FromStr;
use crate::bn254::get_fr;
use crate::gpu::single_buffer_compute;
use crate::wgsl::concat_files;
use crate::utils::{ bigints_to_bytes, u32s_to_bigints };
use poseidon_ark::{ Poseidon, load_constants };

pub fn fr_vec_to_biguint_vec(vals: &Vec<Fr>) -> Vec<BigUint> {
    vals.iter().map(|v| (*v).into()).collect()
}

#[test]
pub fn poseidon() {
    // The BN254 scalar field modulus
    let p = get_fr();

    let b0: Fr = Fr::from_str("0").unwrap();
    let b1: Fr = Fr::from_str("1").unwrap();
    let inputs = vec![b1.clone()];
    let t = inputs.len() + 1;
    let n_rounds_f = 8;
    let n_rounds_p = 56;
    let mut state = vec![b0.clone(), b1.clone()];

    let poseidon = Poseidon::new();
    let constants = load_constants();
    //let c: BigUint = constants.c[t - 2][0].into();
    let c = fr_vec_to_biguint_vec(&constants.c[t - 2]);
    println!("constants.c: {:?}", c);
    println!("state before: {:?}", fr_vec_to_biguint_vec(&state));
    let i = 0;
    poseidon.ark(&mut state, &constants.c[t - 2], i * t);
    println!("state after: {:?}", fr_vec_to_biguint_vec(&state));

    /*
    let num_inputs = 256;
    let mut inputs = Vec::with_capacity(num_inputs);
    let mut expected = Vec::with_capacity(num_inputs);

    for _ in 0..num_inputs {
        // Generate a random field element
        let mut rng = rand::thread_rng();
        let random_bytes = rng.gen::<[u8; 32]>();
        let a = BigUint::from_bytes_be(random_bytes.as_slice()) % &p;

        inputs.push(a);
    }

    let sw = Stopwatch::start_new();
    for i in 0..num_inputs {
        let a = inputs[i].clone();
        let a_pow_5 = a.pow(5) % &p;
        expected.push(a_pow_5);
    }
    println!("CPU took {}ms", sw.elapsed_ms());

    let input_to_gpu = bigints_to_bytes(inputs);

    // Send to the GPU
    let wgsl = concat_files(vec!["src/structs.wgsl", "src/storage.wgsl", "src/bigint.wgsl", "src/fr.wgsl", "src/pow_5.wgsl"]);

    let sw = Stopwatch::start_new();
    let result = pollster::block_on(single_buffer_compute(&wgsl, &input_to_gpu, num_inputs)).unwrap();
    println!("GPU took {}ms", sw.elapsed_ms());

    let result = u32s_to_bigints(result);

    for i in 0..num_inputs {
        assert_eq!(result[i], expected[i]);
    }
    */
}
