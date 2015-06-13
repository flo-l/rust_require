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

      strings = ["", "Hello, Ascii!", "ä#aüsfäö#asöä#¼³½¬³2"]
      t = Test.new

      strings.each_with_index do |str, i|
        expect(t.compare_string(    str,i)).to eq true
        expect(t.compare_mut_string(str,i)).to eq true

        expect(t.return_string(i)).to eq str
        expect(t.return_string(i).encoding).to eq Encoding::UTF_8

        expect(t.pass_string_through(str)).to eq str
      end
    end
  end
end
