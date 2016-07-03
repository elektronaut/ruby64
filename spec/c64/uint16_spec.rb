require "spec_helper"

describe C64::Uint16 do
  def int(value)
    C64::Uint16.new(value)
  end

  it "is comparable to a Fixnum" do
    expect(int(8) == 8).to eq(true)
    expect(int(8) == 10).to eq(false)
    expect(int(8) < 20).to eq(true)
    expect(int(8) < 8).to eq(false)
  end

  it "can be added" do
    expect(int(8) + 4).to eq(12)
  end

  it "can be added with a Uint18" do
    expect(int(0x2000) + C64::Uint8.new(0x10)).to eq(0x2010)
  end

  it "overflows when added" do
    expect(int(8) + 65535).to eq(7)
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

  it "can be converted to a Fixnum" do
    expect(int(8).to_i).to be_a(Fixnum)
  end

  it "can be inspected" do
    expect(int(10).inspect).to eq("C64::Uint16(0x000a)")
  end

  it "can be constructed from two bytes" do
    expect(C64::Uint16.new(0x39, 0x05)).to eq(0x0539)
  end

  it "exposes bytes" do
    expect(int(1337).bytes).to eq([0x39, 0x05])
  end

  it "exposes the high byte" do
    expect(int(1337).high).to eq(5)
    expect(int(1337).high).to be_a(C64::Uint8)
  end

  it "exposes the low byte" do
    expect(int(1337).low).to eq(57)
    expect(int(1337).low).to be_a(C64::Uint8)
  end

  it "exposes bits through the array accessor" do
    expect(int(0b00000010)[0]).to eq(0)
    expect(int(0b00000010)[1]).to eq(1)
  end
end
