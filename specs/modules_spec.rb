require_relative '../lib/rust_require'

describe Rust do
  before :each do
    # delete the subfolder
    `rm -rf specs/.rust_require`
  end

  describe "#rust_require(Modules)" do
    it "should import the module hierachy of rust files" do
      class Test
        rust_require './specs/modules.rs'
        include SubModule::SubSubModule
      end

      expect(Test.constants).to include(:SubModule)
      expect(Test.constants).to include(:ExternalFileModule)
      expect(Test.constants).to include(:ExternalDirModule)
      expect(Test::SubModule.constants).to include(:SubSubModule)

      expect(Test.new.test).to eq nil
    end
  end
end
