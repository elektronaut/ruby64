# frozen_string_literal: true

require "spec_helper"

describe Ruby64::MemoryMap do
  let(:memory_map) { described_class.new }

  specify { expect(memory_map[0x0000]).to eq(0xff) }
  specify { expect(memory_map[0x0001]).to eq(0x07) }

  it "overlays the ROM" do
    expect(memory_map[0xa000]).to eq(0x94)
  end

  context "when writing through an overlay" do
    before { memory_map[0xa000] = 0x20 }

    specify { expect(memory_map[0xa000]).to eq(0x94) }

    context "when the overlays are disabled" do
      # Disables all overlays
      before { memory_map.disable_overlays! }

      specify { expect(memory_map[0xa000]).to eq(0x20) }
    end
  end
end
