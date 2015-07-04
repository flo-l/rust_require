# deactivated for now, maybe reactivated later with explicit conversion

module Rust
  module Types
    class String < Type
      @rust_type = 'String'

      def not_implemented
        raise NotImplementedError, 'String as rust input type is not supported, use &str instead!'
      end

      def c_input_type
        not_implemented
      end

      def c_output_type; '(*const u8,usize)'; end

      def c_output_conversion(name)
        <<-CODE
        {
            let mut #{name} = #{name};

            // deallocate unused capacity if any
            if #{name}.len() != #{name}.capacity() {
                unsafe {
                    let ptr = #{name}.as_mut_vec().as_mut_ptr();
                    std::rt::heap::deallocate(
                        ptr.offset(#{name}.len() as isize),
                        #{name}.capacity() - #{name}.len(),
                        std::mem::min_align_of::<u8>()
                    );
                }
            }

            let tuple = (#{name}.as_ptr(), #{name}.len());
            std::mem::forget(#{name});
            tuple
        }
        CODE
      end

      def c_input_conversion(slice)
        not_implemented
      end

      def ffi_type; Rust::Slice.by_value; end

      def ruby_output_conversion(slice)
        (start,len) = slice.unpack
        start.read_string(len.to_i).force_encoding("UTF-8")
      end

      def ruby_input_conversion(str)
        not_implemented
      end
    end

    class StrSlice < Type
      def rust_type_regex
        /^&(mut)?( )?str$/
      end

      def not_implemented
        raise NotImplementedError, '&mut str/&str as rust output parameter is not supported, use String instead!'
      end

      def c_output_type
        not_implemented
      end

      def c_output_conversion(name)
        not_implemented
      end

      def c_input_conversion(slice)
        "#{slice}"
      end

      def ffi_type; Rust::Slice.by_value; end

      def ruby_output_conversion(slice)
        not_implemented
      end

      def ruby_input_conversion(str)
        str.encode!(Encoding::UTF_8)
        len = str.bytesize
        start = FFI::MemoryPointer.from_string(str)
        start.autorelease = false # no GC
        Rust::Slice.from(start.address, len)
      end
    end
  end
end
