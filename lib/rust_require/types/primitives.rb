module Rust
  # Implement primitive types:
  module Types
    # nil
    class Nil < Type
      @rust_type = 'nil'

      def c_type; '()'; end
      def ffi_output_type; :void; end
      def ffi_input_type
        raise ArgumentError, "nil as ffi input is not supported by the ffi gem"
      end
    end

    class Bool < Type
        @rust_type = "bool"
    end

    class Isize < Type
        @rust_type = "isize"
        def ffi_type; :int; end
    end

    class Usize < Type
        @rust_type = "usize"
        def ffi_type; :uint; end
    end

    # more metaprogramming!!
    %w[8 16 32 64].each do |x|
      usize = Class.new(Type) do
        @rust_type = "u#{x}"
        def ffi_type; rust_type.sub('u', 'uint').to_sym; end
      end

      isize = Class.new(Type) do
        @rust_type = "i#{x}"
        def ffi_type; rust_type.sub('i', 'int').to_sym; end
      end

      const_set('U'+x, usize)
      const_set('I'+x, isize)
    end

    class F32 < Type
      @rust_type = 'f32'

      # Ruby Floats are always f64
      def c_type; 'f64'; end
      def c_input_conversion(name); "#{name} as f32"; end
      def c_output_conversion(name); "#{name} as f64"; end

      def ffi_type; :double; end
    end

    class F64 < Type
      @rust_type = 'f64'
      def ffi_type; :double; end
    end
  end
end
