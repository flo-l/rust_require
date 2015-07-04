require_relative '../lib/rust_require'

describe Rust do
  before :each do
    # delete the subfolder
    `rm -rf specs/.rust_require`
  end

  describe "#rust_require(Modules)" do
    it "should import the module hierachy of rust files" do
      class TestModules
        rust_require './specs/modules.rs'
        include SubModule::SubSubModule
      end

      expect(TestModules.constants).to include(:SubModule)
      expect(TestModules.constants).to include(:ExternalFileModule)
      expect(TestModules.constants).to include(:ExternalDirModule)
      expect(TestModules.constants).to_not include(:InvisibleModule)
      expect(TestModules::SubModule.constants).to include(:SubSubModule)

      expect(TestModules.new.test).to eq nil
    end
  end
end
