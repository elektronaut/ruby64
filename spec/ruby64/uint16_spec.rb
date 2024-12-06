# frozen_string_literal: true

require "spec_helper"

describe Ruby64::Uint16 do
  def int(value)
    Ruby64::Uint16.new(value)
  end

  describe "comparing to an integer" do
    specify { expect(int(8) == 8).to be(true) }
    specify { expect(int(8) == 10).to be(false) }
    specify { expect(int(8) < 20).to be(true) }
    specify { expect(int(8) < 8).to be(false) }
  end

  it "can be added" do
    expect(int(8) + 4).to eq(12)
  end

  it "can be added with a Uint18" do
    expect(int(0x2000) + Ruby64::Uint8.new(0x10)).to eq(0x2010)
  end

  it "overflows when added" do
    expect(int(8) + 65_535).to eq(7)
  end

  it "can be subtracted" do
    expect(int(8) - 2).to eq(6)
  end

  it "overflows when subtracted" do
    expect(int(8) - 9).to eq(0xffff)
  end

  it "can be multiplied" do
    expect(int(8) * 4).to eq(0x20)
  end

  it "can be divided" do
    expect(int(9) / 4).to eq(0x2)
  end

  it "can be bitwise left shifted" do
    expect(int(0b00000001) << 2).to eq(0b00000100)
  end

  it "can be bitwise right shifted" do
    expect(int(0b00000100) >> 2).to eq(0b00000001)
  end

  it "supports bitwise AND" do
    expect(int(0b10101010) & 0b11110000).to eq(0b10100000)
  end

  it "supports bitwise OR" do
    expect(int(0b10101010) | 0b11110000).to eq(0b11111010)
  end

  it "supports bitwise XOR" do
    expect(int(0b10101010) ^ 0b11110000).to eq(0b01011010)
  end

  it "supports bitwise NOT" do
    expect(~int(0b0101010111001100)).to eq(0b1010101000110011)
  end

  it "can be converted to an integer" do
    expect(int(8).to_i).to be_a(Integer)
  end

  it "can be inspected" do
    expect(int(10).inspect).to eq("Ruby64::Uint16(0x000a)")
  end

  it "can be constructed from two bytes" do
    expect(described_class.new(0x39, 0x05)).to eq(0x0539)
  end

  it "exposes bytes" do
    expect(int(1337).bytes).to eq([0x39, 0x05])
  end

  describe "accessing the high byte" do
    specify { expect(int(1337).high).to eq(5) }
    specify { expect(int(1337).high).to be_a(Ruby64::Uint8) }
  end

  describe "accessing the low byte" do
    specify { expect(int(1337).low).to eq(57) }
    specify { expect(int(1337).low).to be_a(Ruby64::Uint8) }
  end

  describe "accessing bits through the array accessor" do
    specify { expect(int(0b00000010)[0]).to eq(0) }
    specify { expect(int(0b00000010)[1]).to eq(1) }
  end
end
