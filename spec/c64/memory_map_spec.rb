require "spec_helper"

describe C64::MemoryMap do
  let(:memory_map) { C64::MemoryMap.new }

  it "should initialize with 0xff and 0x07 as the first bytes" do
    expect(memory_map[0x0000]).to eq(0xff)
    expect(memory_map[0x0001]).to eq(0x07)
  end

  it "should overlay the ROM" do
    expect(memory_map[0xa000]).to eq(0x94)
  end

  it "should write to the underlying RAM" do
    memory_map[0xa000] = 0x20
    expect(memory_map[0xa000]).to eq(0x94)
    memory_map[0x0001] = 0 # Disables all overlays
    expect(memory_map[0xa000]).to eq(0x20)
  end
end
