# frozen_string_literal: true

require "spec_helper"

describe Ruby64::VICBank do
  subject(:vic_bank) { described_class.new }

  describe ".start" do
    subject { vic_bank.start }

    it { is_expected.to eq(0x0000) }

    context "when CIA2 register is 00" do
      before { vic_bank.address_bus.cia2.poke(0xdd00, 0b00) }

      it { is_expected.to eq(0xc000) }
    end

    context "when CIA2 register is 01" do
      before { vic_bank.address_bus.cia2.poke(0xdd00, 0b01) }

      it { is_expected.to eq(0x8000) }
    end

    context "when CIA2 register is 10" do
      before { vic_bank.address_bus.cia2.poke(0xdd00, 0b10) }

      it { is_expected.to eq(0x4000) }
    end
  end
end
