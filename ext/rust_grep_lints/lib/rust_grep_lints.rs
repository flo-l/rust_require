#![crate_type = "dylib"]
#![feature(phase, plugin_registrar)]

extern crate syntax;
extern crate serialize;
extern crate collections;

// Load rustc as a plugin to get macros
#[phase(plugin, link)]
extern crate rustc;

//TreeMap
use collections::treemap::TreeMap;

//JSON support
use serialize::json::ToJson;
use serialize::json;

// some io
use std::io::File;
use std::fmt::{
  Show, Formatter, Result};

// syntax elements
use syntax::ast::{
  Block, FnDecl, Ty_, Ident, NodeId, TyNil, TyPath};
use syntax::codemap::Span;
use syntax::parse::token;
use syntax::visit::{
  FnKind, FkItemFn};

// lint things
use rustc::lint::{
  Context, LintPass, LintPassObject, LintArray};
use rustc::plugin::Registry;

// represents a function header:
// everything one needs to create a wrapper function
struct FnHeader {
  name: String,
  inputs: Vec<String>,
  output: String
}

impl FnHeader {
  fn new(name: String, fn_decl: &FnDecl) -> FnHeader {
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
        .map(|seg| get_name_from_ident(&seg.identifier))
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

// This returns the name of an Ident as String
fn get_name_from_ident(ident: &Ident) -> String {
  let name_str = token::get_ident(*ident);
  String::from_str(name_str.get())
}

// LINT DECLARATION AND REGISTRATION:
///////////////////////////////////////////////////////////////////////////

declare_lint!(FN_HEADERS, Allow,
              "Get the names of all freestanding functions in a file.")

struct FnHeaderGrep {
  output: File,
  fn_headers: Vec<FnHeader>
}

impl FnHeaderGrep {
  fn new() -> FnHeaderGrep {
    let (_,path_string) = std::os::env().iter()
    .filter(|&&(ref key,_)| key.as_slice() == "RUST_REQUIRE_FILE")
    .collect::<Vec<&(String,String)>>()
    .pop()
    .expect("RUST_REQUIRE_FILE not set!")
    .clone();

    let p = Path::new(path_string.as_slice());

    let file = match File::create(&p) {
        Ok(f)  => f,
        Err(e) => panic!("file error: {}", e)
    };

    FnHeaderGrep { output: file, fn_headers: vec![] }
  }
}

// JSON represantation of self
impl ToJson for FnHeaderGrep {
  fn to_json(&self) -> json::Json {
    let mut base_obj   = TreeMap::new();
    let mut fn_headers = TreeMap::new();

    for fn_header in self.fn_headers.iter() {
      fn_headers.insert(fn_header.name.clone(), fn_header.to_json());
    }

    base_obj.insert("fn_headers".to_string(), fn_headers.to_json());
    json::Object(base_obj)
  }
}

// Abuse Drop to write the output file
impl Drop for FnHeaderGrep {
  fn drop(&mut self) {
    match write!(self.output, "{}", self.to_json()) {
      Err(e) => panic!("file error: {}", e),
      Ok(_)  => {}
    };
  }
}

impl LintPass for FnHeaderGrep {
  fn get_lints(&self) -> LintArray {
    lint_array!(FN_HEADERS)
  }

  fn check_fn(&mut self, _: &Context, fn_kind: FnKind, fn_decl: &FnDecl, _: &Block, _: Span, _: NodeId) {
    match fn_kind {
      FkItemFn(ref ident,_,_,_) => {
        let name = get_name_from_ident(ident);
        self.fn_headers.push(FnHeader::new(name, fn_decl));
      },
      _      => {}
    }
  }
}

#[plugin_registrar]
pub fn plugin_registrar(reg: &mut Registry) {
  reg.register_lint_pass(box FnHeaderGrep::new() as LintPassObject);
}

