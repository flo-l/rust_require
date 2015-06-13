require 'rake'

def get_version
  File.read("lib/rust_require/version.rb")
  .match(/VERSION = \"(\d)+\.(\d)+\.(\d)+\"/)[1..3]
  .map(&:to_i)
end

desc "Compiles the rustc lint plugin used to parse a .rs file"
task :compile_rustc_plugin do
  puts 'compiling source_analyzer.rs'
  puts `rustc ext/source_analyzer/lib/source_analyzer.rs -o ext/source_analyzer/lib/libsource_analyzer.so`
end

desc "Compiles the rustc plugin and then runs tests"
task :test_complete => [:compile_rustc_plugin, :test]

desc "Runs tests"
task :test do
  puts `rspec specs/`
end

desc "Increments patch version number"
task :patch do
  mayor,minor,patch = get_version

  File.open("lib/rust_require/version.rb", "w+") do |f|
    f << "VERSION = \"#{mayor}.#{minor}.#{patch+1}\""
  end
end

desc "Builds the rust_require gem"
task :build do
  `gem build rust_require.gemspec` 
end

desc "Build and install the gem"
task :install => :build do
  `gem install rust_require*.gem`
end

desc "Increment patch version, build gem and publish to rubygems"
task "new_patch" => [:patch, :build] do
  `gem publish rust_require-#{get_version.join('.')}.gem`
end

desc "Build the rust_require gem by default"
task :default => :build_gem
