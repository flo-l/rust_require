require_relative '../lib/rust_require'

describe Rust do
  before :each do
    # delete the subfolder
    `rm -rf specs/.rust_require`
  end

  describe "#rust_require(primitives)" do
    it "should support primitive rust types" do
      class Test
        rust_require './specs/primitives.rs'
      end

      t = Test.new
      expect { t.should_not_be_visible }.to raise_error NoMethodError

      expect(t.test_nil).to eq nil
      expect(t.test_bool true).to eq true
      expect(t.test_bool false).to eq false

      # test the limits
      max_uint = 2 ** (FFI::Pointer.size*8) - 1
      max_int  = 2 ** (FFI::Pointer.size*8 - 1) - 1

      expect(t.test_uint max_uint).to eq max_uint
      expect(t.test_uint 0).to eq 0
      expect { t.test_uint max_uint+1 }.to raise_error ArgumentError
      expect { t.test_uint -1 }.to raise_error ArgumentError
      expect { t.test_uint 1.0 }.to raise_error ArgumentError
      expect { t.test_uint "1" }.to raise_error ArgumentError

      expect(t.test_int  max_int).to eq  max_int
      expect(t.test_int -max_int).to eq -max_int
      expect { t.test_int  max_int+1 }.to raise_error ArgumentError
      expect { t.test_int -max_int-1 }.to raise_error ArgumentError
      expect { t.test_int 1.0 }.to raise_error ArgumentError
      expect { t.test_int "1" }.to raise_error ArgumentError

      %w[8 16 32 64].each do |n|
        # test the limits
        max_uint = 2 ** n.to_i - 1
        max_int  = 2 ** (n.to_i - 1) - 1

        expect(t.send "test_" << 'u'+n, max_uint).to eq max_uint
        expect(t.send "test_" << 'u'+n, 0).to eq 0
        expect { t.send "test_" << 'u'+n, max_uint+1 }.to raise_error ArgumentError
        expect { t.send "test_" << 'u'+n, -1 }.to raise_error ArgumentError
        expect { t.send "test_" << 'u'+n, 1.0 }.to raise_error ArgumentError
        expect { t.send "test_" << 'u'+n, "1" }.to raise_error ArgumentError


        expect(t.send "test_" << 'i'+n,  max_int).to eq max_int
        expect(t.send "test_" << 'i'+n, -max_int).to eq -max_int
        expect { t.send "test_" << 'i'+n,  max_int+1 }.to raise_error ArgumentError
        expect { t.send "test_" << 'i'+n, -max_int-1 }.to raise_error ArgumentError
        expect { t.send "test_" << 'i'+n, 1.0 }.to raise_error ArgumentError
        expect { t.send "test_" << 'i'+n, "1" }.to raise_error ArgumentError
      end

      # Ruby floats are always f64
      expect(t.test_f32 t.f32_max).to eq t.f32_max
      expect(t.test_f32 t.f32_min).to eq t.f32_min
      expect { t.test_f32 t.f32_max*2 }.to raise_error ArgumentError
      expect { t.test_f32 t.f32_min*2 }.to raise_error ArgumentError

      expect(t.test_f64 Float::MAX).to eq Float::MAX
      expect(t.test_f64 Float::MIN).to eq Float::MIN
      expect { t.test_f64 Float::MAX**2 }.to raise_error ArgumentError
      expect { t.test_f64 Float::MIN**2 }.to raise_error ArgumentError
    end
  end
end
