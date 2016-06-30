require "spec_helper"

describe C64::Memory do
  let(:memory) { C64::Memory.new }

  it "should have a length" do
    expect(memory.length).to eq(65_536)
  end

  it "should be zero filled" do
    expect(memory.peek(0xffff)).to eq(0)
  end

  it "can be read as an array" do
    memory = C64::Memory.new([1, 2, 3])
    expect(memory[2]).to eq(3)
  end

  it "can be written as an array" do
    memory[20] = 15
    expect(memory[20]).to eq(15)
  end

  context "with initial state" do
    let(:memory) { C64::Memory.new([0xff, 0x07]) }

    it "should keep the state" do
      expect(memory.peek(0)).to eq(0xff)
      expect(memory.peek(1)).to eq(0x07)
    end
  end

  context "with a start location" do
    let(:memory) { C64::Memory.new([0xff, 0x07], start: 0x100, length: 2**8) }

    it "should have a range" do
      expect(memory.range).to eq(0x100..0x1ff)
    end

    it "should return bytes at the proper address" do
      expect(memory[0x101]).to eq(0x07)
    end

    it "should raise an error on out of bounds" do
      expect { memory[0x80] }.to raise_error(C64::Memory::OutOfBoundsError)
    end
  end

  describe "#in_range?" do
    let(:memory) { C64::Memory.new(start: 0x100, length: 2**8) }

    it "should return true if address is in range" do
      expect(memory.in_range?(0x1ff)).to eq(true)
    end

    it "should return false if address is not in range" do
      expect(memory.in_range?(0xff)).to eq(false)
    end
  end

  describe "#peek_16" do
    before { memory.poke(0x100, C64::Uint16.new(1337)) }

    it "should read a 16 bit value" do
      expect(memory.peek_16(0x100)).to eq(1337)
    end

    it "should return a Uint16" do
      expect(memory.peek_16(0x100)).to be_a(C64::Uint16)
    end
  end

  describe "#poke" do
    context "with an 8 bit value" do
      before { memory.poke(0x100, 0x80) }
      it "should store the value" do
        expect(memory.peek(0x100)).to eq(0x80)
      end
    end

    context "with a 16 bit value" do
      before { memory.poke(0x100, C64::Uint16.new(0x0539)) }
      it "should store the value" do
        expect(memory.peek(0x100)).to eq(0x05)
        expect(memory.peek(0x101)).to eq(0x39)
      end
    end
  end

  describe "#write and #read" do
    before { memory.write(0x2000, [0x0a, 0x09, 0x08, 0x07]) }
    it "should write the bytes" do
      expect(memory.read(0x2000, 4)).to eq([0x0a, 0x09, 0x08, 0x07])
    end
  end
end
