static STRING: &'static str = "ä#aüsfäö#asöä#¼³½¬³2";

pub fn compare_string(s: &str) -> bool {
    s == STRING
}

pub fn compare_mut_string(s: &mut str) -> bool {
    s == STRING
}

pub fn return_string() -> String {
    STRING.into()
}

pub fn pass_string_through(s: &str) -> String { s.into() }
