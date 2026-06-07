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

  describe "standard bitmap mode through a bad-line DMA fetch" do
    let(:raster) { 52 }
    let(:col) { 10 }

    before do
      vic.poke(0xd018, 0x18) # screen matrix @ $0400, bitmap @ $2000
      vic.poke(0xd011, 0x3b) # DEN=1, BMM=1, RSEL=1, YSCROLL=3
    end

    def render_col
      ((raster + 1) * 63).times { vic.cycle! }
      vic.display[(raster * vic.width) + ((col + 16) * 8), 8]
    end

    it "draws the high nibble for set bits and the low nibble for clear bits" do
      vic.address_bus.ram.poke(0x0400 + col, 0x4a) # fg 4, bg 10
      vic.address_bus.ram.poke(0x2000 + (col * 8) + 1, 0b1000_0001)
      expect(render_col).to eq([4, 10, 10, 10, 10, 10, 10, 4])
    end
  end

  describe "multicolour bitmap mode through a bad-line DMA fetch" do
    let(:raster) { 52 }
    let(:col) { 10 }

    before do
      vic.poke(0xd018, 0x18) # screen matrix @ $0400, bitmap @ $2000
      vic.poke(0xd011, 0x3b) # DEN=1, BMM=1, RSEL=1, YSCROLL=3
      vic.poke(0xd016, 0xd8) # MCM=1, CSEL=40, XSCROLL=0
      vic.poke(0xd021, 6)    # background 0
    end

    def render_col
      ((raster + 1) * 63).times { vic.cycle! }
      vic.display[(raster * vic.width) + ((col + 16) * 8), 8]
    end

    # pairs: 00->bg0(6) 01->matrix high(3) 10->matrix low(5) 11->colour RAM(9)
    it "decodes pairs from background, video-matrix nibbles and colour RAM" do
      vic.address_bus.ram.poke(0x0400 + col, 0x35)
      vic.address_bus.color_ram.poke(0xd800 + col, 9)
      vic.address_bus.ram.poke(0x2000 + (col * 8) + 1, 0b00_01_10_11)
      expect(render_col).to eq([6, 6, 3, 3, 5, 5, 9, 9])
    end
  end

  describe "sprite rendering through a full raster" do
    let(:line) { 60 }
    let(:sprite_x) { 100 }
    let(:raster_x) { sprite_x + Ruby64::VIC::Sprite::X_OFFSET }

    before do
      vic.poke(0xd018, 0x18) # screen matrix @ $0400 -> pointers @ $07f8
      vic.poke(0xd011, 0x1b) # DEN=1, RSEL=1, YSCROLL=3
      vic.poke(0xd015, 0x01) # enable sprite 0
      vic.poke(0xd000, sprite_x)
      vic.poke(0xd001, line)
      vic.poke(0xd027, 5)    # sprite 0 colour
      vic.address_bus.ram.poke(0x07f8, 0x80)        # sprite 0 data @ $2000
      vic.address_bus.ram.poke(0x2000, 0b1000_0000) # row 0, leftmost pixel set
    end

    def run_to(target)
      ((target + 1) * 63).times { vic.cycle! }
    end

    it "draws the sprite pixel into the display at its raster position" do
      run_to(line)
      expect(vic.display[(line * vic.width) + raster_x]).to eq(5)
    end

    it "does not draw the sprite on lines outside its 21-row span" do
      run_to(line + 21)
      expect(vic.display[((line + 21) * vic.width) + raster_x]).not_to eq(5)
    end

    it "places the sprite using the 9th X bit from $D010" do
      vic.poke(0xd000, 20)
      vic.poke(0xd010, 0x01) # X = 276
      run_to(line)
      expect(vic.display[(line * vic.width) + (276 + Ruby64::VIC::Sprite::X_OFFSET)])
        .to eq(5)
    end

    it "hides a sprite behind the side border" do
      vic.poke(0xd000, 0)
      run_to(line)
      expect(vic.display[(line * vic.width) + 104]).to eq(14)
    end
  end

  describe "sprite collision IRQ through a full raster" do
    let(:line) { 60 }

    before do
      vic.poke(0xd018, 0x18)
      vic.poke(0xd011, 0x1b)
      vic.poke(0xd01a, 0x06) # enable sprite-sprite and sprite-data IRQs
      vic.poke(0xd015, 0x03) # enable sprites 0 and 1
      vic.poke(0xd000, 100)
      vic.poke(0xd001, line)
      vic.poke(0xd002, 100)  # sprite 1 at the same position
      vic.poke(0xd003, line)
      vic.address_bus.ram.poke(0x07f8, 0x80) # both point at $2000
      vic.address_bus.ram.poke(0x07f9, 0x80)
      vic.address_bus.ram.poke(0x2000, 0b1000_0000)
    end

    it "raises a sprite-sprite collision and asserts the IRQ line" do
      ((line + 1) * 63).times { vic.cycle! }
      aggregate_failures do
        expect(vic.peek(0xd01e) & 0x03).to eq(0x03)
        expect(vic.interrupted?).to be(true)
      end
    end

    it "detects a collision in the side border, outside the display window" do
      vic.poke(0xd000, 420) # raster X 20 (left border, off the visible crop)
      vic.poke(0xd002, 420)
      ((line + 1) * 63).times { vic.cycle! }
      expect(vic.peek(0xd01e) & 0x03).to eq(0x03)
    end
  end

  describe "sprite-data collision under the 38-column border" do
    let(:line) { 52 }

    before do
      vic.poke(0xd018, 0x18) # screen @ $0400, char @ $2000, ptrs @ $07f8
      vic.poke(0xd011, 0x1b) # DEN=1, RSEL=1, YSCROLL=3
      vic.poke(0xd016, 0xc0) # CSEL=38 (column 0 falls under the border)
      vic.poke(0xd015, 0x01) # enable sprite 0
      vic.poke(0xd000, 24)   # sprite X 24 -> raster 128 (column 0)
      vic.poke(0xd001, line)
      ram = vic.address_bus.ram
      ram.poke(0x0400, 1)              # column 0 shows character 1
      ram.poke(0x2000 + 8 + 1, 0x80)   # char 1, row 1: foreground at pixel 0
      ram.poke(0x07f8, 0x90)           # sprite 0 data @ $2400
      ram.poke(0x2400, 0x80)           # sprite row 0: pixel 0 set
    end

    it "sets the sprite-data collision register" do
      ((line + 1) * 63).times { vic.cycle! }
      expect(vic.peek(0xd01f) & 0x01).to eq(0x01)
    end

    it "still shows the border colour over the collision" do
      ((line + 1) * 63).times { vic.cycle! }
      expect(vic.display[(line * vic.width) + 128]).to eq(14)
    end
  end

  describe "#dma_active?" do
    subject { vic.dma_active? }

    let(:rasterline) { 59 }
    let(:rasterline_cycle) { 20 }
    let(:d011) { 0x1b } # DEN=1, RSEL=1, YSCROLL=3

    before do
      vic.poke(0xd011, d011)
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

    context "when display was disabled during raster line $30" do
      let(:d011) { 0x0b } # DEN=0 from power-on, so the bad-line latch never sets

      it { is_expected.to be(false) }
    end
  end

  describe "FLD: withholding bad lines opens an idle gap" do
    let(:bg) { 6 }
    let(:fg) { 1 }
    let(:cell) { 10 }
    let(:gap_line) { 80 } # well inside the display area

    before do
      vic.poke(0xd018, 0x18) # screen @ $0400, char @ $2000
      vic.poke(0xd011, 0x1b) # DEN=1, RSEL=1, YSCROLL=3
      vic.poke(0xd021, bg)
      ram = vic.address_bus.ram
      256.times { |i| ram.poke(0x0400 + i, 1) }      # screen full of char 1
      8.times { |r| ram.poke(0x2000 + 8 + r, 0xff) } # char 1 solid in every row
      vic.address_bus.color_ram.poke(0xd800 + cell, fg)
    end

    it "renders the gap line as background, not character graphics" do
      # Run normally up to the first bad line, then keep YSCROLL mismatched so no
      # further bad line occurs and the chip slips into idle state.
      (0..gap_line).each do |line|
        vic.poke(0xd011, 0x18 | ((line + 1) & 0b111)) if line > 52
        63.times { vic.cycle! }
      end

      expect(vic.display[(gap_line * vic.width) + ((16 + cell) * 8)]).to eq(bg)
    end
  end
end
