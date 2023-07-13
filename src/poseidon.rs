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

pub fn gen_poseidon_t2_wgsl() -> String {
    let t = 2;
    let (n_rounds_f, n_rounds_p) = n_rounds(t);

    let mut code = concat_files(
        vec![
            "src/wgsl/structs.wgsl",
            "src/wgsl/storage.wgsl",
            "src/wgsl/bigint.wgsl",
            "src/wgsl/fr.wgsl",
        ]
    );

    code += "fn poseidon_t2(a: ptr<function, BigInt256>) -> BigInt256 {\n";
    code += gen_c_definitions(load_constants_c(t)).as_str();

    code +=         "    var state_0: BigInt256;\n";
    code +=         "    var state_1: BigInt256 = *a;\n";
    code += format!("    for (var i = 0u; i < {}u; i ++) {{\n", n_rounds_f + n_rounds_p).as_str();

    for i in 0..(n_rounds_f + n_rounds_p) {
        // ARC
        code += format!("        state_0 = fr_add(&state_0, &c_{});\n", i * t).as_str();
        code += format!("        state_1 = fr_add(&state_1, &c_{});\n", i * t + 1).as_str();
    }

    code +=         "    }\n";
    code +=         "    return state_0;\n";

    code += "}\n";

    code = append_from_file(code, "src/snippets/poseidon_t2_main.wgsl");
    code
}

#[test]
pub fn test_poseidon() {
    /*
    let num_inputs = 512;
    let mut inputs = Vec::with_capacity(512);
    
    // 0: preimage
    // 1 - 128: constants_c

    for i in 0..512 {
        inputs.push(BigUint::from_slice(&[i]));
    }

    let wgsl = concat_files(
        vec![
            "src/wgsl/structs.wgsl",
            "src/wgsl/storage.wgsl",
            "src/wgsl/bigint.wgsl",
            "src/wgsl/fr.wgsl",
            "src/wgsl/poseidon_t2.wgsl"
        ]
    );

    let input_to_gpu = bigints_to_bytes(inputs);

    let result = pollster::block_on(single_buffer_compute(&wgsl, &input_to_gpu, 1)).unwrap();
    let result = u32s_to_bigints(result);

    println!("{:?}", result);
    */

    // The BN254 scalar field modulus
    let p = get_fr();

    let b0: Fr = Fr::from_str("0").unwrap();
    let b1: Fr = Fr::from_str("1").unwrap();

    // Number of inputs: 1
    // t = 1 + 1 = 2

    let mut inputs: Vec<BigUint> = vec![b1.into()];
    let t = inputs.len() + 1;
    let n_rounds_f = 8;
    let n_rounds_p = 56;
    let mut state = vec![b0.clone(), b1.clone()];

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
            //println!("m: {:?}", val.clone());
        }
    }

    println!("initial state: {:?}", fr_vec_to_biguint_vec(&state));
    for i in 0..(n_rounds_f + n_rounds_p) {
        poseidon.ark(&mut state, &constants.c[t - 2], i * t);
        poseidon.sbox(n_rounds_f, n_rounds_p, &mut state, i);
        state = poseidon.mix(&state, &constants.m[t - 2]);
    }
    let expected_final_state = fr_vec_to_biguint_vec(&state);
    println!("expected final state: {:?}", expected_final_state);

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
    println!("result from GPU: {:?}", result[0]);
    assert_eq!(result[0], expected_final_state[0]);
    println!("Great!!");
    /*
    */

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
