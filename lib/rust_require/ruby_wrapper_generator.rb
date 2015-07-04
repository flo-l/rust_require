module Rust
  # This class generates Ruby wrappers for a dylib
  # with information from an info.json file and
  # a ruby Module (or Class) Object
  class RubyWrapperGenerator
    # @info_file: info.json file, parsed with JSON
    def info_file=(info_file)
      @info_file = info_file
    end

    # @rust_lib: path to the rust lib to be included (String)
    attr_writer :rust_lib

    # makes items from lib available in mod
    # mod: Module/Class into which the wrappers should get included (Module || Class)
    def include_lib(mod)
      # attach items according to @info_file
      attach_items(@info_file, mod, '')
    end

    # attaches items to mod,
    # mod_string is the mod's prefix eg 'mod_submod_'
    def attach_items(rust_module, mod, mod_string)
      rust_module['submodules'].each do |x|
        rust_mod = Module.new
        attach_items(x, rust_mod, mod_string+x['name']+'_')
        mod.const_set(x['name'].camelize, rust_mod)
      end

      attach_fns(rust_module['fn_headers'], mod, mod_string)
      attach_structs(rust_module['structs'], mod)
    end

    # attaches fns via FFI to mod
    def attach_fns(fn_headers, mod, mod_string)
      # add ffi and the rust lib to mod
      mod.extend FFI::Library
      mod.ffi_lib @rust_lib

      fn_headers.each do |fn|
        rust_fn_name = fn['name']

        # fn mod::fn() => fn _mod_fn_wrapper
        wrapper_name = "_#{mod_string+fn['name']}_wrapper".to_sym

        input_types = fn['inputs'].map { |t| Rust::Types.find_type(t) }
        ffi_input_types = input_types.map { |t| t.ffi_input_type }


        output_type = Rust::Types.find_type(fn['output'])
        ffi_output_type = output_type.ffi_output_type

        # attach fn and define ruby wrapper
        mod.attach_function wrapper_name, ffi_input_types, ffi_output_type
        mod.instance_eval do
          define_method(rust_fn_name) do |*args|
            # check input parameter count
            raise ArgumentError, "wrong number of arguments (#{args.count} for #{input_types.count})" unless args.count == input_types.count

            # check & convert ruby objects before handling them to FFI
            args.map!.with_index do |arg,i|
              input_types[i].ruby_input_conversion(arg)
            end

            # call FFI function and convert output
            raw_output = send wrapper_name, *args
            output_type.ruby_output_conversion raw_output
          end
        end
      end
    end

    # attaches structs via FFI to mod
    def attach_structs(struct_defs, mod)
      struct_defs.each do |s|
        fields = s['fields'].map do |name, type|
          type = Rust::Types.find_type(type)
          [name.to_sym, type.ffi_output_type]
        end.flatten

        struct = Class.new(Rust::Struct)
        struct.layout *fields

        mod.const_set(s['name'], struct)
      end
    end
  end
end
