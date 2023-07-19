//use ark_bn254::{G1Affine, G2Affine};
use ark_ff::{PrimeField, BigInteger};
use ark_bn254::Fr;
use ark_poly::{EvaluationDomain, GeneralEvaluationDomain};
//use ethers::types::U256;
use std::string::String;
use std::io::Write;

//pub fn u256_to_hex(val: U256) -> String {
    //let b: &mut [u8; 32] = &mut [0u8; 32];
    //val.to_big_endian(b);
    //hex::encode(&b).to_uppercase()
//}

//pub fn f_to_u256<F: PrimeField>(val: F) -> U256 {
    //let mut b = Vec::with_capacity(32);
    //let _ = val.write(&mut b);
    //let b_as_arr: [u8; 32] = b.try_into().unwrap();
    //U256::from_little_endian(&b_as_arr)
//}

pub fn f_to_hex<F: PrimeField>(val: F) -> String {
    hex::encode(val.into_bigint().to_bytes_be())
}

#[test]
pub fn test_fft() {
    // Fr is the BN254 scalar field
    let mut v = vec![Fr::from(1), Fr::from(2)];
    let domain = GeneralEvaluationDomain::<Fr>::new(v.len()).unwrap();
    domain.fft_in_place(&mut v);
    println!("{:?}", f_to_hex(v[0]));
    println!("{:?}", f_to_hex(v[1]));
}
