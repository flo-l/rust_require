use collections::BTreeMap;

//JSON support
use serialize::json::{
    self, ToJson, Json};

// some io
use std::fmt::{
    Display, Formatter, Result};

// syntax elements
use syntax::ast::{
  FnDecl, Ty_, Ident, TyPath, TyTup, FunctionRetTy};

// represents a function header:
// everything one needs to create a wrapper function
pub struct FnHeader {
  pub name: String,
  inputs: Vec<String>,
  output: String,
}

impl FnHeader {
  pub fn new(ident: &Ident, fn_decl: &FnDecl) -> FnHeader {
    let name = super::get_name_from_ident(ident);

    let inputs = fn_decl.inputs.iter()
    .map(|arg| FnHeader::read_type(&arg.ty.node))
    .collect::<Vec<String>>();

    let output = match &fn_decl.output {
        &FunctionRetTy::NoReturn(_) => unimplemented!(),
        &FunctionRetTy::DefaultReturn(_) => FnHeader::read_type(&Ty_::TyTup(vec![])),
        &FunctionRetTy::Return(ref ret) => FnHeader::read_type(&ret.node),
    };

    FnHeader { name: name, inputs: inputs, output: output }
  }

  // this should return a string version of the supplied type,
  // like: "uint" or "collections::string::String"
  fn read_type(t: &Ty_) -> String {
    match t {
      &TyTup(ref v) if v.is_empty() => String::from_str("nil"),
      &TyPath(_,ref p) => {
        let mut state = true;

        p.segments
        .iter()
        .map(|seg| super::get_name_from_ident(&seg.identifier))
        .fold(String::new(), |mut a, b| {
          if state {
            state = false;
            a.push_str(&b);
          } else {
            a.push_str(&format!("::{}", b));
          }
          a
        })
      },
      _ => panic!("cannot handle type: {:?}", t)

    }
  }
}


// for serialization
// eg: fn test1(i: int, j: String) {}
// =>  {"test1":{"inputs":["int","String"],"output":"nil"}}
impl ToJson for FnHeader {
    fn to_json(&self) -> json::Json {
        let mut fn_obj = BTreeMap::new();
        fn_obj.insert("inputs".to_string(), self.inputs.to_json());
        fn_obj.insert("output".to_string(), self.output.to_json());
        fn_obj.to_json()
    }
}

// Prints the JSON representation of FnHeader
impl Display for FnHeader {
  fn fmt(&self, f: &mut Formatter) -> Result {
    write!(f, "{}", self.to_json())
  }
}
