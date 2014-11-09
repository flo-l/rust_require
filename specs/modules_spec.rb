require_relative '../lib/rust_require'

describe Rust do
  before :each do
    # delete the subfolder
    `rm -rf specs/.rust_require`
  end

  describe "#rust_require" do
    it "should support primitive rust types" do

    end
  end
end
