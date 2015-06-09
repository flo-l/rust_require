module Rust
  # a rust fat pointer
  class Slice < FFI::Struct
    layout :ptr, :pointer,
           :len, :uint

    def self.from(start, len)
      s = new
      s[:ptr] = start
      s[:len] = len
      s
    end

    def unpack
      [self[:ptr], self[:len]]
    end
  end

  # Types are used to implement support
  # for rust types in rust_require
  module Types
    # returns type instance for rust_type
    def self.find_type(rust_type)
      # find types in module constants
      type = constants
       .map     { |c| const_get(c) }
       .keep_if { |c| c.is_a?(Class) && c.ancestors.include?(Type) && c != Type} #just Type subclass objects, excluding Type itself
       .map     { |c| c.new } # instances of the Type classes
       .find    { |c| c.rust_type_regex =~ rust_type }

      if type
        type.rust_type = rust_type
        type
      else
        raise NotImplementedError, "type #{rust_type} is not implemented!"
      end
    end

    # The base class for Types with simple defaults
    class Type
      # accessor for @rust_type of Type class
      def self.rust_type; @rust_type; end

      # set @rust_type from class variable @rust_type
      def initialize
        @rust_type = self.class.rust_type
      end

      # name of the rust type (String)
      # raises error when @rust_type is nil
      def rust_type
        raise NotImplementedError, "This is a bug." if @rust_type.nil?
        @rust_type
      end

      attr_writer :rust_type

      def rust_type_regex
        Regexp.new @rust_type
      end

      def c_type; rust_type; end

      # name of the type passed in from ruby (String)
      def c_input_type; c_type; end

      # name of the type returned by the wrapper fn to ruby
      def c_output_type; c_type; end

      # rust code performing necessary conversions on input from ruby
      # with name before passing it to original rust fn (String)
      def c_input_conversion(name); name; end

      # rust code performing necessary conversions on output with name
      # from rust fn before returning it to ruby (String)
      def c_output_conversion(name); name; end

      # Border between Rust and Ruby
      ########################################

      # shortcut for ffi type (input and output)
      def ffi_type; rust_type.to_sym; end

      # returns symbol understood by ruby ffi gem corresponding to @rust_type as input
      def ffi_input_type; ffi_type; end

      # returns symbol understood by ruby ffi gem corresponding to @rust_type as output
      def ffi_output_type; ffi_type; end

      # return value will directly be passed into the ffi fn
      def ruby_input_conversion(obj); obj; end

      # obj is return value of ffi fn
      # return value will be the final result of ffi call
      def ruby_output_conversion(obj); obj; end
    end
  end
end
