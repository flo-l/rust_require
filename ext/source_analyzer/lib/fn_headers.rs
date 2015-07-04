use collections::BTreeMap;

//JSON support
use serialize::json::{
    self, ToJson, Json};

// some io
use std::fmt::{
    Display, Formatter, Result};

// syntax elements
use syntax::ast::{
    FnDecl, Ty_, Ident, TyTup, FunctionRetTy};

// helpers
use super::read_type;

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
        .map(|arg| read_type(&arg.ty.node))
        .collect::<Vec<String>>();

        let output = match &fn_decl.output {
            &FunctionRetTy::NoReturn(_) => unimplemented!(),
            &FunctionRetTy::DefaultReturn(_) => read_type(&Ty_::TyTup(vec![])),
            &FunctionRetTy::Return(ref ret) => read_type(&ret.node),
        };

        FnHeader { name: name, inputs: inputs, output: output }
    }
}


// for serialization
// eg: fn test1(i: int, j: String) {}
// =>  {"name":"test1","inputs":["int","String"],"output":"nil"}
impl ToJson for FnHeader {
    fn to_json(&self) -> json::Json {
        let mut j = BTreeMap::new();
        j.insert("name".to_string(), self.name.to_json());
        j.insert("inputs".to_string(), self.inputs.to_json());
        j.insert("output".to_string(), self.output.to_json());
        j.to_json()
    }
}

// Prints the JSON representation of FnHeader
impl Display for FnHeader {
    fn fmt(&self, f: &mut Formatter) -> Result {
        write!(f, "{}", self.to_json())
    }
}
