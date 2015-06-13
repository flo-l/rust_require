static STRING0: &'static str = "";
static STRING1: &'static str = "Hello, Ascii!";
static STRING2: &'static str = "ä#aüsfäö#asöä#¼³½¬³2";

pub fn compare_string(s: &str, n: u8) -> bool {
    match n {
        0 => s == STRING0,
        1 => s == STRING1,
        2 => s == STRING2,
        _ => unreachable!(),
    }
}

pub fn compare_mut_string(s: &mut str, n: u8) -> bool {
    compare_string(s,n)
}

pub fn return_string(n: u8) -> String {
    match n {
        0 => STRING0.into(),
        1 => STRING1.into(),
        2 => STRING2.into(),
        _ => unreachable!(),
    }
}

pub fn pass_string_through(s: &str) -> String { s.into() }
