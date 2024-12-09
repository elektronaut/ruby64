# frozen_string_literal: true

require "spec_helper"

describe Ruby64::AddressBus do
  let(:address_bus) { described_class.new }

  specify { expect(address_bus[0x0000]).to eq(0xff) }
  specify { expect(address_bus[0x0001]).to eq(0b00110111) }

  it "overlays the ROM" do
    expect(address_bus[0xa000]).to eq(0x94)
  end

  context "when writing through an overlay" do
    before { address_bus[0xa000] = 0x20 }

    specify { expect(address_bus[0xa000]).to eq(0x94) }

    context "when the overlays are disabled" do
      # Disables all overlays
      before { address_bus.disable_overlays! }

      specify { expect(address_bus[0xa000]).to eq(0x20) }
    end
  end
end
