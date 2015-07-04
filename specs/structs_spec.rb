require_relative '../lib/rust_require'

describe Rust do
  before :each do
    # delete the subfolder
    `rm -rf specs/.rust_require`
  end

  describe "#rust_require(Structs)" do
    it "should import simple structs" do
      class TestStructs
        rust_require './specs/structs.rs'
      end

      expect(TestStructs.constants).to include(:TestStruct)
      expect(TestStructs::TestStruct.superclass).to be FFI::Struct

      struct = TestStructs::TestStruct.new

      expect{ struct[:a] =  1 }.not_to raise_error
      expect{ struct[:b] = -1 }.not_to raise_error

      expect(struct[:a]).to eq  1
      expect(struct[:b]).to eq -1
    end

    it "should import tuple structs" do
      class TestStructs
        rust_require './specs/structs.rs'
      end

      expect(TestStructs.constants).to include(:TupleStruct)
      expect(TestStructs::TupleStruct.superclass).to be FFI::Struct

      struct = TestStructs::TupleStruct.new

      expect{ struct[:"0"] =  1 }.not_to raise_error
      expect{ struct[:"1"] = -1 }.not_to raise_error

      expect(struct[:"0"]).to eq  1
      expect(struct[:"1"]).to eq -1
    end

    it "should import simple nested structs" do
      class TestNestedStructs
        rust_require './specs/structs.rs'
      end

      expect(TestNestedStructs.constants).to include(:Nested)
      expect(TestNestedStructs::Nested.constants).to include(:TestStruct)
      expect(TestNestedStructs::Nested::TestStruct.superclass).to be FFI::Struct

      struct = TestNestedStructs::Nested::TestStruct.new

      expect{ struct[:a] =  1 }.not_to raise_error
      expect{ struct[:b] = -1 }.not_to raise_error

      expect(struct[:a]).to eq  1
      expect(struct[:b]).to eq -1
    end
  end
end
