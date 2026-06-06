# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ruby64::VIC::Sequencer do
  subject(:sequencer) { described_class.new(504, registers) }

  let(:registers) { Ruby64::VIC::Registers.new }
  let(:fg) { 1 }
  let(:bg) { 6 }
  let(:col) { 10 }
  let(:x_pos) { (col + 16) * 8 }

  # With the default YSCROLL=3, rasterline 51 falls inside the display window
  # and 10 sits above it; the border colour is set to 2.
  def in_line = 51
  def out_line = 10
  def border = 2

  before do
    registers.write(0x20, border)
    registers.write(0x21, bg)
  end

  # Emit a cell and return its eight rendered pixels (colours).
  def render(char, xscroll: 0, prev: nil, line: in_line)
    registers.write(0x16, 0xc8 | xscroll) # keep CSEL (40 cols), set XSCROLL
    sequencer.emit(prev, fg, col - 1, x_pos - 8, line) if prev
    sequencer.emit(char, fg, col, x_pos, line)
    sequencer.colors[x_pos, 8]
  end

  # The matching foreground-mask for the cell.
  def render_fg(char, **opts)
    render(char, **opts)
    sequencer.fg[x_pos, 8]
  end

  describe "standard text decode" do
    it "draws set bits in the foreground colour" do
      expect(render(0b1000_0001)).to eq([fg, bg, bg, bg, bg, bg, bg, fg])
    end

    it "draws clear bits in the background colour" do
      expect(render(0)).to eq([bg, bg, bg, bg, bg, bg, bg, bg])
    end
  end

  describe "foreground-mask" do
    it "marks set bits as foreground" do
      expect(render_fg(0b1010_0000)).to eq([true, false, true, false,
                                            false, false, false, false])
    end

    it "marks background pixels as not foreground" do
      expect(render_fg(0)).to all(be(false))
    end

    it "marks border pixels as not foreground" do
      expect(render_fg(0xff, line: out_line)).to all(be(false))
    end
  end

  describe "border / window clip" do
    it "renders foreground inside the visible line" do
      expect(render(0xff)).to all(eq(fg))
    end

    it "renders border for a line outside the display window" do
      expect(render(0xff, line: out_line)).to all(eq(border))
    end

    it "renders border for columns outside the horizontal window" do
      registers.write(0x16, 0xc8)             # CSEL=40, XSCROLL=0
      sequencer.emit(0xff, fg, 0, 0, in_line) # x 0 sits in the left border
      expect(sequencer.colors[0, 8]).to all(eq(border))
    end
  end

  describe "fine horizontal scrolling (XSCROLL)" do
    context "with XSCROLL=0" do
      it "draws the cell unshifted" do
        expect(render(0b1000_0000)).to eq([fg, bg, bg, bg, bg, bg, bg, bg])
      end
    end

    context "with XSCROLL=1" do
      it "shifts the cell one pixel to the right" do
        expect(render(0b1000_0000, xscroll: 1))
          .to eq([bg, fg, bg, bg, bg, bg, bg, bg])
      end

      it "bleeds the previous cell into the vacated pixel" do
        # prev cell bit 0 set -> its rightmost pixel fills the leftmost slot
        expect(render(0, prev: 0b0000_0001, xscroll: 1))
          .to eq([fg, bg, bg, bg, bg, bg, bg, bg])
      end
    end

    context "with XSCROLL=7 (maximum)" do
      it "shifts the cell seven pixels to the right" do
        expect(render(0b1000_0000, xscroll: 7))
          .to eq([bg, bg, bg, bg, bg, bg, bg, fg])
      end
    end

    context "when at the left edge of the display (column 0)" do
      let(:col) { 0 }

      it "fills shifted-in pixels with background, ignoring the rolling cell" do
        # Leave a set rightmost pixel in the rolling window, then render
        # column 0: the bleed must be suppressed at the left edge.
        sequencer.emit(0b0000_0001, fg, 39, x_pos - 8, in_line)
        registers.write(0x16, 0xc9) # CSEL=40, XSCROLL=1
        sequencer.emit(0, fg, col, x_pos, in_line)
        expect(sequencer.colors[x_pos]).to eq(bg)
      end
    end

    describe "#new_line" do
      it "clears the rolling window so the next line does not bleed" do
        sequencer.emit(0b0000_0001, fg, col - 1, x_pos - 8, in_line)
        sequencer.new_line
        registers.write(0x16, 0xc9) # CSEL=40, XSCROLL=1
        sequencer.emit(0, fg, col, x_pos, in_line)
        expect(sequencer.colors[x_pos]).to eq(bg)
      end
    end
  end
end
