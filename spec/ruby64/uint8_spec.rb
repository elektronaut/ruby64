# frozen_string_literal: true

require "spec_helper"

describe Ruby64::Uint8 do
  def int(value)
    Ruby64::Uint8.new(value)
  end

  describe "comparing to an integer" do
    specify { expect(int(8) == 8).to eq(true) }
    specify { expect(int(8) == 10).to eq(false) }
    specify { expect(int(8) < 20).to eq(true) }
    specify { expect(int(8) < 8).to eq(false) }
  end

  it "can be added" do
    expect(int(8) + 4).to eq(12)
  end

  it "overflows when added" do
    expect(int(8) + 255).to eq(7)
  end

  it "can be subtracted" do
    expect(int(8) - 2).to eq(6)
  end

  it "overflows when subtracted" do
    expect(int(8) - 9).to eq(0xff)
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
    expect(~int(0b11001100)).to eq(0b00110011)
  end

  it "can be converted to an Integer" do
    expect(int(8).to_i).to be_a(Integer)
  end

  describe "coercion" do
    specify { expect(5 + int(8)).to eq(13) }
    specify { expect(5 + int(8)).to be_a(described_class) }
    specify { expect(int(5) + int(8)).to eq(13) }
    specify { expect(int(5) + int(8)).to be_a(described_class) }
  end

  it "can be inspected" do
    expect(int(10).inspect).to eq("Ruby64::Uint8(0x0a)")
  end

  it "exposes bytes" do
    expect(int(8).bytes).to eq([8])
  end

  describe "accessing bits through the array accessor" do
    specify { expect(int(0b00000010)[0]).to eq(0) }
    specify { expect(int(0b00000010)[1]).to eq(1) }
  end

  describe "#signed" do
    specify { expect(int(127).signed).to eq(127) }
    specify { expect(int(128).signed).to eq(-128) }
    specify { expect(int(255).signed).to eq(-1) }
  end
end
