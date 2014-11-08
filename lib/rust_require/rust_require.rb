module Rust
  # Hash to keep record of already required files
  ALREADY_REQUIRED = Hash.new(false)

  # This should compile 'file_name' with rustc,
  # generate rust-to-c wrappers and finally
  # make as much as possible available
  # in Module 'mod' as ruby objects/methods.

  # file_path: String (path to .rs file)
  # mod: Module/Class (Module which requires the .rs file)
  def self.require_rust_file(file_path, mod)
    # type check haha
    check_file file_path

    # make the path absolute
    file_path = File.absolute_path file_path

    # check if the file was already required by mod
    return if already_required? [file_path,mod]

    register_file [file_path,mod]

    # create .rust_require/#{file_name} subfolder
    subdir = create_subfolder(file_path)

    # TODO: insert check for unmodified input here

    # location of info.json
    info_file_path = "#{subdir}/info.json"

    # Use Rustc to create wrappers and compile the file + wrappers
    rustc = Rustc.new(file_path)
    rustc.subdir         = subdir
    rustc.info_file_path = info_file_path
    rustc.output_path    = "#{subdir}/lib#{File.basename(file_path, '.rs')}.so"

    info_file = rustc.create_wrapper
    rustc.compile

    # Use RubyWrapperGenerator to make items from the compiled
    # lib available in mod
    gen = RubyWrapperGenerator.new
    gen.info_file = info_file
    gen.rust_lib  = rustc.output_path
    gen.include_lib(mod)

    true #explicit return value
  end

  private

  # This checks if file_name is a valid .rs file
  def self.check_file(file_path)
    raise ArgumentError, 'input must be a String object' unless file_path.is_a? String
    raise LoadError, 'file #{file_name} not found'       unless File.exists? file_path
    raise NameError, 'input file must be a .rs file'     unless file_path.end_with? '.rs'
  end

  # checks if the file/mod combination has already been required
  def self.already_required?(comb)
    ALREADY_REQUIRED[comb]
  end

  # registers a file/mod combination as 'already_required'
  def self.register_file(comb)
    ALREADY_REQUIRED[comb] = true
  end

  # This creates a subfolder '.rust_require/#{file_name}'
  # to store intermediate files to cache compilation results
  def self.create_subfolder(file_path)
    # file name without .rs extension
    file_name = File.basename(file_path, '.rs')

    # path of dir containing file_name
    dir_name = File.dirname(file_path)

    # path of the dirs to be created
    new_dir_paths = []
    new_dir_paths << "#{dir_name}/.rust_require"
    new_dir_paths << "#{dir_name}/.rust_require/#{file_name}"

    new_dir_paths.each do |path|
      unless Dir.exists? path
        # mkdir with permissions: rwx-rx-r
        Dir.mkdir path, 0754
      end
    end

    # return the newly created dir path
    new_dir_paths[1]
  end
end
