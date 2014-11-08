require 'json'

module Rust
  # A Generator for Rust-to-C-wrappers
  # Is initialized with a Json file containing
  # relevant info about the rust file
  class CWrapperGenerator
    # info file, already parsed with json
    def initialize(json)
      @json = json
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
        # convert inputs
        input_types = @inputs.map  { |t| Rust::Types.find_type(t) }
        c_inputs = input_types.map { |t| t.c_input_type } #C input types ([String])
        input_str = c_inputs.map.with_index { |t,i| "c#{i}: #{t}" }.join(',') #fn foo_wrapper(input_str) ...
        input_conversions = input_types.map.with_index { |t,i| t.c_input_conversion("c#{i}") }.join("\n") #code used to convert input types to c types

        # convert output
        output_type = Rust::Types.find_type(@output)
        c_output = output_type.c_output_type
        output_conversion = output_type.c_output_conversion('output')

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
