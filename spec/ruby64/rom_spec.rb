# frozen_string_literal: true
require "spec_helper"

describe Ruby64::ROM do
  let(:memory) { Ruby64::ROM.new }
  let(:basic) { Ruby64::ROM.load("basic.rom", 0xa000) }

  it "should raise an error on write" do
    expect { memory[15] = 20 }.to(
      raise_error(Ruby64::Memory::ReadOnlyMemoryError)
    )
  end

  describe ".load" do
    it "should read the length from the file" do
      expect(basic.length).to eq(8192)
    end

    it "should set the address" do
      expect(basic.start).to eq(0xa000)
    end

    it "should read the contents from the file" do
      expect(basic[0xa000]).to eq(0x94)
      expect(basic[0xa001]).to eq(0xe3)
    end
  end
end
