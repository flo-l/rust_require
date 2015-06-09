require 'rake'

desc "Compiles the rustc lint plugin used to parse a .rs file"
task :compile_rustc_plugin do
  puts 'compiling source_analyzer.rs'
  puts `rustc ext/source_analyzer/lib/source_analyzer.rs -o ext/source_analyzer/lib/libsource_analyzer.so`
end

desc "Runs tests"
task :test do
  puts `rspec specs/`
end

desc "Compiles the rustc plugin and then runs tests"
task :test_complete => [:compile_rustc_plugin, :test]

desc "Builds the rust_require gem"
task :build do
  `gem build rust_require.gemspec` 
end

desc "Build the rust_require gem by default"
task :default => :build_gem

desc "Build and install the gem"
task :install => :build do
  `gem install rust_require*.gem`
end
