# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ruby64::VIC::Sprites do
  subject(:sprites) { described_class.new(registers, bank) }

  let(:registers) { Ruby64::VIC::Registers.new }
  let(:bank) { Ruby64::VIC::Bank.new }
  let(:ram) { bank.address_bus.ram }
  let(:colors) { Array.new(504, 6) } # background
  let(:fg) { Array.new(504, false) }

  # Place sprite `index` at X 100 (raster X 204), Y 60, one set pixel at its
  # left edge (pixel 23), pointing at data block `ptr`.
  def setup_sprite(index, ptr:, color:, priority: false)
    registers.write(0x15, registers[0x15] | (1 << index)) # enable
    registers.write(0x1b, registers[0x1b] | (priority ? (1 << index) : 0))
    registers.write(index * 2, 100)
    registers.write((index * 2) + 1, 60)
    registers.write(0x27 + index, color)
    ram.poke(0x03f8 + index, ptr)
    ram.poke(ptr * 64, 0b1000_0000)
  end

  describe "#composite" do
    before { setup_sprite(0, ptr: 0x20, color: 5) }

    it "draws the sprite pixel over the background" do
      sprites.start_line(60)
      sprites.composite(colors, fg, 200, 8)
      expect(colors[204]).to eq(5)
    end

    it "leaves background untouched where the sprite is transparent" do
      sprites.start_line(60)
      sprites.composite(colors, fg, 200, 8)
      expect(colors[205]).to eq(6)
    end

    it "does nothing when no sprite is displaying" do
      sprites.start_line(0) # before any Y
      expect(sprites).not_to be_active
    end
  end

  describe "sprite/sprite priority" do
    before do
      setup_sprite(0, ptr: 0x20, color: 5)
      setup_sprite(1, ptr: 0x21, color: 7)
      sprites.start_line(60)
    end

    it "shows the lower-numbered sprite on top" do
      sprites.composite(colors, fg, 200, 8)
      expect(colors[204]).to eq(5)
    end
  end

  describe "sprite/foreground priority ($D01B)" do
    before { fg[204] = true } # background pixel is foreground graphics

    it "draws the sprite over foreground when priority is clear" do
      setup_sprite(0, ptr: 0x20, color: 5, priority: false)
      sprites.start_line(60)
      sprites.composite(colors, fg, 200, 8)
      expect(colors[204]).to eq(5)
    end

    it "hides the sprite behind foreground when priority is set" do
      setup_sprite(0, ptr: 0x20, color: 5, priority: true)
      sprites.start_line(60)
      sprites.composite(colors, fg, 200, 8)
      expect(colors[204]).to eq(6)
    end
  end

  describe "sprite/sprite collision ($D01E)" do
    before do
      setup_sprite(0, ptr: 0x20, color: 5)
      setup_sprite(1, ptr: 0x21, color: 7)
      sprites.start_line(60)
      sprites.composite(colors, fg, 200, 8)
    end

    it "sets a bit per colliding sprite" do
      expect(registers.read(0x1e)).to eq(0b11)
    end

    it "latches the sprite-sprite collision IRQ flag" do
      expect(registers[0x19] & 0x04).to eq(0x04)
    end

    it "clears the register on read" do
      registers.read(0x1e)
      expect(registers.read(0x1e)).to eq(0)
    end

    it "does not collide when only one sprite overlaps a pixel" do
      registers.read(0x1e)        # clear the two-sprite collision above
      registers.write(0x15, 0x01) # leave only sprite 0 enabled
      sprites.start_line(60)
      sprites.composite(Array.new(504, 6), fg, 200, 8)
      expect(registers.read(0x1e)).to eq(0)
    end
  end

  describe "sprite/foreground collision ($D01F)" do
    before do
      setup_sprite(0, ptr: 0x20, color: 5)
      sprites.start_line(60)
    end

    it "sets the sprite bit when its pixel overlaps foreground graphics" do
      fg[204] = true
      sprites.composite(colors, fg, 200, 8)
      expect(registers.read(0x1f)).to eq(0b1)
    end

    it "does not collide over background pixels" do
      sprites.composite(colors, fg, 200, 8)
      expect(registers.read(0x1f)).to eq(0)
    end

    it "latches the sprite-data collision IRQ flag" do
      fg[204] = true
      sprites.composite(colors, fg, 200, 8)
      expect(registers[0x19] & 0x02).to eq(0x02)
    end
  end
end
