require_relative '../lib/rust_require'

describe Rust do
  before :each do
    # delete the subfolder
    `rm -rf specs/.rust_require`
  end

  describe "#rust_require" do
    it "should support primitive rust types" do
      class Test
        rust_require './specs/primitives.rs'
      end

      t = Test.new
      expect(t.test_nil).to eq nil
      expect(t.test_bool true).to eq true

      expect(t.test_int -1).to eq -1
      expect(t.test_uint 1).to eq 1

      %w[8 16 32 64].each do |n|
        # test the limits
        max_uint = 2 ** n.to_i - 1
        max_int  = 2 ** (n.to_i - 1) - 1

        expect(t.send "test_" << 'u'+n, max_uint).to eq max_uint
        expect(t.send "test_" << 'i'+n, max_int).to eq max_int
        expect(t.send "test_" << 'i'+n, -max_int).to eq -max_int
      end

      # f32 is inexact, so just test that the difference is smaller than the input precision
      expect((t.test_f32(3.1234567) - 3.1234567).abs).to be < 0.0000001
      expect(t.test_f64 Math::PI).to eq Math::PI
    end
  end
end
