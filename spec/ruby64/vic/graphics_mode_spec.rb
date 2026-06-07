# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ruby64::VIC::GraphicsMode do
  let(:registers) { Ruby64::VIC::Registers.new }
  let(:bank) { Ruby64::VIC::Bank.new }
  let(:sequencer) { Ruby64::VIC::Sequencer.new(504, registers, bank) }

  def put_char(screencode, bits)
    bank.address_bus.ram.poke(screencode * 8, bits)
  end

  describe Ruby64::VIC::GraphicsMode::Text do
    subject(:mode) { described_class.new }

    before { registers.write(0x21, 6) } # background

    it "draws set bits in the cell colour and clear bits in the background" do
      put_char(1, 0b1000_0001)
      mode.decode(1, 4, 0, 0, sequencer)
      expect(sequencer.cur_colors).to eq([4, 6, 6, 6, 6, 6, 6, 4])
    end

    it "marks set bits as foreground" do
      put_char(1, 0b1000_0001)
      mode.decode(1, 4, 0, 0, sequencer)
      expect(sequencer.cur_fg)
        .to(eq([true, false, false, false, false, false, false, true]))
    end

    it "reads the addressed row of the character" do
      bank.address_bus.ram.poke((1 * 8) + 3, 0b1111_1111) # row 3 all set
      mode.decode(1, 4, 0, 3, sequencer)
      expect(sequencer.cur_colors).to all(eq(4))
    end
  end

  describe Ruby64::VIC::GraphicsMode::MulticolorText do
    subject(:mode) { described_class.new }

    before do
      registers.write(0x21, 6) # background 0
      registers.write(0x22, 5) # background 1
      registers.write(0x23, 4) # background 2
    end

    context "with a single-colour cell (colour bit 3 clear)" do
      before { put_char(1, 0b1000_0000) }

      it "decodes as hi-res using the low three colour bits" do
        mode.decode(1, 0x07, 0, 0, sequencer)
        expect(sequencer.cur_colors).to eq([7, 6, 6, 6, 6, 6, 6, 6])
      end

      it "marks the set bit as foreground" do
        mode.decode(1, 0x07, 0, 0, sequencer)
        expect(sequencer.cur_fg.first).to be(true)
      end
    end

    context "with a multicolour cell (colour bit 3 set)" do
      # pairs map 00->bg0(6) 01->bg1(5) 10->bg2(4) 11->colour&7, double-wide.
      it "decodes 2-bit pairs into double-wide pixels" do
        put_char(1, 0b00_01_10_11)
        mode.decode(1, 0x08 | 0x02, 0, 0, sequencer) # colour low bits = 2
        expect(sequencer.cur_colors).to eq([6, 6, 5, 5, 4, 4, 2, 2])
      end

      it "marks only the high-bit (10/11) pairs as foreground" do
        put_char(1, 0b00_01_10_11)
        mode.decode(1, 0x08, 0, 0, sequencer)
        expect(sequencer.cur_fg).to eq([false, false, false, false,
                                        true, true, true, true])
      end
    end
  end

  describe Ruby64::VIC::GraphicsMode::ExtendedBackgroundText do
    subject(:mode) { described_class.new }

    before do
      registers.write(0x21, 6) # background 0
      registers.write(0x22, 5) # background 1
      registers.write(0x23, 4) # background 2
      registers.write(0x24, 3) # background 3
    end

    it "draws set bits in the cell colour" do
      put_char(1, 0b1000_0000)
      mode.decode(1, 7, 0, 0, sequencer)
      expect(sequencer.cur_colors).to eq([7, 6, 6, 6, 6, 6, 6, 6])
    end

    it "selects the background from the top two screencode bits" do
      put_char(1, 0)
      mode.decode(0b1000_0001, 7, 0, 0, sequencer) # bg index 0b10 = 2
      expect(sequencer.cur_colors).to all(eq(4))
    end

    it "addresses the character with the low six bits" do
      put_char(1, 0b1111_1111)
      mode.decode(0b1100_0001, 7, 0, 0, sequencer) # char = screencode & 0x3f = 1
      expect(sequencer.cur_colors).to all(eq(7))
    end

    it "marks set bits as foreground" do
      put_char(1, 0b1000_0000)
      mode.decode(1, 7, 0, 0, sequencer)
      expect(sequencer.cur_fg.first).to be(true)
    end
  end

  describe Ruby64::VIC::GraphicsMode::Bitmap do
    subject(:mode) { described_class.new }

    # $D018 default screen_base bits give bitmap_base 0; cell 0 row 0 -> $0000.
    def put_bitmap(cell, row, bits)
      bank.address_bus.ram.poke(registers.bitmap_base + (cell * 8) + row, bits)
    end

    it "draws set bits in the screencode high nibble, clear bits in the low" do
      put_bitmap(0, 0, 0b1000_0001)
      mode.decode(0x4a, 0, 0, 0, sequencer) # fg = 4, bg = 10
      expect(sequencer.cur_colors).to eq([4, 10, 10, 10, 10, 10, 10, 4])
    end

    it "marks set bits as foreground" do
      put_bitmap(0, 0, 0b1000_0001)
      mode.decode(0x4a, 0, 0, 0, sequencer)
      expect(sequencer.cur_fg)
        .to(eq([true, false, false, false, false, false, false, true]))
    end

    it "addresses the bitmap by cell and row" do
      put_bitmap(3, 5, 0b1111_1111)
      mode.decode(0x4a, 0, 3, 5, sequencer)
      expect(sequencer.cur_colors).to all(eq(4))
    end
  end

  describe Ruby64::VIC::GraphicsMode::MulticolorBitmap do
    subject(:mode) { described_class.new }

    before { registers.write(0x21, 6) } # background 0

    def put_bitmap(cell, row, bits)
      bank.address_bus.ram.poke(registers.bitmap_base + (cell * 8) + row, bits)
    end

    # pairs: 00->bg0(6) 01->screencode high nibble 10->low nibble 11->colour RAM
    it "decodes 2-bit pairs into double-wide pixels" do
      put_bitmap(0, 0, 0b00_01_10_11)
      mode.decode(0x35, 9, 0, 0, sequencer) # high=3 low=5 colour RAM=9
      expect(sequencer.cur_colors).to eq([6, 6, 3, 3, 5, 5, 9, 9])
    end

    it "marks only the high-bit (10/11) pairs as foreground" do
      put_bitmap(0, 0, 0b00_01_10_11)
      mode.decode(0x35, 9, 0, 0, sequencer)
      expect(sequencer.cur_fg).to eq([false, false, false, false,
                                      true, true, true, true])
    end

    it "addresses the bitmap by cell and row" do
      put_bitmap(2, 4, 0b11_11_11_11)
      mode.decode(0x00, 9, 2, 4, sequencer)
      expect(sequencer.cur_colors).to all(eq(9))
    end
  end

  describe Ruby64::VIC::GraphicsMode::Null do
    subject(:mode) { described_class.new }

    it "renders black" do
      sequencer.cur_colors.fill(9)
      mode.decode(1, 1, 0, 0, sequencer)
      expect(sequencer.cur_colors).to all(eq(0))
    end

    it "marks nothing as foreground" do
      sequencer.cur_fg.fill(true)
      mode.decode(1, 1, 0, 0, sequencer)
      expect(sequencer.cur_fg).to all(be(false))
    end
  end
end
