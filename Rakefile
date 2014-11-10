require 'rake'

desc "Compiles the rustc lint plugin used to parse a .rs file"
task :compile_rustc_plugin do
  puts 'compiling source_analyzer.rs'
  puts `rustc ext/rust_grep_lints/lib/source_analyzer.rs -o ext/rust_grep_lints/lib/libsource_analyzer.so`
end

desc "Runs tests"
task :test do
  puts `rspec specs/`
end

desc "Compiles the rustc plugin and then runs tests"
task :test_complete => [:compile_rustc_plugin, :test]

desc "Compile the rustc plugin by default"
task :default => :compile_rustc_plugin
