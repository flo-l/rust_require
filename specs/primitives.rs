//just functions taking primitives and returning them unmodified

fn test_nil() {}
fn test_bool(b: bool) -> bool { b }

fn test_int(i: isize) -> isize { i }
fn test_uint(u: usize) -> usize { u }


fn test_i8(i: i8) -> i8 { i }
fn test_i16(i: i16) -> i16 { i }
fn test_i32(i: i32) -> i32 { i }
fn test_i64(i: i64) -> i64 { i }

fn test_u8(u: u8) -> u8 { u }
fn test_u16(u: u16) -> u16 { u }
fn test_u32(u: u32) -> u32 { u }
fn test_u64(u: u64) -> u64 { u }

fn test_f32(f: f32) -> f32 { f }
fn test_f64(f: f64) -> f64 { f }
