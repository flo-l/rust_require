use collections::BTreeMap;

//JSON support
use serialize::json::{
    self, ToJson, Json};

// syntax elements
use syntax::ast::StructDef;
use syntax::ast::StructFieldKind::*;

pub struct StructDefinition {
    name: String,
    //          (name  ,type  )
    fields: Vec<(String, String)>,
}

impl StructDefinition {
    pub fn new(name: String, struct_def: &StructDef) -> StructDefinition {
        let mut tuple_struct_index = 0i64;
        let fields: Vec<(String,String)> = struct_def.fields
        .iter()
        .map(|field|
            match field.node.kind {
                // TODO: handle visibility
                NamedField(ref ident, ref _visibility)
                    => (super::get_name_from_ident(ident), super::read_type(&field.node.ty.node)),
                UnnamedField(ref _visibility) => {
                    let t = (tuple_struct_index.to_string(), super::read_type(&field.node.ty.node));
                    tuple_struct_index += 1;
                    t
                }
            }
        )
        .collect();

        StructDefinition { name: name, fields: fields }
    }
}

// for serialization
// eg: struct Test { a: i64, b: String }
// =>  {"name":"Test","fields":[["a","i64"],["b","String"]]}
impl ToJson for StructDefinition {
    fn to_json(&self) -> json::Json {
        let mut j = BTreeMap::new();
        j.insert("name".to_string(), self.name.to_json());
        j.insert("fields".to_string(), self.fields.to_json());
        j.to_json()
    }
}
