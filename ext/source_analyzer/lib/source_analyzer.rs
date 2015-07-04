#![crate_type = "dylib"]
#![feature(rustc_private, plugin_registrar, collections)]

extern crate syntax;
extern crate serialize;
extern crate collections;

// Load rustc with macros
#[macro_use]
extern crate rustc;

use serialize::json::ToJson;

// some io
use std::path::Path;
use std::fs::File;
use std::io::Write;

// syntax elements
use syntax::ast::{
    Crate, Ty_, Ident, TyPath, TyTup, Mutability, TyRptr};

use syntax::parse::token;

// lint things
use rustc::lint::{
    Context, LintPass, LintPassObject, LintArray};
use rustc::plugin::Registry;

//Load mods
mod fn_headers;
mod modules;
mod structs;

use modules::Module;

// NICE LITTLE HELPERS
///////////////////////////////////////////////////////////////////////////

// This returns the name of an Ident as String
fn get_name_from_ident(ident: &Ident) -> String {
    let name_str = token::get_ident(*ident);
    String::from(&*name_str)
}

// this should return a string version of the supplied type,
// like: "uint" or "collections::string::String"
fn read_type(t: &Ty_) -> String {
    match t {
        &TyTup(ref v) if v.is_empty() => String::from("nil"),
        &TyPath(_,ref p) => {
            let mut state = true;

            p.segments
            .iter()
            .map(|seg| get_name_from_ident(&seg.identifier))
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
        &TyRptr(lifetime,ref ty) => {
            let mut s: String = "&".into();

            if lifetime.is_some() {
                panic!("references with lifetimes are not yet supported!");
            }

            match ty.mutbl {
                Mutability::MutMutable   => s.push_str("mut "),
                Mutability::MutImmutable => s.push_str(" "),
            }

            s.push_str(&read_type(&ty.ty.node));
            s
        }
        t => {
            println!("cannot handle type: {:?}", t);
            unimplemented!();
        }
    }
}

// LINT DECLARATION AND REGISTRATION:
///////////////////////////////////////////////////////////////////////////

declare_lint!(SOURCE_ANALYZER, Allow, "Analyze rust source file and produce json output named RUST_REQUIRE_FILE");

struct SourceAnalyzer {
    output: File,
    top_level_mod: Option<Module>,
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

        SourceAnalyzer { output: file, top_level_mod: None }
    }
}

// Abuse Drop to write the output file
impl Drop for SourceAnalyzer {
    fn drop(&mut self) {
        let json = self.top_level_mod.as_ref().unwrap().to_json();
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

    fn check_crate(&mut self, _: &Context, c: &Crate) {
        self.top_level_mod = Some(Module::new("top_level".to_string(), &c.module));
    }
}

#[plugin_registrar]
pub fn plugin_registrar(reg: &mut Registry) {
    reg.register_lint_pass(Box::new(SourceAnalyzer::new()) as LintPassObject);
}

