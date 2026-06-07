# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ruby64::VIC::Sequencer do
  subject(:sequencer) { described_class.new(504, registers, bank) }

  let(:registers) { Ruby64::VIC::Registers.new }
  let(:bank) { Ruby64::VIC::Bank.new }
  let(:col) { 10 }
  let(:x_pos) { (col + 16) * 8 }

  before do
    registers.write(0x20, 2)
    registers.write(0x21, 6)
  end

  def put_char(screencode, bits)
    bank.address_bus.ram.poke(screencode * 8, bits)
  end

  def emit_cell(screencode, bits, at, xscroll: 0)
    registers.write(0x16, 0xc8 | xscroll)
    put_char(screencode, bits)
    sequencer.emit(screencode, 1, at, 51)
  end

  def render(bits, xscroll: 0, prev_bits: nil, line: 51)
    registers.write(0x16, 0xc8 | xscroll) # keep CSEL (40 cols), set XSCROLL
    put_char(1, bits)
    if prev_bits
      put_char(2, prev_bits)
      sequencer.emit(2, 1, col - 1, line)
    end
    sequencer.emit(1, 1, col, line)
    sequencer.colors[x_pos, 8]
  end

  def render_fg(bits, **opts)
    render(bits, **opts)
    sequencer.fg[x_pos, 8]
  end

  describe "standard text decode" do
    it "draws set bits in the foreground colour" do
      expect(render(0b1000_0001)).to eq([1, 6, 6, 6, 6, 6, 6, 1])
    end

    it "draws clear bits in the background colour" do
      expect(render(0)).to eq([6, 6, 6, 6, 6, 6, 6, 6])
    end
  end

  describe "foreground-mask" do
    it "marks set bits as foreground" do
      expect(render_fg(0b1010_0000))
        .to(eq([true, false, true, false, false, false, false, false]))
    end

    it "marks background pixels as not foreground" do
      expect(render_fg(0)).to all(be(false))
    end

    it "marks border pixels as not foreground" do
      expect(render_fg(0xff, line: 10)).to all(be(false))
    end
  end

  describe "border / window clip" do
    it "renders foreground inside the visible line" do
      expect(render(0xff)).to all(eq(1))
    end

    it "renders border for a line outside the display window" do
      expect(render(0xff, line: 10)).to all(eq(2))
    end

    it "renders border for columns outside the horizontal window" do
      registers.write(0x16, 0xc8) # CSEL=40, XSCROLL=0
      put_char(1, 0xff)
      sequencer.emit(1, 1, -16, 51) # column -16 maps to x 0 (border)
      expect(sequencer.colors[0, 8]).to all(eq(2))
    end
  end

  describe "fine horizontal scrolling (XSCROLL)" do
    context "with XSCROLL=0" do
      it "draws the cell unshifted" do
        expect(render(0b1000_0000)).to eq([1, 6, 6, 6, 6, 6, 6, 6])
      end
    end

    context "with XSCROLL=1" do
      it "shifts the cell one pixel to the right" do
        expect(render(0b1000_0000, xscroll: 1))
          .to eq([6, 1, 6, 6, 6, 6, 6, 6])
      end

      it "bleeds the previous cell into the vacated pixel" do
        # prev cell bit 0 set -> its rightmost pixel fills the leftmost slot
        expect(render(0, prev_bits: 0b0000_0001, xscroll: 1))
          .to eq([1, 6, 6, 6, 6, 6, 6, 6])
      end
    end

    context "with XSCROLL=7 (maximum)" do
      it "shifts the cell seven pixels to the right" do
        expect(render(0b1000_0000, xscroll: 7))
          .to eq([6, 6, 6, 6, 6, 6, 6, 1])
      end
    end

    context "when at the left edge of the display (column 0)" do
      let(:col) { 0 }

      it "fills shifted-in pixels with background, ignoring the rolling cell" do
        # A set rightmost pixel in the rolling window must not bleed into the
        # vacated pixel at the left edge (column 0).
        expect(render(0, prev_bits: 0b0000_0001, xscroll: 1).first).to eq(6)
      end
    end

    describe "#new_line" do
      it "clears the rolling window so the next line does not bleed" do
        emit_cell(1, 0b0000_0001, col - 1) # set rightmost pixel in the window
        sequencer.new_line
        emit_cell(2, 0, col, xscroll: 1)
        expect(sequencer.colors[x_pos]).to eq(6)
      end
    end
  end
end
