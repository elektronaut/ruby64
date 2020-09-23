# frozen_string_literal: true

require "spec_helper"

describe Ruby64::ROM do
  let(:memory) { described_class.new }

  it "raises an error on write" do
    expect { memory[15] = 20 }.to(
      raise_error(Ruby64::Memory::ReadOnlyMemoryError)
    )
  end

  describe ".load" do
    subject(:basic) { described_class.load("basic.rom", 0xa000) }

    specify { expect(basic[0xa000]).to eq(0x94) }
    specify { expect(basic[0xa001]).to eq(0xe3) }

    it "reads the length from the file" do
      expect(basic.length).to eq(8192)
    end

    it "sets the address" do
      expect(basic.start).to eq(0xa000)
    end
  end
end
