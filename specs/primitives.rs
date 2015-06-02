//just functions taking primitives and returning them unmodified
macro_rules! test {
    ($i:ident, $t:ty) => (pub fn $i(x: $t) -> $t { x });
}

fn should_not_be_visible() {}

pub fn test_nil() {}
test!(test_bool, bool);

test!(test_int,  isize);
test!(test_uint, usize);

test!(test_i8,  i8);
test!(test_i16, i16);
test!(test_i32, i32);
test!(test_i64, i64);

test!(test_u8,  u8);
test!(test_u16, u16);
test!(test_u32, u32);
test!(test_u64, u64);

test!(test_f32, f32);
test!(test_f64, f64);
