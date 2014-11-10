module Rust
  # A Wrapper to use rustc
  class Rustc
    # Path of rustc lint plugin to gather information about .rs files
    SOURCE_ANALYZER = File.absolute_path('ext/rust_grep_lints/lib/libsource_analyzer.so')

    # default rustc command
    RUSTC_CMD = 'rustc --crate-type dylib -A dead_code'

    # @output_path: output path for library generated by Rustc
    attr_accessor :output_path

    # @info_file_path is the info.json file containing infos about the rust lib
    attr_accessor :info_file_path

    # @subdir is the dir where various files can be stored
    attr_writer :subdir

    # input is a String object containing the absolute path to an input file
    def initialize(input)
      @input_path = input
    end

    # creates a c-wrapper for file at @input_path
    # returns info.json, parsed with JSON
    def create_wrapper
      # @input_path with wrappers
      @tempfile = "#{@subdir}/#{File.basename(@input_path)}"

      analyze_tempfile

      # parse info.json
      info_file = JSON.parse File.open(@info_file_path, 'r').read

      gen = CWrapperGenerator.new(info_file)

      File.open(@tempfile, "a") do |f|
        f << gen.generate_wrapper
      end

      # return info_file for further use
      info_file
    end

    # Compiles file @input_path with rustc
    def compile
      puts `#{RUSTC_CMD} #{@tempfile} -o #{@output_path}`
    end

    private
    # Analyze @tempfile with the lint
    # create an info.json file in @subdir
    def analyze_tempfile
      File.open(@tempfile, 'w+') do |f|
        # injection of the librust_grep_lints plugin
        f << "#![feature(phase)]\n#[phase(plugin)]\nextern crate source_analyzer;\n"

        # add the actual file content
        File.open(@input_path, "r") { |input| f << input.read }
      end

      # use the lint to just parse the file (no output)
      puts `RUST_REQUIRE_FILE=#{@info_file_path} #{RUSTC_CMD} --no-trans -L #{File.dirname(SOURCE_ANALYZER)} #{@tempfile}`

      # remove the injected lint plugin again
      File.open(@tempfile, 'w+') do |f|
        # add just the actual file content
        File.open(@input_path, "r") { |input| f << input.read }
      end
    end
  end
end
