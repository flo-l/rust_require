pub mod sub_module {
    pub mod sub_sub_module {
        pub fn test() {}
    }

    mod invisible_module {}
}

pub mod external_file_module;
pub mod external_dir_module;

fn main() {}
