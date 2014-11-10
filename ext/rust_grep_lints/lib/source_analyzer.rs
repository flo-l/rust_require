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

// syntax elements
use syntax::ast::{
  Block, FnDecl, Ident, NodeId};
use syntax::codemap::Span;
use syntax::parse::token;
use syntax::visit::{
  FnKind, FkItemFn};

// lint things
use rustc::lint::{
  Context, LintPass, LintPassObject, LintArray};
use rustc::plugin::Registry;

//Load mods
mod fn_headers;

// NICE LITTLE HELPERS
///////////////////////////////////////////////////////////////////////////

// This returns the name of an Ident as String
fn get_name_from_ident(ident: &Ident) -> String {
  let name_str = token::get_ident(*ident);
  String::from_str(name_str.get())
}

// LINT DECLARATION AND REGISTRATION:
///////////////////////////////////////////////////////////////////////////

declare_lint!(SOURCE_ANALYZER, Allow, "Analyze rust source file and produce json output named RUST_REQUIRE_FILE")

struct SourceAnalyzer {
  output: File,
  fn_headers: Vec<fn_headers::FnHeader>
}

impl SourceAnalyzer {
  fn new() -> SourceAnalyzer {
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

    SourceAnalyzer { output: file, fn_headers: vec![] }
  }
}

// JSON represantation of self
impl ToJson for SourceAnalyzer {
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
impl Drop for SourceAnalyzer {
  fn drop(&mut self) {
    match write!(self.output, "{}", self.to_json()) {
      Err(e) => panic!("file error: {}", e),
      Ok(_)  => {}
    };
  }
}

impl LintPass for SourceAnalyzer {
  fn get_lints(&self) -> LintArray {
    lint_array!(SOURCE_ANALYZER)
  }

  fn check_fn(&mut self, _: &Context, fn_kind: FnKind, fn_decl: &FnDecl, _: &Block, _: Span, _: NodeId) {
    match fn_kind {
      FkItemFn(ref ident,_,_,_) => self.fn_headers.push(fn_headers::FnHeader::new(ident, fn_decl)),
      _ => {}
    }
  }
}

#[plugin_registrar]
pub fn plugin_registrar(reg: &mut Registry) {
  reg.register_lint_pass(box SourceAnalyzer::new() as LintPassObject);
}

