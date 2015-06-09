require_relative 'lib/rust_require/version.rb'

Gem::Specification.new do |s|
  s.name        = 'rust_require'
  s.version     = Rust::VERSION
  s.date        = Date.today.iso8601

  s.summary     = 'An automatic rust binding generator'
  s.description = <<-DESC
        A ruby gem that generates bindings to rust files automatically.
        DESC

  s.authors     = ["Florian Lackner"]
  s.email       = 'lacknerflo@gmail.com'

  s.add_dependency('ffi', '~> 1.9')
  s.add_dependency('activesupport', '~> 4.2')
  s.add_development_dependency('rake', '~> 10.4')
  s.add_development_dependency('rspec', '~> 2.99')

  s.files       = ["lib/rust_require.rb"] +
                  ["ext/source_analyzer/lib/libsource_analyzer.so"] +
                  Dir["lib/rust_require/*.rb"] +
                  Dir["lib/rust_require/*/*.rb"] +

  s.extensions << "ext/source_analyzer/extconf.rb"

  s.homepage    = 'https://github.com/flo-l/rust_require'
  s.license     = 'MIT'
end
