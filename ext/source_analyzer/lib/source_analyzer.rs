#![crate_type = "dylib"]
#![feature(rustc_private, plugin_registrar, collections)]

extern crate syntax;
extern crate serialize;
extern crate collections;

// Load rustc with macros
#[macro_use]
extern crate rustc;

//BTreeMap
use collections::BTreeMap;

//JSON support
use serialize::json::{
    self, ToJson, Json};

// some io
use std::path::Path;
use std::fs::File;
use std::io::Write;

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
//mod modules;

// NICE LITTLE HELPERS
///////////////////////////////////////////////////////////////////////////

// This returns the name of an Ident as String
fn get_name_from_ident(ident: &Ident) -> String {
  let name_str = token::get_ident(*ident);
  String::from_str(&name_str)
}

// LINT DECLARATION AND REGISTRATION:
///////////////////////////////////////////////////////////////////////////

declare_lint!(SOURCE_ANALYZER, Allow, "Analyze rust source file and produce json output named RUST_REQUIRE_FILE");

struct SourceAnalyzer {
  output: File,
  fn_headers: Vec<fn_headers::FnHeader>
}

impl SourceAnalyzer {
  fn new() -> SourceAnalyzer {
    let (_,path_string) = std::env::vars()
    .filter(|&(ref key,_)| key == &"RUST_REQUIRE_FILE")
    .next()
    .expect("RUST_REQUIRE_FILE not set!")
    .clone();

    let p = Path::new(&path_string);

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
    let mut base_obj   = BTreeMap::new();
    let mut fn_headers = BTreeMap::new();

    for fn_header in self.fn_headers.iter() {
      fn_headers.insert(fn_header.name.clone(), fn_header.to_json());
    }

    base_obj.insert("fn_headers".to_string(), fn_headers.to_json());
    base_obj.to_json()
  }
}

// Abuse Drop to write the output file
impl Drop for SourceAnalyzer {
  fn drop(&mut self) {
    let json = self.to_json();
    match write!(self.output, "{}", json) {
      Err(e) => panic!("file error: {}", e),
      Ok(_)  => ()
    };
  }
}

impl LintPass for SourceAnalyzer {
  fn get_lints(&self) -> LintArray {
    lint_array!(SOURCE_ANALYZER)
  }

  fn check_fn(&mut self, _: &Context, fn_kind: FnKind, fn_decl: &FnDecl, _: &Block, _: Span, _: NodeId) {
    match fn_kind {
      FkItemFn(ref ident,_,_,_,_,_) => self.fn_headers.push(fn_headers::FnHeader::new(ident, fn_decl)),
      _ => (),
    }
  }
}

#[plugin_registrar]
pub fn plugin_registrar(reg: &mut Registry) {
  reg.register_lint_pass(Box::new(SourceAnalyzer::new()) as LintPassObject);
}

