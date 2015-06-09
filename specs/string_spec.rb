require_relative '../lib/rust_require'

describe Rust do
  before :each do
    # delete the subfolder
    `rm -rf specs/.rust_require`
  end

  describe "#rust_require(strings)" do
    it "should support rust strings" do
      class Test
        rust_require './specs/string.rs'
      end

      t = Test.new
      unicode_str = "ä#aüsfäö#asöä#¼³½¬³2"

      expect(t.compare_string(unicode_str)).to eq true
      expect(t.compare_mut_string(unicode_str)).to eq true

      expect(t.return_string).to eq unicode_str
      expect(t.return_string.encoding).to eq Encoding::UTF_8

      expect(t.pass_string_through(unicode_str)).to eq unicode_str
    end
  end
end
