use std::env;
use std::fs;
use poseidon_ark::load_constants;
use wgsl_poseidon::codegen::gen_c_definitions;

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() <= 2 {
        println!("Usage: cargo run gen_constants_wgsl <num_inputs> <wgsl_output_file>");
        println!(
            "Generates a WGSL file containing the round constants for a given number of inputs."
        );
        return;
    }
    assert!(args.len() > 3);
    let num_inputs = &args[args.len() - 2];
    let num_inputs: usize = num_inputs.parse().unwrap();

    let wgsl_output_file = &args[args.len() - 1];

    let constants = load_constants();

    let n_rounds_f = 8;
    let n_rounds_p = vec![
        56, 57, 56, 60, 60, 63, 64, 63, 60, 66, 60, 65, 70, 60, 64, 68,
    ];
    let t = num_inputs + 1;

    let num_constants = (n_rounds_f + n_rounds_p[t - 2]) * 2;
    let mut constants_c_to_use = Vec::with_capacity(num_constants);

    for i in 0..num_constants {
        constants_c_to_use.push(constants.c[t - 2][i]);
    }

    let start = format!("fn get_t{}_constant_c(index: u32) -> BigInt256 {{", t);
    let end = "}";
    let c_definitions = gen_c_definitions(constants_c_to_use);
    println!("{}", c_definitions);

    let mut c_list = String::new();
    for i in 0..num_constants {
        c_list += format!("c_{}", i.to_string()).as_str();
        if i != num_constants - 1 {
            c_list += ", ";
        }
    }

    let arr_code = format!("    var constants = array({});\n    return constants[index];", c_list);

    let code = format!("{}\n{}\n{}\n{}", start, c_definitions, arr_code, end);
    fs::write(wgsl_output_file, code).expect("Error: unable to write to the output file.");
    //println!("{}", code);
}
