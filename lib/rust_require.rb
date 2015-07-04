# Extern libs
require 'ffi'
require 'active_support/core_ext/string/inflections'

# Libs
module Rust
  require_relative 'rust_require/version.rb'
end

require_relative 'rust_require/rust_require.rb'
require_relative 'rust_require/rustc.rb'
require_relative 'rust_require/types.rb'
require_relative 'rust_require/c_wrapper_generator.rb'
require_relative 'rust_require/ruby_wrapper_generator.rb'
require_relative 'rust_require/struct.rb'


# Types
require_relative 'rust_require/types/primitives.rb'

# deactivated for now, maybe reactivated later with explicit conversion
# require_relative 'rust_require/types/string.rb'

class Module
  def rust_require(file)
    Rust.require_rust_file(file, self)
  end
end
