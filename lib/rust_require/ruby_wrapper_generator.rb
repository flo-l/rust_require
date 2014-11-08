require 'ffi'

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
      # add ffi and the rust lib to mod
      mod.extend FFI::Library
      mod.ffi_lib @rust_lib

      # attach functions according to @info_file
      attach_fns(mod)
    end

    # attaches functions via FFI
    def attach_fns(mod)
      @info_file['fn_headers'].each do |name, fn|
        wrapper_name = "_#{name}_wrapper".to_sym

        input_types = fn['inputs'].map { |t| Rust::Types.find_type(t) }
        ffi_input_types = input_types.map { |t| t.ffi_input_type }


        output_type = Rust::Types.find_type(fn['output'])
        ffi_output_type = output_type.ffi_output_type

        # attach fn and define ruby wrapper
        mod.attach_function wrapper_name, ffi_input_types, ffi_output_type
        mod.instance_exec do
          define_method(name) do |*args|
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
  end
end
