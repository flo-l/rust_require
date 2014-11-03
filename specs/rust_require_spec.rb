require_relative '../lib/rust_require'

describe Rust do
  before :each do
    # delete the subfolder
    `rm -rf specs/.rust_require`
  end

  describe "#rust_require" do
    it "should support primitive rust types" do
      module Test
        rust_require './specs/primitives.rs'

        expect(test_nil nil).to eq nil
        expect(test_bool true).to eq true

        expect(test_int 2).to eq 4
        expect(test_uint 2).to eq 4

        %w[8 16 32 64].map { |n| ["i" << n, "u" << n]  }.flatten.each do |type|
          # call eg. test_i8(2)
          expect(send "test_" << type, 2).to eq 4
        end

        expect(test_f32 Math::PI).to eq Math::PI
        expect(test_f64 Math::PI).to eq Math::PI
      end
    end
  end
end
