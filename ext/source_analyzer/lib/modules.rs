//BTreeMap
use collections::BTreeMap;

//JSON support
use serialize::json::{
    self, ToJson, Json};

// syntax elements
use syntax::ast::Visibility;
use syntax::ast::Item_::*;
use syntax::ast::Mod as SyntaxMod;

use super::fn_headers::FnHeader;

pub struct Module {
    name: String,
    fn_headers: Vec<FnHeader>,
    submodules: Vec<Module>,
}

impl Module {
    pub fn new(name: String, module: &SyntaxMod) -> Module {
        let mut fn_headers = vec![];
        let mut submodules = vec![];

        let iter = module.items.iter()
        .filter(|x| match x.vis { Visibility::Public => true, Visibility::Inherited => false });

        for x in iter {
            match x.node {
                ItemFn(ref fn_decl,_,_,_,_,_) => fn_headers.push(FnHeader::new(&x.ident, fn_decl)),
                ItemMod(ref module) => submodules.push(Module::new(super::get_name_from_ident(&x.ident), module)),
                _ => (),
            }
        }

        Module { name: name, fn_headers: fn_headers, submodules: submodules }
    }
}

// JSON representation of self
impl ToJson for Module {
    fn to_json(&self) -> json::Json {
        let mut j = BTreeMap::new();
        j.insert("name".to_string(),       self.name.to_json());
        j.insert("fn_headers".to_string(), self.fn_headers.to_json());
        j.insert("submodules".to_string(), self.submodules.to_json());
        j.to_json()
    }
}
