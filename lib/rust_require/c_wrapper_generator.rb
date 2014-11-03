require 'json'

module Rust
  # A Generator for Rust-to-C-wrappers
  # Is initialized with a Json file containing
  # relevant info about the rust file
  class CWrapperGenerator
    # info file path
    def initialize(path)
      @json = JSON.parse File.open(path, 'r').read
    end

    # Generates a Rust-to-C code wrapper as rust code (String)
    def generate_wrapper
      @json['fn_headers'].map do |name, fn|
        WrapperFn.new(name, fn['inputs'], fn['output']).to_s
      end.join("\n")
    end
  end
end

module Rust
  class CWrapperGenerator
    # Rust code of a wrapper function
    class WrapperFn
      # original_name: name of the fn to be wrapped (String)
      # inputs:        input types in order         (Array[String])
      # output:        output type                  (String || nil)
      def initialize(original_name, inputs, output)
        @original_name = original_name
        @inputs = inputs
        @output = output
      end

      # returns string of rust code
      def to_s
        c_inputs = @inputs.map { |t| RustToC.translate(t) } #C input types
        input_str = c_inputs.map.with_index { |t,i| "c#{i}: #{t}" }.join(',') #fn foo_wrapper(input_str) ...
        input_conversions = @inputs.map.with_index { |t,i| RustToC.convert(@inputs[i], "c#{i}") }.join("\n") #code used to convert input types to c types

        c_output = CToRust.translate(@output)
        output_conversion = CToRust.convert(@output, 'output')

        <<-END
          #[no_mangle]
          pub extern "C" fn _#{@original_name}_wrapper(#{input_str}) -> #{c_output} {
            let output = #{@original_name}(#{input_conversions});
            #{output_conversion}
          }
        END
      end
    end
  end
end

module Rust
  # Translation and conversion of types from rust to C
  module RustToC
    # returns C type of self
    # str: String representing type (String)
    def self.translate(str)
      Translator.translate(str)
    end

    # returns a rust code snippet that converts a
    # variable with 'name' and type 'str' to a c_type
    # str: type name (String)
    # name: name of the variable (String)
    def self.convert(str, name)
      Converter.convert(str, name)
    end

    # This class provides logic to translate a rust type into a c type
    class Translator
      # returns c_type of self
      # str: String representing type (String)
      def self.translate(str)
        new.send str
      end

      # nil is special
      define_method(:nil) { '()' }

      # all these types are the same in c
      %w[bool int uint f32 f64].each do |s|
        define_method(s) { s }
      end

      # Machine integer types
      %w[8 16 32 64].each do |x|
        define_method("u#{x}") { "u#{x}" }
        define_method("i#{x}") { "i#{x}" }
      end

      # default: unimplemented
      def method_missing(*args)
        raise NotImplementedError, "Type #{args[0]} is not implemented."
      end
    end

    #######################################################################

    # This is used to create rust code snippets that convert
    # a rust type into a C type
    class Converter
      # returns a rust code snippet that converts a
      # variable with 'name' and type 'str' to a c_type
      # str: type name (String)
      # name: name of the variable (String)
      def self.convert(str, name)
        new.send str, name
      end

      # all these types don't need to be converted,
      # so we return 'name'
      %w[nil bool int uint f32 f64].each do |s|
        define_method(s) { |name| name }
      end

      %w[8 16 32 64].each do |n|
        define_method("u#{n}") { |name| name }
        define_method("i#{n}") { |name| name }
      end

      # default: unimplemented
      def method_missing(*args)
        raise NotImplementedError, "Type conversion for type #{args[0]} is not implemented."
      end
    end
  end
end

module Rust
  # Translation and conversion of types from C to rust
  # Actually the types are from rusts libc, not 'real' C
  module CToRust
    # returns rust_type of self
    # str: String representing type (String)
    def self.translate(str)
      Translator.translate(str)
    end

    # returns a rust code snippet that converts a
    # variable with 'name' (String) to a rust type
    def self.convert(str, name)
      Converter.convert(str, name)
    end

    # This class provides logic to translate a C type into a rust type
    class Translator
      # returns rust_type of self
      # str: String representing type (String)
      def self.translate(str)
        new.send str
      end

      # nil is special
      define_method(:nil) { '()' }

      # all these types are the same in rust and C
      %w[bool int uint f32 f64].each do |s|
        define_method(s) { s }
      end

      # Machine integer types
      %w[8 16 32 64].each do |x|
        define_method("u#{x}") { "u#{x}" }
        define_method("i#{x}") { "i#{x}" }
      end

      # if this is not implemented a bug was encountered,
      # because it shouldn't be that something is just
      # implemented on the ruby side.
      def method_missing(*args)
        raise NotImplementedError, "Type #{args[0]} is not implemented. This is a bug."
      end
    end

    #######################################################################

    # This is used to create rust code snippets that convert
    # a C type into a rust type
    class Converter
      # returns a rust code snippet that converts a
      # variable with 'name' (String) to a rust type
      def self.convert(str, name)
        new.send str, name
      end

      # all these types don't need to be converted,
      # so we return 'name'
      %w[nil bool int uint f32 f64].each do |s|
        define_method(s) { |name| name }
      end

      %w[8 16 32 64].each do |n|
        define_method("u#{n}") { |name| name }
        define_method("i#{n}") { |name| name }
      end

      # if this is not implemented a bug was encountered,
      # because it shouldn't be that something is just
      # implemented on the ruby side.
      def method_missing(*args)
        raise NotImplementedError, "Type conversion for type #{args[0]} is not implemented. This is a bug."
      end
    end
  end
end
