require 'ffi'

module Rust
  # This class generates Ruby wrappers for a dylib
  # with information from an info.json file and
  # a ruby Module (or Class) Object
  class RubyWrapperGenerator
    # @info_file: info.json file path (String)
    def info_file=(path)
      @info_file = JSON.parse File.open(path, 'r').read
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
        inputs = fn['inputs'].map { |i| CToRuby.translate(i) }
        output = CToRuby.translate(fn['output'])

        # attach fn and define ruby wrapper
        mod.attach_function wrapper_name, inputs, output
        mod.instance_eval do
          define_method(name) do |*args|
            # check & convert ruby objects before handling them to FFI
            args.map!.with_index do |i,arg|
              RubyToC.convert(arg, fn['inputs'][i])
            end

            # call FFI function and convert output
            raw_output = send wrapper_name, *args
            CToRuby.convert(fn['output'], raw_output)
          end
        end
      end
    end
  end
end

module Rust
  module RubyToC
    # runs ruby code to make a ruby object usable via FFI
    # obj: Ruby object handed over to attached function
    # str: C type of input of attached fn (String)
    # returns something FFI can deal with
    def self.convert(obj, str)
      Converter.convert(obj, str)
    end

    # This is used to run ruby code that converts
    # a Ruby type into a C type
    class Converter
      # runs ruby code to make a ruby object usable via FFI
      # obj: Ruby object handed over to attached function
      # str: C type of input of attached fn (String)
      # returns something FFI can deal with
      def self.convert(obj, str)
        new.send str, obj
      end

      # all these types don't need to be converted,
      # so 'obj' is returned directly
      %w[nil bool int uint f32 f64].each do |s|
        define_method(s) { |obj| obj }
      end

      %w[8 16 32 64].each do |n|
        define_method("u#{n}") { |obj| obj }
        define_method("i#{n}") { |obj| obj }
      end

      # default: unimplemented
      def method_missing(*args)
        raise NotImplementedError, "Type conversion for type #{args[0]} is not implemented."
      end
    end
  end
end

module Rust
  # Translation and conversion of types from C to Ruby
  # Actually the types are from rusts libc, not 'real' C
  # and the ruby types are symbols understood by FFI
  module CToRuby
    # returns a symbol which represents an FFI type
    # str: rust type name from info.json (String)
    def self.translate(str)
      Translator.translate(str)
    end

    # runs ruby code to make a C object usable via ruby
    # str: C type (String)
    # obj: Ruby object returned from attached function
    # returns the usable object
    def self.convert(str, obj)
      new.send str, obj
    end

    # This class provides logic to translate a C type into a ruby FFI type
    class Translator
      # returns a symbol which represents an FFI type
      # str: rust type name from info.json (String)
      def self.translate(str)
        str = 'nil' if str.nil? #deal with nil
        new.send str
      end

      # nil is special
      define_method(:nil) { :void }

      # bool
      define_method(:bool) { :bool }

      # Machine integer types
      %w[8 16 32 64].each do |x|
        define_method("u#{x}") { "uint#{x}".to_sym }
        define_method("i#{x}") {  "int#{x}".to_sym }
      end

      # Platform dependent integers
      define_method(:int)  { :long }
      define_method(:uint) { :ulong }

      # Floats
      define_method(:f32) { :float }
      define_method(:f64) { :double }

      # if this is not implemented a bug was encountered,
      # because it shouldn't be that something is just
      # implemented on the ruby side.
      def method_missing(*args)
        raise NotImplementedError, "Type #{args[0]} is not implemented. This is a bug."
      end
    end

    #######################################################################

    # This is used to run ruby code that converts
    # a C type into a Ruby type
    class Converter
      # runs ruby code to make a C object usable via ruby
      # str: C type (String)
      # obj: Ruby object returned from attached function
      # returns the usable object
      def self.convert(str, name)
        new.send name
      end

      # all these types don't need to be converted,
      # so 'obj' is returned directly
      %w[nil bool int uint f32 f64].each do |s|
        define_method(s) { |obj| obj }
      end

      %w[8 16 32 64].each do |n|
        define_method("u#{n}") { |obj| obj }
        define_method("i#{n}") { |obj| obj }
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
