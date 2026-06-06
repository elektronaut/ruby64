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
      specify { expect(vic.peek(0xd019) & 0x80).to eq(0) }
    end

    context "when IRQ is enabled" do
      before do
        vic.poke(0xd01a, 1)
        vic.poke(0xd012, 50)
        ((50 * 63) + 1).times { vic.cycle! }
      end

      specify { expect(vic.interrupted?).to be(true) }
      specify { expect(vic.peek(0xd019) & 0x01).to eq(1) }
      specify { expect(vic.peek(0xd019) & 0x80).to eq(0x80) }

      it "stays asserted across cycles until acknowledged" do
        100.times { vic.cycle! }
        expect(vic.interrupted?).to be(true)
      end

      it "clears the IRQ flag when writing to it" do
        vic.poke(0xd019, 1)
        expect(vic.peek(0xd019) & 0x01).to eq(0)
      end

      it "releases the line when the flag is acknowledged" do
        vic.poke(0xd019, 1)
        expect(vic.interrupted?).to be(false)
      end

      it "clears the master IRQ bit when acknowledged" do
        vic.poke(0xd019, 1)
        expect(vic.peek(0xd019) & 0x80).to eq(0)
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

  describe "XSCROLL default" do
    it "is zero after reset" do
      expect(vic.peek(0xd016) & 0b0111).to eq(0)
    end
  end

  describe "XSCROLL through a bad-line DMA fetch" do
    # Char row 0 starts at raster 51, which is a bad line. Raster 52
    # reuses the fetched buffers at char-line 1.
    let(:raster) { 52 }
    let(:col) { 10 }
    let(:bg) { 6 }

    before do
      vic.poke(0xd018, 0x18) # video matrix @ $0400, character data @ $2000
      vic.poke(0xd011, 0x1b) # DEN=1, RSEL=1, YSCROLL=3
      vic.poke(0xd021, bg)   # background colour
    end

    def put_char(column, code, color, bits)
      ram = vic.address_bus.ram
      ram.poke(0x0400 + column, code)
      ram.poke(0x2000 + (code * 8) + 1, bits)
      vic.address_bus.color_ram.poke(0xd800 + column, color)
    end

    def render_col(xscroll)
      vic.poke(0xd016, 0xc8 | xscroll) # keep CSEL (40 cols), set XSCROLL
      ((raster + 1) * 63).times { vic.cycle! }
      vic.display[(raster * vic.width) + ((col + 16) * 8), 8]
    end

    it "renders the cell unshifted with XSCROLL=0" do
      put_char(col, 0x01, 1, 0b1000_0000)
      expect(render_col(0)).to eq([1, bg, bg, bg, bg, bg, bg, bg])
    end

    it "shifts the cell one pixel right with XSCROLL=1" do
      put_char(col, 0x01, 1, 0b1000_0000)
      put_char(col - 1, 0x03, bg, 0) # blank left neighbour
      expect(render_col(1)).to eq([bg, 1, bg, bg, bg, bg, bg, bg])
    end

    it "shifts the cell seven pixels right with XSCROLL=7" do
      put_char(col, 0x01, 1, 0b1000_0000)
      put_char(col - 1, 0x03, bg, 0)
      expect(render_col(7)).to eq([bg, bg, bg, bg, bg, bg, bg, 1])
    end

    it "bleeds the left neighbour into the vacated pixel with XSCROLL=1" do
      put_char(col, 0x01, 1, 0) # blank cell
      put_char(col - 1, 0x03, 2, 0b0000_0001) # neighbour's rightmost pixel set
      expect(render_col(1)).to eq([2, bg, bg, bg, bg, bg, bg, bg])
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
      it { is_expected.to be(true) }
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
