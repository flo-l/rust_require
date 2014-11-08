# Libs
require_relative 'rust_require/rust_require.rb'
require_relative 'rust_require/rustc.rb'
require_relative 'rust_require/types.rb'
require_relative 'rust_require/c_wrapper_generator.rb'
require_relative 'rust_require/ruby_wrapper_generator.rb'

# Types
require_relative 'rust_require/types/primitives.rb'

class Module
  def rust_require(file)
    Rust.require_rust_file(file, self)
  end
end
