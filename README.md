# rust_require
[![Gem Version](https://badge.fury.io/rb/rust_require.svg)](http://badge.fury.io/rb/rust_require)

### Overview
This gem imports a rust file similar to how ```require``` imports a ruby file. It creates wrappers for all rust functions marked ```pub```, including type conversions for more complex things like strings.

```rust_require``` makes ruby to rust interop completely automatic and convenient (also fast and memory safe).

Internally it makes heavy use of the awesome [```ffi gem```](https://github.com/ffi/ffi/) and should as a result work with all three major ruby implementations.

### Install
    gem install rust_require

### Usage
*script.rb*

    require 'rust_require'
    
    class Calculator
      rust_require 'calc.rs'
    end
    
    c = Calculator.new
    c.add(2,3) # => "2 + 3 = 5"
    c.mul(4,7) # => "4 * 7 = 28"

*calc.rs*

    pub fn add(x:i64, y:i64) -> String { format!("{} + {} = {}", x, y, x+y) }
    pub fn mul(x:i64, y:i64) -> String { format!("{} * {} = {}", x, y, x+y) }

# Features

- Supports rust macros
- Supports free functions
- Imports the whole rust module tree

# Supported types:

- All primitive Integers
