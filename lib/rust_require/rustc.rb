module Rust
  # A Wrapper to use rustc
  class Rustc
    # Path of rustc lint plugin to gather information about .rs files
    SOURCE_ANALYZER = Gem::Specification.find_by_name('rust_require').full_gem_path + '/ext/source_analyzer/lib/libsource_analyzer.so'

    # default rustc command
    RUSTC_CMD = 'rustc --crate-type dylib -A dead_code'

    # @output_path: output path for library generated by Rustc
    attr_accessor :output_path

    # @info_file_path is the info.json file containing infos about the rust lib
    attr_accessor :info_file_path

    # @subdir is a tempdir
    attr_writer :subdir

    # input is a String object containing the absolute path to an input file
    def initialize(input)
      @input_path = input
    end

    # creates a c-wrapper for file at @input_path
    # returns info.json, parsed with JSON
    def create_wrapper
      # @input_path with wrappers added
      @tempfile = "#{File.dirname(@input_path)}/#{File.basename(@input_path, ".*")}_wrapper.rs"

      analyze_tempfile

      # parse info.json
      info_file = JSON.parse File.open(@info_file_path, 'r').read

      gen = CWrapperGenerator.new(info_file)

      File.open(@tempfile, "w+") do |f|
        # add necessary extern crate definitions #FIXME: if this proves to be unnecessary remove it
        f << <<-SRC

        SRC

        # add the actual file content
        File.open(@input_path, "r") { |input| f << input.read }

        # add wrappers
        f << gen.generate_wrapper
      end

      # return info_file for further use
      info_file
    end

    # Compiles file @input_path with rustc
    def compile
      print `#{RUSTC_CMD} -L #{File.dirname(@input_path)} #{@tempfile} -o #{@output_path}`
      raise "rust compiler error" if $? != 0
      `rm #{@tempfile}`
    end

    private
    # Analyze @tempfile with the lint
    # create an info.json file in @subdir
    def analyze_tempfile
      File.open(@tempfile, 'w+') do |f|
        # injection of the librust_grep_lints plugin
        f << "#![feature(plugin)]\n#![plugin(source_analyzer)]\n"

        # add the actual file content
        File.open(@input_path, "r") { |input| f << input.read }
      end

      # use the lint to just parse the file (no output)
      print `RUST_REQUIRE_FILE=#{@info_file_path} #{RUSTC_CMD} -Z no-trans -L #{File.dirname(@input_path)} -L #{File.dirname(SOURCE_ANALYZER)} #{@tempfile}`
      raise "rust compiler error" if $? != 0

      # remove the injected lint plugin again
      File.open(@tempfile, 'w+') do |f|
        # add just the actual file content
        File.open(@input_path, "r") { |input| f << input.read }
      end
    end
  end
end
