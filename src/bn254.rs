use num_bigint::BigUint;

pub fn get_fr() -> BigUint {
    BigUint::parse_bytes(b"30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001", 16).unwrap()
}
