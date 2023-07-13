use std::fs;
use ark_bn254::Fr;
use num_bigint::BigUint;
use crate::utils::bigint_to_limbs;

pub fn append_from_file(code: String, filepath: &str) -> String {
    let contents: String = fs::read_to_string(filepath).unwrap().parse().unwrap();
    String::from(code) + &String::from("\n") + &String::from(contents)
}

pub fn gen_c_definitions(constants_c_to_use: Vec<Fr>) -> String {
    let mut c_definitions = String::new();
    for (i, c) in constants_c_to_use.iter().enumerate() {
        let mut block: String = format!("    var c_{}: BigInt256;\n", i);
        let c_biguint: BigUint = (*c).into();
        let limbs = bigint_to_limbs(&c_biguint);
        for (j, limb) in limbs.iter().enumerate() {
            let i_str = i.to_string();
            let j_str = j.to_string();
            let limb_str = limb.to_string();
            block += format!("    c_{}.limbs[{}] = {}u;\n", i_str.clone(), j_str.clone(), limb_str.clone()).as_str();
        }
        c_definitions += String::from(block).as_str();
        c_definitions += "\n";
    }
    c_definitions
}

