extern crate serialize;
extern crate collections;

use serialize::json::ToJson;
use serialize::json;
use collections::treemap::TreeMap;

fn main() {
  let mut test = TreeMap::new();
  test.insert(String::from_str("test_nil"), 1u.to_json());
  let obj = json::Object(test);
  assert_eq!(obj.to_string(), String::from_str("{\"nil\":1}"));
}
