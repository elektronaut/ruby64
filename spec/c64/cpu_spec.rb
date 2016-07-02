require "spec_helper"

describe C64::CPU do
  let(:addr) { 0xc000 }
  let(:memory) do
    C64::Memory.new.tap do |m|
      m.poke(0xfffc, C64::Uint16.new(addr - 1))
    end
  end
  let(:cpu) { C64::CPU.new(memory) }

  def execute(bytes, steps = 1)
    memory.write(addr, bytes)
    steps.times { cpu.step! }
  end

  describe "BCC" do
    let(:carry) { false }
    let(:offset) { 0x20 }
    before do
      cpu.status.carry = carry
      execute([0x90, offset])
    end

    context "when flag is set" do
      let(:carry) { true }
      it "should not branch" do
        expect(cpu.program_counter).to eq(0xc001)
        expect(cpu.cycles).to eq(2)
      end
    end

    context "when flag is clear" do
      it "should branch" do
        expect(cpu.program_counter).to eq(0xc020)
        expect(cpu.cycles).to eq(3)
      end
    end

    context "branching across page boundary" do
      let(:offset) { C64::Uint8.new(-100) }
      it "should spend an extra cycle" do
        expect(cpu.program_counter).to eq(0xbf9c)
        expect(cpu.cycles).to eq(4)
      end
    end
  end

  describe "BCS" do
    let(:carry) { true }
    let(:offset) { 0x20 }
    before do
      cpu.status.carry = carry
      execute([0xb0, offset])
    end

    context "when flag is clear" do
      let(:carry) { false }
      it "should not branch" do
        expect(cpu.program_counter).to eq(0xc001)
        expect(cpu.cycles).to eq(2)
      end
    end

    context "when flag is set" do
      it "should branch" do
        expect(cpu.program_counter).to eq(0xc020)
        expect(cpu.cycles).to eq(3)
      end
    end

    context "branching across page boundary" do
      let(:offset) { C64::Uint8.new(-100) }
      it "should spend an extra cycle" do
        expect(cpu.cycles).to eq(4)
      end
    end
  end

  describe "BEQ" do
    let(:zero) { true }
    let(:offset) { 0x20 }
    before do
      cpu.status.zero = zero
      execute([0xf0, offset])
    end

    context "when flag is clear" do
      let(:zero) { false }
      it "should not branch" do
        expect(cpu.program_counter).to eq(0xc001)
        expect(cpu.cycles).to eq(2)
      end
    end

    context "when flag is set" do
      it "should branch" do
        expect(cpu.program_counter).to eq(0xc020)
        expect(cpu.cycles).to eq(3)
      end
    end

    context "branching across page boundary" do
      let(:offset) { C64::Uint8.new(-100) }
      it "should spend an extra cycle" do
        expect(cpu.cycles).to eq(4)
      end
    end
  end

  describe "BMI" do
    let(:negative) { true }
    let(:offset) { 0x20 }
    before do
      cpu.status.negative = negative
      execute([0x30, offset])
    end

    context "when negative is clear" do
      let(:negative) { false }
      it "should not branch" do
        expect(cpu.program_counter).to eq(0xc001)
        expect(cpu.cycles).to eq(2)
      end
    end

    context "when negative is set" do
      it "should branch" do
        expect(cpu.program_counter).to eq(0xc020)
        expect(cpu.cycles).to eq(3)
      end
    end

    context "branching across page boundary" do
      let(:offset) { C64::Uint8.new(-100) }
      it "should spend an extra cycle" do
        expect(cpu.cycles).to eq(4)
      end
    end
  end

  describe "BNE" do
    let(:zero) { false }
    let(:offset) { 0x20 }
    before do
      cpu.status.zero = zero
      execute([0xd0, offset])
    end

    context "when flag is set" do
      let(:zero) { true }
      it "should not branch" do
        expect(cpu.program_counter).to eq(0xc001)
        expect(cpu.cycles).to eq(2)
      end
    end

    context "when flag is clear" do
      it "should branch" do
        expect(cpu.program_counter).to eq(0xc020)
        expect(cpu.cycles).to eq(3)
      end
    end

    context "branching across page boundary" do
      let(:offset) { C64::Uint8.new(-100) }
      it "should spend an extra cycle" do
        expect(cpu.cycles).to eq(4)
      end
    end
  end

  describe "BPL" do
    let(:negative) { false }
    let(:offset) { 0x20 }
    before do
      cpu.status.negative = negative
      execute([0x10, offset])
    end

    context "when flag is set" do
      let(:negative) { true }
      it "should not branch" do
        expect(cpu.program_counter).to eq(0xc001)
        expect(cpu.cycles).to eq(2)
      end
    end

    context "when flag is clear" do
      it "should branch" do
        expect(cpu.program_counter).to eq(0xc020)
        expect(cpu.cycles).to eq(3)
      end
    end

    context "branching across page boundary" do
      let(:offset) { C64::Uint8.new(-100) }
      it "should spend an extra cycle" do
        expect(cpu.cycles).to eq(4)
      end
    end
  end

  describe "BVC" do
    let(:overflow) { false }
    let(:offset) { 0x20 }
    before do
      cpu.status.overflow = overflow
      execute([0x50, offset])
    end

    context "when flag is set" do
      let(:overflow) { true }
      it "should not branch" do
        expect(cpu.program_counter).to eq(0xc001)
        expect(cpu.cycles).to eq(2)
      end
    end

    context "when flag is clear" do
      it "should branch" do
        expect(cpu.program_counter).to eq(0xc020)
        expect(cpu.cycles).to eq(3)
      end
    end

    context "branching across page boundary" do
      let(:offset) { C64::Uint8.new(-100) }
      it "should spend an extra cycle" do
        expect(cpu.cycles).to eq(4)
      end
    end
  end

  describe "BVS" do
    let(:overflow) { true }
    let(:offset) { 0x20 }
    before do
      cpu.status.overflow = overflow
      execute([0x70, offset])
    end

    context "when flag is clear" do
      let(:overflow) { false }
      it "should not branch" do
        expect(cpu.program_counter).to eq(0xc001)
        expect(cpu.cycles).to eq(2)
      end
    end

    context "when flag is set" do
      it "should branch" do
        expect(cpu.program_counter).to eq(0xc020)
        expect(cpu.cycles).to eq(3)
      end
    end

    context "branching across page boundary" do
      let(:offset) { C64::Uint8.new(-100) }
      it "should spend an extra cycle" do
        expect(cpu.cycles).to eq(4)
      end
    end
  end

  describe "CLC" do
    before do
      cpu.status.carry = true
      execute([0x18])
    end
    it "should clear the flag" do
      expect(cpu.status.carry?).to eq(false)
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "CLD" do
    before do
      cpu.status.decimal = true
      execute([0xd8])
    end
    it "should clear the flag" do
      expect(cpu.status.decimal?).to eq(false)
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "CLI" do
    before do
      cpu.status.interrupt = true
      execute([0x58])
    end
    it "should clear the flag" do
      expect(cpu.status.interrupt?).to eq(false)
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "CLV" do
    before do
      cpu.status.overflow = true
      execute([0xb8])
    end
    it "should clear the flag" do
      expect(cpu.status.overflow?).to eq(false)
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "DEX" do
    before { execute([0xca]) }
    it "should decrement x by 1" do
      expect(cpu.x).to eq(255)
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "DEY" do
    before { execute([0x88]) }
    it "should decrement y by 1" do
      expect(cpu.y).to eq(255)
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "INX" do
    before { execute([0xe8]) }
    it "should increment x by 1" do
      expect(cpu.x).to eq(1)
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "INY" do
    before { execute([0xc8]) }
    it "should increment y by 1" do
      expect(cpu.y).to eq(1)
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "JMP" do
    context "absolute addressing" do
      before { execute([0x4c, 0x39, 0x05]) }
      it "should update the program counter" do
        expect(cpu.program_counter).to eq(0x0539)
        expect(cpu.cycles).to eq(3)
      end
    end

    context "indirect addressing" do
      before do
        memory.write(0x2120, [0x05, 0x39])
        execute([0x6c, 0x20, 0x21])
      end
      it "should update the program counter" do
        expect(cpu.program_counter).to eq(0x0539)
        expect(cpu.cycles).to eq(5)
      end
    end

    context "indirect addressing (at page boundary)" do
      before do
        memory.write(0x21ff, [0x05, 0x39])
        execute([0x6c, 0xff, 0x21])
      end
      it "should update the program counter" do
        expect(cpu.program_counter).to eq(0x0500)
        expect(cpu.cycles).to eq(5)
      end
    end
  end

  describe "LDA" do
    context "immediate addressing" do
      before { execute([0xa9, 0x40]) }
      it "should set the accumulator" do
        expect(cpu.a).to eq(0x40)
        expect(cpu.cycles).to eq(2)
      end
    end

    context "zeropage addressing" do
      before do
        memory.write(0x20, [0x40])
        execute([0xa5, 0x20])
      end
      it "should set the accumulator" do
        expect(cpu.a).to eq(0x40)
        expect(cpu.cycles).to eq(3)
      end
    end

    context "zeropage_x addressing" do
      before do
        cpu.x = 0x05
        memory.write(0x25, [0x40])
        execute([0xb5, 0x20])
      end
      it "should set the accumulator" do
        expect(cpu.a).to eq(0x40)
        expect(cpu.cycles).to eq(4)
      end
    end

    context "absolute addressing" do
      before do
        memory.write(0x2010, [0x40])
        execute([0xad, 0x10, 0x20])
      end
      it "should set the accumulator" do
        expect(cpu.a).to eq(0x40)
        expect(cpu.cycles).to eq(4)
      end
    end

    context "absolute_x addressing" do
      before do
        cpu.x = 0x01
        memory.write(0x2011, [0x40])
        execute([0xbd, 0x10, 0x20])
      end
      it "should set the accumulator" do
        expect(cpu.a).to eq(0x40)
        expect(cpu.cycles).to eq(4)
      end
    end

    context "absolute_x addressing at page boundary" do
      before do
        cpu.x = 0x03
        memory.write(0x2101, [0x40])
        execute([0xbd, 0xfe, 0x20])
      end
      it "should spend an extra cycle" do
        expect(cpu.a).to eq(0x40)
        expect(cpu.cycles).to eq(5)
      end
    end

    context "absolute_y addressing" do
      before do
        cpu.y = 0x03
        memory.write(0x2101, [0x40])
        execute([0xb9, 0xfe, 0x20])
      end
      it "should set the accumulator" do
        expect(cpu.a).to eq(0x40)
        expect(cpu.cycles).to eq(5)
      end
    end

    context "indirect_x addressing" do
      before do
        cpu.x = 0x03
        memory.write(0x2110, [0x40])
        memory.write(0x05, [0x10, 0x21])
        execute([0xa1, 0x02])
      end
      it "should set the accumulator" do
        expect(cpu.a).to eq(0x40)
        expect(cpu.cycles).to eq(6)
      end
    end

    context "indirect_y addressing" do
      before do
        cpu.y = 0x03
        memory.write(0x2113, [0x40])
        memory.write(0x05, [0x10, 0x21])
        execute([0xb1, 0x05])
      end
      it "should set the accumulator" do
        expect(cpu.a).to eq(0x40)
        expect(cpu.cycles).to eq(5)
      end
    end

    context "indirect_y addressing at page boundary" do
      before do
        cpu.y = 0x03
        memory.write(0x2113, [0x40])
        memory.write(0xff, [0x10, 0x21])
        execute([0xb1, 0xff])
      end
      it "should set the accumulator" do
        expect(cpu.a).to eq(0x40)
        expect(cpu.cycles).to eq(6)
      end
    end
  end

  describe "NOP" do
    before { execute([0xea]) }
    it "should spend 2 cycles" do
      expect(cpu.cycles).to eq(2)
    end
  end
end
