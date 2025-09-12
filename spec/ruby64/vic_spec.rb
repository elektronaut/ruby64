# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ruby64::VIC do
  let(:vic) { described_class.new }

  describe "rasterline" do
    it "starts at rasterline 0" do
      expect(vic.rasterline).to eq(0)
    end

    it "advances to next line after 63 cycles" do
      63.times { vic.cycle! }
      expect(vic.rasterline).to eq(1)
    end

    it "wraps around after 312 lines" do
      (312 * 63).times { vic.cycle! }
      expect(vic.rasterline).to eq(0)
    end

    it "returns current rasterline low 8 bits from 0xd012" do
      (100 * 63).times { vic.cycle! }
      expect(vic.peek(0xd012)).to eq(100)
    end

    context "when rasterline <= 0xff" do
      before { (100 * 63).times { vic.cycle! } }

      specify { expect(vic.peek(0xd011) & 0x80).to eq(0) }
      specify { expect(vic.peek(0xd012)).to eq(100) }
    end

    context "when rasterline > 0xff" do
      before { (300 * 63).times { vic.cycle! } }

      specify { expect(vic.peek(0xd011) & 0x80).to eq(0x80) }
      specify { expect(vic.peek(0xd012)).to eq(44) }
    end
  end

  describe "raster IRQ" do
    context "when IRQ is disabled" do
      before do
        vic.poke(0xd01a, 0)
        vic.poke(0xd012, 50)
        ((50 * 63) + 1).times { vic.cycle! }
      end

      specify { expect(vic.interrupted?).to be(false) }
      specify { expect(vic.peek(0xd019) & 0x01).to eq(1) }
    end

    context "when IRQ is enabled" do
      before do
        vic.poke(0xd01a, 1)
        vic.poke(0xd012, 50)
        ((50 * 63) + 1).times { vic.cycle! }
      end

      specify { expect(vic.interrupted?).to be(true) }
      specify { expect(vic.peek(0xd019) & 0x01).to eq(1) }

      it "clears the IRQ flag when writing to it" do
        vic.poke(0xd019, 1)
        expect(vic.peek(0xd019) & 0x01).to eq(0)
      end
    end

    context "when raster target requires 9 bits using register 0x11" do
      before do
        vic.poke(0xd011, 0x80)
        vic.poke(0xd012, 44)
        vic.poke(0xd01a, 1)
        ((300 * 63) + 1).times { vic.cycle! }
      end

      specify { expect(vic.interrupted?).to be true }
    end
  end

  describe "#dma_active?" do
    subject { vic.dma_active? }

    let(:rasterline) { 59 }
    let(:rasterline_cycle) { 20 }

    before do
      vic.poke(0xd011, 0x1b) # DEN=1, RSEL=1, YSCROLL=3
      vic.poke(0xd016, 0x08) # Text mode
      ((rasterline * 63) + rasterline_cycle).times { vic.cycle! }
    end

    context "when before the display area" do
      let(:rasterline) { 35 }

      it { is_expected.to be(false) }
    end

    context "when after the display area" do
      let(:rasterline) { 259 }

      it { is_expected.to be(false) }
    end

    context "when on a bad line during the DMA period" do
      xit { is_expected.to be(true) }
    end

    context "when on a bad line outside the DMA period" do
      let(:rasterline_cycle) { 10 }

      it { is_expected.to be(false) }
    end

    context "when not on a bad line" do
      let(:rasterline) { 50 }

      it { is_expected.to be(false) }
    end

    context "when display is disabled" do
      before { vic.poke(0xd011, 0x0b) }

      it { is_expected.to be(false) }
    end
  end
end
