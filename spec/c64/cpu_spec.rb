require "spec_helper"

describe C64::CPU do
  let(:start_addr) { C64::Uint16.new(0xc000) }
  let(:memory) do
    C64::Memory.new.tap do |m|
      m.poke(0xfffc, start_addr)
    end
  end
  let(:cpu) { C64::CPU.new(memory) }

  def execute(bytes, steps = 1)
    memory.write(start_addr, bytes)
    steps.times { cpu.step! }
  end

  describe "ADC" do
    it "should add the values" do
      cpu.a = 0x01
      execute([0x69, 0x01])
      expect(cpu.a).to eq(0x02)
      expect(cpu.status.carry?).to eq(false)
      expect(cpu.status.overflow?).to eq(false)
      expect(cpu.cycles).to eq(2)
    end

    it "should include the carry bit" do
      cpu.a = 0x01
      cpu.status.carry = true
      execute([0x69, 0x01])
      expect(cpu.a).to eq(0x03)
      expect(cpu.status.carry?).to eq(false)
      expect(cpu.status.overflow?).to eq(false)
    end

    it "should set the carry bit rolling over" do
      cpu.a = 0xff
      execute([0x69, 0x01])
      expect(cpu.a).to eq(0x00)
      expect(cpu.status.carry?).to eq(true)
      expect(cpu.status.overflow?).to eq(false)
    end

    it "should set the overflow bit" do
      cpu.a = -128
      execute([0x69, -1])
      expect(cpu.status.overflow?).to eq(true)
    end
  end

  describe "AND" do
    before do
      cpu.a = 0b00001111
      execute([0x29, 0b10101010])
    end
    it "should do a bitwise AND on the accumulator" do
      expect(cpu.a).to eq(0b00001010)
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "ASL" do
    context "with accumulator addressing" do
      before do
        cpu.a = 0b11111111
        execute([0x0a])
      end
      it "should rotate the accumulator" do
        expect(cpu.a).to eq(0b11111110)
        expect(cpu.status.carry?).to eq(true)
        expect(cpu.cycles).to eq(2)
      end
    end

    context "with carry bit" do
      before do
        cpu.status.carry = 1
        cpu.a = 0b01010101
        execute([0x0a])
      end
      it "should rotate the accumulator" do
        expect(cpu.a).to eq(0b10101010)
        expect(cpu.status.carry?).to eq(false)
      end
    end
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
        expect(cpu.program_counter).to eq(0xc002)
        expect(cpu.cycles).to eq(2)
      end
    end

    context "when flag is clear" do
      it "should branch" do
        expect(cpu.program_counter).to eq(0xc022)
        expect(cpu.cycles).to eq(3)
      end
    end

    context "branching across page boundary" do
      let(:offset) { C64::Uint8.new(-100) }
      it "should spend an extra cycle" do
        expect(cpu.program_counter).to eq(0xbf9e)
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
        expect(cpu.program_counter).to eq(0xc002)
        expect(cpu.cycles).to eq(2)
      end
    end

    context "when flag is set" do
      it "should branch" do
        expect(cpu.program_counter).to eq(0xc022)
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
        expect(cpu.program_counter).to eq(0xc002)
        expect(cpu.cycles).to eq(2)
      end
    end

    context "when flag is set" do
      it "should branch" do
        expect(cpu.program_counter).to eq(0xc022)
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

  describe "BIT" do
    context "zeropage addressing" do
      before do
        memory.poke(0x20, 0b11000000)
        execute([0x24, 0x20])
      end
      it "should set the bits" do
        expect(cpu.status.negative?).to eq(true)
        expect(cpu.status.overflow?).to eq(true)
        expect(cpu.status.zero?).to eq(true)
        expect(cpu.cycles).to eq(3)
      end
    end

    context "absolute addressing" do
      before do
        cpu.a = 1
        memory.poke(0x2010, 0b00000001)
        execute([0x2c, 0x10, 0x20])
      end
      it "should set the bits" do
        expect(cpu.status.negative?).to eq(false)
        expect(cpu.status.overflow?).to eq(false)
        expect(cpu.status.zero?).to eq(false)
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
        expect(cpu.program_counter).to eq(0xc002)
        expect(cpu.cycles).to eq(2)
      end
    end

    context "when negative is set" do
      it "should branch" do
        expect(cpu.program_counter).to eq(0xc022)
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
        expect(cpu.program_counter).to eq(0xc002)
        expect(cpu.cycles).to eq(2)
      end
    end

    context "when flag is clear" do
      it "should branch" do
        expect(cpu.program_counter).to eq(0xc022)
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
        expect(cpu.program_counter).to eq(0xc002)
        expect(cpu.cycles).to eq(2)
      end
    end

    context "when flag is clear" do
      it "should branch" do
        expect(cpu.program_counter).to eq(0xc022)
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

  describe "BRK" do
    before do
      execute([0x00])
    end
    it "should set the break flag" do
      expect(cpu.status.break?).to eq(true)
    end
    it "should take 7 cycles" do
      expect(cpu.cycles).to eq(7)
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
        expect(cpu.program_counter).to eq(0xc002)
        expect(cpu.cycles).to eq(2)
      end
    end

    context "when flag is clear" do
      it "should branch" do
        expect(cpu.program_counter).to eq(0xc022)
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
        expect(cpu.program_counter).to eq(0xc002)
        expect(cpu.cycles).to eq(2)
      end
    end

    context "when flag is set" do
      it "should branch" do
        expect(cpu.program_counter).to eq(0xc022)
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

  describe "CMP" do
    before do
      cpu.a = 0x60
      execute([0xc9, 0x40])
    end
    it "should set the flags" do
      expect(cpu.status.carry?).to eq(true)
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "CPX" do
    before do
      cpu.x = 0x60
      execute([0xe0, 0x40])
    end
    it "should set the flags" do
      expect(cpu.status.carry?).to eq(true)
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "CPY" do
    before do
      cpu.y = 0x60
      execute([0xc0, 0x40])
    end
    it "should set the flags" do
      expect(cpu.status.carry?).to eq(true)
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "DEC" do
    before { memory.poke(target_addr, 0x40) }

    describe "zeropage addressing" do
      let(:target_addr) { 0x20 }
      before { execute([0xc6, target_addr]) }
      it "should decrement the value" do
        expect(memory.peek(target_addr)).to eq(0x3f)
        expect(cpu.cycles).to eq(5)
      end
    end

    describe "zeropage_x addressing" do
      let(:target_addr) { 0x22 }
      before do
        cpu.x = 2
        execute([0xd6, 0x20])
      end
      it "should decrement the value" do
        expect(memory.peek(target_addr)).to eq(0x3f)
        expect(cpu.cycles).to eq(6)
      end
    end

    describe "absolute addressing" do
      let(:target_addr) { 0x2010 }
      before { execute([0xce, 0x10, 0x20]) }
      it "should decrement the value" do
        expect(memory.peek(target_addr)).to eq(0x3f)
        expect(cpu.cycles).to eq(6)
      end
    end

    describe "absolute_x addressing" do
      let(:target_addr) { 0x2012 }
      before do
        cpu.x = 2
        execute([0xde, 0x10, 0x20])
      end
      it "should decrement the value" do
        expect(memory.peek(target_addr)).to eq(0x3f)
        expect(cpu.cycles).to eq(7)
      end
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

  describe "EOR" do
    before do
      cpu.a = 0b00001111
      execute([0x49, 0b10101010])
    end
    it "should do a bitwise AND on the accumulator" do
      expect(cpu.a).to eq(0b10100101)
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "INC" do
    before do
      memory.poke(0x20, 0x40)
      execute([0xe6, 0x20])
    end
    it "should increment the value" do
      expect(memory.peek(0x20)).to eq(0x41)
      expect(cpu.cycles).to eq(5)
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

  describe "JSR" do
    before { execute([0x20, 0x10, 0x20]) }
    it "should jump to the subroutine" do
      expect(cpu.program_counter).to eq(0x2010)
      expect(cpu.cycles).to eq(6)
    end

    it "should store the address on the stack" do
      expect(memory.peek_16(0x01fe)).to eq(0xc003)
      expect(cpu.stack_pointer).to eq(0xfd)
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

  describe "LDX" do
    before { execute([0xa2, 0x40]) }
    it "should set the accumulator" do
      expect(cpu.x).to eq(0x40)
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "LDY" do
    before { execute([0xa0, 0x40]) }
    it "should set the accumulator" do
      expect(cpu.y).to eq(0x40)
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "LSR" do
    context "with accumulator addressing" do
      before do
        cpu.a = 0b11111110
        execute([0x4a])
      end
      it "should rotate the accumulator" do
        expect(cpu.a).to eq(0b01111111)
        expect(cpu.status.carry?).to eq(false)
        expect(cpu.cycles).to eq(2)
      end
    end

    context "with carry bit" do
      before do
        cpu.status.carry = 1
        cpu.a = 0b01010101
        execute([0x4a])
      end
      it "should rotate the accumulator" do
        expect(cpu.a).to eq(0b00101010)
        expect(cpu.status.carry?).to eq(true)
      end
    end
  end

  describe "NOP" do
    before { execute([0xea]) }
    it "should spend 2 cycles" do
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "ORA" do
    context "immediate addressing" do
      before do
        cpu.a = 0b00001111
        execute([0x09, 0b10101010])
      end
      it "should do a bitwise AND on the accumulator" do
        expect(cpu.a).to eq(0b10101111)
        expect(cpu.cycles).to eq(2)
      end
    end

    context "zeropage addressing" do
      before do
        memory.poke(0xbd, 0b10101010)
        cpu.a = 0b00001111
        execute([0x05, 0xbd])
      end
      it "should do a bitwise AND on the accumulator" do
        expect(cpu.a).to eq(0b10101111)
        expect(cpu.cycles).to eq(3)
      end
    end
  end

  describe "PHA" do
    before do
      cpu.a = 0x40
      execute([0x48])
    end
    it "should push the accumulator on the stack" do
      expect(memory.peek(0x01ff)).to eq(0x40)
      expect(cpu.stack_pointer).to eq(0xfe)
      expect(cpu.cycles).to eq(3)
    end
  end

  describe "PHP" do
    before do
      cpu.p = 0b10101010
      execute([0x08])
    end
    it "should push the processor status on the stack" do
      expect(memory.peek(0x01ff)).to eq(0b10101010)
      expect(cpu.stack_pointer).to eq(0xfe)
      expect(cpu.cycles).to eq(3)
    end
  end

  describe "PLA" do
    before do
      memory.poke(0x01ff, 0x20)
      cpu.stack_pointer = 0xfe
      execute([0x68])
    end
    it "should pull the accumulator from the stack" do
      expect(cpu.a).to eq(0x20)
      expect(cpu.stack_pointer).to eq(0xff)
      expect(cpu.cycles).to eq(4)
    end
  end

  describe "PLP" do
    before do
      memory.poke(0x01ff, 0b10101010)
      cpu.stack_pointer = 0xfe
      execute([0x28])
    end
    it "should pull the processor status from the stack" do
      expect(cpu.p).to eq(0b10101010)
      expect(cpu.stack_pointer).to eq(0xff)
      expect(cpu.cycles).to eq(4)
    end
  end

  describe "ROL" do
    context "with accumulator addressing" do
      before do
        cpu.a = 0b11111111
        execute([0x2a])
      end
      it "should rotate the accumulator" do
        expect(cpu.a).to eq(0b11111110)
        expect(cpu.status.carry?).to eq(true)
        expect(cpu.cycles).to eq(2)
      end
    end

    context "with carry bit" do
      before do
        cpu.status.carry = 1
        cpu.a = 0b10101010
        execute([0x2a])
      end
      it "should rotate the accumulator" do
        expect(cpu.a).to eq(0b01010101)
        expect(cpu.status.carry?).to eq(true)
      end
    end

    context "with zeropage addressing" do
      before do
        memory.poke(0x20, 0b11111111)
        execute([0x26, 0x20])
      end
      it "should rotate the memory location" do
        expect(memory.peek(0x20)).to eq(0b11111110)
        expect(cpu.status.carry?).to eq(true)
        expect(cpu.cycles).to eq(5)
      end
    end

    context "with absolute addressing" do
      before do
        memory.poke(0x2010, 0b01111111)
        execute([0x2e, 0x10, 0x20])
      end
      it "should rotate the memory location" do
        expect(memory.peek(0x2010)).to eq(0b11111110)
        expect(cpu.status.carry?).to eq(false)
        expect(cpu.cycles).to eq(6)
      end
    end

    context "with absolute_x addressing" do
      before do
        cpu.x = 2
        memory.poke(0x2012, 0b01111111)
        execute([0x3e, 0x10, 0x20])
      end
      it "should rotate the memory location" do
        expect(memory.peek(0x2012)).to eq(0b11111110)
        expect(cpu.status.carry?).to eq(false)
        expect(cpu.cycles).to eq(7)
      end
    end
  end

  describe "ROR" do
    context "with accumulator addressing" do
      before do
        cpu.a = 0b11111110
        execute([0x6a])
      end
      it "should rotate the accumulator" do
        expect(cpu.a).to eq(0b01111111)
        expect(cpu.status.carry?).to eq(false)
        expect(cpu.cycles).to eq(2)
      end
    end

    context "with carry bit" do
      before do
        cpu.status.carry = 1
        cpu.a = 0b01010101
        execute([0x6a])
      end
      it "should rotate the accumulator" do
        expect(cpu.a).to eq(0b10101010)
        expect(cpu.status.carry?).to eq(true)
      end
    end
  end

  describe "RTI" do
    before do
      memory.write(0x01fd, [0x40, 0x12, 0x20])
      cpu.stack_pointer = 0xfc
      execute([0x40])
    end

    it "should return from the interrupt" do
      expect(cpu.p).to eq(0x40)
      expect(cpu.program_counter).to eq(0x2012)
      expect(cpu.stack_pointer).to eq(0xff)
      expect(cpu.cycles).to eq(6)
    end
  end

  describe "RTS" do
    before do
      memory.write(0x01fe, [0x12, 0x20])
      cpu.stack_pointer = 0xfd
      execute([0x60])
    end

    it "should return from the subroutine" do
      expect(cpu.program_counter).to eq(0x2013)
      expect(cpu.stack_pointer).to eq(0xff)
      expect(cpu.cycles).to eq(6)
    end
  end

  describe "SBC" do
    it "should add the values" do
      cpu.a = 0x05
      execute([0xe9, 0x01])
      expect(cpu.a).to eq(0x04)
      expect(cpu.status.carry?).to eq(true)
      expect(cpu.status.overflow?).to eq(false)
      expect(cpu.cycles).to eq(2)
    end

    it "should include the carry bit" do
      cpu.a = 0x05
      cpu.status.carry = true
      execute([0xe9, 0x01])
      expect(cpu.a).to eq(0x03)
      expect(cpu.status.carry?).to eq(true)
      expect(cpu.status.overflow?).to eq(false)
    end

    it "should set the carry bit rolling over" do
      cpu.a = 0x0
      execute([0xe9, 0x01])
      expect(cpu.a).to eq(0xff)
      expect(cpu.status.carry?).to eq(false)
      expect(cpu.status.overflow?).to eq(false)
    end

    it "should set the overflow bit" do
      cpu.a = -128
      execute([0xe9, 1])
      expect(cpu.status.overflow?).to eq(true)
    end
  end

  describe "SEC" do
    before { execute([0x38]) }
    it "should set the flag" do
      expect(cpu.status.carry?).to eq(true)
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "SED" do
    before { execute([0xf8]) }
    it "should set the flag" do
      expect(cpu.status.decimal?).to eq(true)
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "SEI" do
    before { execute([0x78]) }
    it "should set the flag" do
      expect(cpu.status.interrupt?).to eq(true)
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "STA" do
    before do
      cpu.a = 0x40
      execute([0x8d, 0x10, 0x20])
    end
    it "should store the accumulator" do
      expect(memory.peek(0x2010)).to eq(0x40)
      expect(cpu.cycles).to eq(4)
    end
  end

  describe "STX" do
    before do
      cpu.x = 0x40
      execute([0x8e, 0x10, 0x20])
    end
    it "should store the X register" do
      expect(memory.peek(0x2010)).to eq(0x40)
      expect(cpu.cycles).to eq(4)
    end
  end

  describe "STY" do
    before do
      cpu.y = 0x40
      execute([0x8c, 0x10, 0x20])
    end
    it "should store the Y register" do
      expect(memory.peek(0x2010)).to eq(0x40)
      expect(cpu.cycles).to eq(4)
    end
  end

  describe "TAX" do
    before do
      cpu.a = 0x40
      execute([0xaa])
    end
    it "should transfer the accumulator" do
      expect(cpu.x).to eq(0x40)
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "TAY" do
    before do
      cpu.a = 0x40
      execute([0xa8])
    end
    it "should transfer the accumulator" do
      expect(cpu.y).to eq(0x40)
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "TSX" do
    before do
      execute([0xba])
    end
    it "should transfer the stack pointer" do
      expect(cpu.x).to eq(0xff)
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "TXA" do
    before do
      cpu.x = 0x40
      execute([0x8a])
    end
    it "should transfer X to the accumulator" do
      expect(cpu.a).to eq(0x40)
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "TXS" do
    before do
      cpu.x = 0x40
      execute([0x9a])
    end
    it "should transfer X to the accumulator" do
      expect(cpu.stack_pointer).to eq(0x40)
      expect(cpu.cycles).to eq(2)
    end
  end

  describe "TYA" do
    before do
      cpu.y = 0x40
      execute([0x98])
    end
    it "should transfer X to the accumulator" do
      expect(cpu.a).to eq(0x40)
      expect(cpu.cycles).to eq(2)
    end
  end
end
