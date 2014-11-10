//TreeMap
use collections::treemap::TreeMap;

//JSON support
use serialize::json::ToJson;
use serialize::json;

// some io
use std::fmt::{
  Show, Formatter, Result};

// syntax elements
use syntax::ast::{
  FnDecl, Ty_, Ident, TyNil, TyPath};

// represents a function header:
// everything one needs to create a wrapper function
pub struct FnHeader {
  pub name: String,
  inputs: Vec<String>,
  output: String
}

impl FnHeader {
  pub fn new(ident: &Ident, fn_decl: &FnDecl) -> FnHeader {
    let name = super::get_name_from_ident(ident);

    let inputs = fn_decl.inputs.iter()
    .map(|arg| FnHeader::read_type(&arg.ty.node.clone()))
    .collect::<Vec<String>>();

    let output = FnHeader::read_type(&fn_decl.output.node);

    FnHeader { name: name, inputs: inputs, output: output }
  }

  // this should return a string version of the supplied type,
  // like: "uint" or "collections::string::String"
  fn read_type(t: &Ty_) -> String {
    match (*t).clone() {
      TyNil => String::from_str("nil"),
      TyPath(p,_,_) => {
        let mut state = true;

        p.segments.iter()
        .map(|seg| super::get_name_from_ident(&seg.identifier))
        .fold(String::new(), |mut a, b| {
          if state {
            state = false;
            a.push_str(b.as_slice());
          } else {
            a.push_str(format!("::{}", b).as_slice());
          }
          a
        })
      },
      _ => panic!("cannot handle type: {}", t)

    }
  }
}

// for serialization
// eg: fn test1(i: int, j: String) {}
// =>  {"test1":{"inputs":["int","String"],"output":null}}
impl ToJson for FnHeader {
    fn to_json(&self) -> json::Json {
        let mut fn_obj = TreeMap::new();
        fn_obj.insert("inputs".to_string(), self.inputs.to_json());
        fn_obj.insert("output".to_string(), self.output.to_json());
        json::Object(fn_obj)
    }
}

// Prints the JSON representation of FnHeader
impl Show for FnHeader {
  fn fmt(&self, f: &mut Formatter) -> Result {
    write!(f, "{}", self.to_json())
  }
}
