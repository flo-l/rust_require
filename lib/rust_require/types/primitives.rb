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

    class PrimitiveInteger < Type
        def initialize
            @bits = self.class.bits
            @signed = self.class.signed
            super
        end

        def self.bits; @bits; end
        def self.signed; @signed; end

        def rust_type_regex
          @rust_type ? super : /.^/ # will never match
        end

        def type_check(num)
          bounds = if @signed
            (-2**(@bits-1)+1)..(2**(@bits-1)-1)
          else
            0..(2**@bits-1)
          end

          raise ArgumentError, "#{num.inspect} is no integer." unless [Fixnum, Bignum].include? num.class
          raise ArgumentError, "#{num} is not in the expected input range #{bounds}" unless bounds.include? num
        end

        def ruby_input_conversion(num)
          type_check(num)
          num
        end
    end

    class Usize < PrimitiveInteger
        @rust_type = "usize"
        @bits = FFI::Pointer.size * 8
        @signed = false

        def ffi_type; :ulong; end
    end

    class Isize < PrimitiveInteger
        @rust_type = "isize"
        @bits = FFI::Pointer.size * 8
        @signed = true

        def ffi_type; :long; end
    end

    # metaprogramming!!
    %w[8 16 32 64].each do |x|
      usize = Class.new(PrimitiveInteger) do
        @bits = x.to_i
        @signed = false
        @rust_type = "u#{x}"

        def ffi_type; rust_type.sub('u', 'uint').to_sym; end
      end

      isize = Class.new(PrimitiveInteger) do
        @rust_type = "i#{x}"
        @bits = x.to_i
        @signed = true

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

      def ruby_input_conversion(float)
        bounds = -3.4028234663852886e+38 .. 3.4028234663852886e+38
        raise ArgumentError, "#{float.inspect} is no Float." unless float.is_a? Float
        raise ArgumentError, "#{float} is not in the expected input range #{bounds}" unless bounds.include? float
        float
      end
    end

    class F64 < Type
      @rust_type = 'f64'
      def ffi_type; :double; end

      def ruby_input_conversion(float)
        bounds = Float::MIN..Float::MAX
        raise ArgumentError, "#{float.inspect} is no Float." unless float.is_a? Float
        raise ArgumentError, "#{float} is not in the expected input range #{bounds}" unless bounds.include? float
        float
      end
    end
  end
end
