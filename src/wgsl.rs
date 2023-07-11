pub fn concat_files(filenames: Vec<&str>) -> String {
    let mut result = String::new();

    for (i, filename) in filenames.iter().enumerate() {
        let contents = std::fs::read_to_string(filename).unwrap();
        result += &String::from(format!("//---- {}\n\n", filename));
        result += &String::from(contents);
        if i < filenames.len() - 1 {
            result += "\n";
        }
    }
    String::from(result)
}

pub fn validate(input: &str) -> Result<(), naga::front::wgsl::ParseError> {
    let result = naga::front::wgsl::parse_str(&input);
    if result.is_err() {
        let e = result.err().unwrap();
        e.emit_to_stderr_with_path(&input, "");
        return Err(e);
    }
    Ok(())
}

#[cfg(test)]
pub mod tests {
    use crate::wgsl::{concat_files, validate};

    #[test]
    pub fn test_concat_files() {
        let input = concat_files(vec!["src/structs.wgsl", "src/storage.wgsl", "src/bigint.wgsl", "src/fr.wgsl"]);
        assert!(validate(&input).is_ok());
    }
}
