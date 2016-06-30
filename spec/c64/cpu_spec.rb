require "spec_helper"

describe C64::CPU do
  let(:addr) { 0xc000 }
  let(:memory) do
    C64::Memory.new.tap { |m| m.poke(0xfffc, C64::Uint16.new(addr - 1)) }
  end
  let(:cpu) { C64::CPU.new(memory) }

  def execute(bytes, steps = 1)
    memory.write(addr, bytes)
    steps.times { cpu.step! }
  end

  describe "JMP" do
    context "absolute addressing" do
      before { execute([0x4c, 0x05, 0x39]) }
      it "should update the program counter" do
        expect(cpu.program_counter).to eq(1337)
        expect(cpu.cycles).to eq(3)
      end
    end

    context "indirect addressing" do
      before do
        memory.write(0x2120, [0x05, 0x39])
        execute([0x6c, 0x21, 0x20])
      end
      before {  }
      it "should update the program counter" do
        expect(cpu.program_counter).to eq(1337)
        expect(cpu.cycles).to eq(5)
      end
    end

    context "indirect addressing (at page boundary)" do
      before do
        memory.write(0x21ff, [0x05, 0x39])
        execute([0x6c, 0x21, 0xff])
      end
      before {  }
      it "should update the program counter" do
        expect(cpu.program_counter).to eq(0x0500)
        expect(cpu.cycles).to eq(5)
      end
    end
  end
end
