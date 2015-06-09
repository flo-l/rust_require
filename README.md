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

- Supports free functions
- Imports the whole rust module tree

# Supported types:

- All primitive Integers
- String and &str
