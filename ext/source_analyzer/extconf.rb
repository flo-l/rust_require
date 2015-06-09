require 'mkmf'

# Stops the installation process if one of these commands is not found in
# $PATH.
find_executable('rustc')
find_executable('rake')

puts `rustc #{File.dirname(__FILE__)}/lib/source_analyzer.rs -o #{File.dirname(__FILE__)}/lib/libsource_analyzer.so`

$makefile_created = true
