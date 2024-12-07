# frozen_string_literal: true

require "spec_helper"

describe Ruby64::CPU do
  let(:start_addr) { 0xc000 }
  let(:memory) do
    Ruby64::Memory.new.tap do |m|
      m.poke(0xfffc, start_addr)
    end
  end
  let(:cpu) { described_class.new(memory) }

  def execute(bytes, steps = 1)
    memory.write(start_addr, bytes)
    steps.times { cpu.step! }
  end

  describe "Non-maskable interrupt" do
    before do
      memory.write(0xfffa, [0x39, 0x05])
      memory.write(start_addr, [0x69, 0x05])
      cpu.cycle!
      cpu.nmi = true # Set the interrupt mid-instruction
      2.times { cpu.step! } # Finish the instruction and perform the interrupt
    end

    specify { expect(cpu.cycles).to eq(2 + 7) }
    specify { expect(cpu.stack_pointer).to eq(0xfc) }
    specify { expect(cpu.status.interrupt?).to be(true) }
    specify { expect(cpu.nmi).to be(false) }
    specify { expect(cpu.program_counter).to eq(0x0539) }

    it "finishes the previous instruction" do
      expect(cpu.a).to eq(0x05)
    end
  end

  describe "Interrupt request" do
    let(:interrupt) { false }

    before do
      memory.write(0xfffe, [0x40, 0x05])
      memory.write(start_addr, [0x69, 0x05])
      cpu.status.interrupt = interrupt
      cpu.cycle!
      cpu.irq = true # Set the interrupt mid-instruction
      2.times { cpu.step! } # Finish the instruction and perform the interrupt
    end

    specify { expect(cpu.cycles).to eq(2 + 7) }
    specify { expect(cpu.stack_pointer).to eq(0xfc) }
    specify { expect(cpu.status.interrupt?).to be(true) }
    specify { expect(cpu.irq).to be(false) }
    specify { expect(cpu.program_counter).to eq(0x0540) }

    it "finishes the previous instruction" do
      expect(cpu.a).to eq(0x05)
    end

    describe "when the interrupt flag is set" do
      let(:interrupt) { true }

      specify { expect(cpu.cycles).to eq(2) }
      specify { expect(cpu.stack_pointer).to eq(0xff) }
      specify { expect(cpu.program_counter).to eq(0xc002) }
      specify { expect(cpu.irq).to be(false) }
    end
  end

  describe "ADC" do
    before { cpu.a = 0x01 }

    describe "adding a value" do
      before { execute([0x69, 0x01]) }

      specify { expect(cpu.a).to eq(0x02) }
      specify { expect(cpu.status.carry?).to be(false) }
      specify { expect(cpu.status.overflow?).to be(false) }
      specify { expect(cpu.cycles).to eq(2) }
    end

    describe "when the carry bit is set" do
      before do
        cpu.status.carry = true
        execute([0x69, 0x01])
      end

      specify { expect(cpu.a).to eq(0x03) }
      specify { expect(cpu.status.carry?).to be(false) }
      specify { expect(cpu.status.overflow?).to be(false) }
    end

    describe "rolling over" do
      before do
        cpu.a = 0xff
        execute([0x69, 0x01])
      end

      specify { expect(cpu.a).to eq(0x00) }
      specify { expect(cpu.status.carry?).to be(true) }
      specify { expect(cpu.status.overflow?).to be(false) }
    end

    describe "overflowing" do
      before do
        cpu.a = -128
        execute([0x69, -1])
      end

      specify { expect(cpu.status.overflow?).to be(true) }
    end
  end

  describe "ADC (decimal mode)" do
    before do
      cpu.a = 0x22
      cpu.status.decimal = true
    end

    describe "adding a value" do
      before { execute([0x69, 0x33]) }

      specify { expect(cpu.a).to eq(0x55) }
      specify { expect(cpu.status.carry?).to be(false) }
    end

    describe "when the carry bit is set" do
      before do
        cpu.status.carry = true
        execute([0x69, 0x01])
      end

      specify { expect(cpu.a).to eq(0x24) }
      specify { expect(cpu.status.carry?).to be(false) }
    end

    describe "rolling over" do
      before do
        cpu.a = 0x99
        execute([0x69, 0x01])
      end

      specify { expect(cpu.a).to eq(0x00) }
      specify { expect(cpu.status.carry?).to be(true) }
      specify { expect(cpu.status.overflow?).to be(false) }
    end
  end

  describe "AND" do
    before do
      cpu.a = 0b00001111
      execute([0x29, 0b10101010])
    end

    specify { expect(cpu.a).to eq(0b00001010) }
    specify { expect(cpu.cycles).to eq(2) }
  end

  describe "ASL" do
    context "with accumulator addressing" do
      before do
        cpu.a = 0b11111111
        execute([0x0a])
      end

      specify { expect(cpu.a).to eq(0b11111110) }
      specify { expect(cpu.status.carry?).to be(true) }
      specify { expect(cpu.cycles).to eq(2) }
    end

    context "with carry bit" do
      before do
        cpu.status.carry = 1
        cpu.a = 0b01010101
        execute([0x0a])
      end

      specify { expect(cpu.a).to eq(0b10101010) }
      specify { expect(cpu.status.carry?).to be(false) }
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

      specify { expect(cpu.cycles).to eq(2) }

      specify { expect(cpu.program_counter).to eq(0xc002) }
    end

    context "when flag is clear" do
      specify { expect(cpu.cycles).to eq(3) }

      specify { expect(cpu.program_counter).to eq(0xc022) }
    end

    context "when branching across page boundary" do
      let(:offset) { -100 }

      specify { expect(cpu.program_counter).to eq(0xbf9e) }
      specify { expect(cpu.cycles).to eq(4) }
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

      specify { expect(cpu.cycles).to eq(2) }

      it "does not branch" do
        expect(cpu.program_counter).to eq(0xc002)
      end
    end

    context "when flag is set" do
      specify { expect(cpu.cycles).to eq(3) }

      it "branches" do
        expect(cpu.program_counter).to eq(0xc022)
      end
    end

    context "when branching across page boundary" do
      let(:offset) { -100 }

      it "spends an extra cycle" do
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

      specify { expect(cpu.cycles).to eq(2) }

      it "does not branch" do
        expect(cpu.program_counter).to eq(0xc002)
      end
    end

    context "when flag is set" do
      specify { expect(cpu.cycles).to eq(3) }

      it "branches" do
        expect(cpu.program_counter).to eq(0xc022)
      end
    end

    context "when branching across page boundary" do
      let(:offset) { -100 }

      specify { expect(cpu.cycles).to eq(4) }
    end
  end

  describe "BIT" do
    context "when zeropage addressing" do
      before do
        memory.poke(0x20, 0b11000000)
        execute([0x24, 0x20])
      end

      specify { expect(cpu.status.negative?).to be(true) }
      specify { expect(cpu.status.overflow?).to be(true) }
      specify { expect(cpu.status.zero?).to be(true) }
      specify { expect(cpu.cycles).to eq(3) }
    end

    context "when absolute addressing" do
      before do
        cpu.a = 1
        memory.poke(0x2010, 0b00000001)
        execute([0x2c, 0x10, 0x20])
      end

      specify { expect(cpu.status.negative?).to be(false) }
      specify { expect(cpu.status.overflow?).to be(false) }
      specify { expect(cpu.status.zero?).to be(false) }
      specify { expect(cpu.cycles).to eq(4) }
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

      specify { expect(cpu.cycles).to eq(2) }

      it "does not branch" do
        expect(cpu.program_counter).to eq(0xc002)
      end
    end

    context "when negative is set" do
      specify { expect(cpu.cycles).to eq(3) }

      it "branches" do
        expect(cpu.program_counter).to eq(0xc022)
      end
    end

    context "when branching across page boundary" do
      let(:offset) { -100 }

      specify { expect(cpu.cycles).to eq(4) }
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

      specify { expect(cpu.cycles).to eq(2) }

      it "does not branch" do
        expect(cpu.program_counter).to eq(0xc002)
      end
    end

    context "when flag is clear" do
      specify { expect(cpu.cycles).to eq(3) }

      it "branches" do
        expect(cpu.program_counter).to eq(0xc022)
      end
    end

    context "when branching across page boundary" do
      let(:offset) { -100 }

      specify { expect(cpu.cycles).to eq(4) }
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

      specify { expect(cpu.cycles).to eq(2) }

      it "does not branch" do
        expect(cpu.program_counter).to eq(0xc002)
      end
    end

    context "when flag is clear" do
      specify { expect(cpu.cycles).to eq(3) }

      it "branches" do
        expect(cpu.program_counter).to eq(0xc022)
      end
    end

    context "when branching across page boundary" do
      let(:offset) { -100 }

      specify { expect(cpu.cycles).to eq(4) }
    end
  end

  describe "BRK" do
    let(:interrupt) { false }

    before do
      memory.write(0xfffe, [0x40, 0x05])
      cpu.status.interrupt = interrupt
      execute([0x00])
    end

    specify { expect(cpu.cycles).to eq(7) }
    specify { expect(cpu.stack_pointer).to eq(0xfc) }
    specify { expect(cpu.status.break?).to be(true) }
    specify { expect(cpu.status.interrupt?).to be(true) }
    specify { expect(cpu.irq).to be(false) }
    specify { expect(cpu.program_counter).to eq(0x0540) }

    describe "when the interrupt flag is set" do
      let(:interrupt) { true }

      specify { expect(cpu.cycles).to eq(1) }
      specify { expect(cpu.stack_pointer).to eq(0xff) }
      specify { expect(cpu.program_counter).to eq(0xc001) }
      specify { expect(cpu.irq).to be(false) }
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

      specify { expect(cpu.cycles).to eq(2) }

      it "does not branch" do
        expect(cpu.program_counter).to eq(0xc002)
      end
    end

    context "when flag is clear" do
      specify { expect(cpu.cycles).to eq(3) }

      it "branches" do
        expect(cpu.program_counter).to eq(0xc022)
      end
    end

    context "when branching across page boundary" do
      let(:offset) { -100 }

      it "spends an extra cycle" do
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

      specify { expect(cpu.cycles).to eq(2) }

      it "does not branch" do
        expect(cpu.program_counter).to eq(0xc002)
      end
    end

    context "when flag is set" do
      specify { expect(cpu.cycles).to eq(3) }

      it "branches" do
        expect(cpu.program_counter).to eq(0xc022)
      end
    end

    context "when branching across page boundary" do
      let(:offset) { -100 }

      specify { expect(cpu.cycles).to eq(4) }
    end
  end

  describe "CLC" do
    before do
      cpu.status.carry = true
      execute([0x18])
    end

    specify { expect(cpu.cycles).to eq(2) }

    it "clears the flag" do
      expect(cpu.status.carry?).to be(false)
    end
  end

  describe "CLD" do
    before do
      cpu.status.decimal = true
      execute([0xd8])
    end

    specify { expect(cpu.cycles).to eq(2) }

    it "clears the flag" do
      expect(cpu.status.decimal?).to be(false)
    end
  end

  describe "CLI" do
    before do
      cpu.status.interrupt = true
      execute([0x58])
    end

    specify { expect(cpu.cycles).to eq(2) }

    it "clears the flag" do
      expect(cpu.status.interrupt?).to be(false)
    end
  end

  describe "CLV" do
    before do
      cpu.status.overflow = true
      execute([0xb8])
    end

    specify { expect(cpu.cycles).to eq(2) }

    it "clears the flag" do
      expect(cpu.status.overflow?).to be(false)
    end
  end

  describe "CMP" do
    before do
      cpu.a = 0x60
      execute([0xc9, 0x40])
    end

    specify { expect(cpu.cycles).to eq(2) }

    it "sets the flags" do
      expect(cpu.status.carry?).to be(true)
    end
  end

  describe "CPX" do
    before do
      cpu.x = 0x60
      execute([0xe0, 0x40])
    end

    specify { expect(cpu.cycles).to eq(2) }

    it "sets the flags" do
      expect(cpu.status.carry?).to be(true)
    end
  end

  describe "CPY" do
    before do
      cpu.y = 0x60
      execute([0xc0, 0x40])
    end

    specify { expect(cpu.cycles).to eq(2) }

    it "sets the flags" do
      expect(cpu.status.carry?).to be(true)
    end
  end

  describe "DEC" do
    before { memory.poke(target_addr, 0x40) }

    describe "zeropage addressing" do
      let(:target_addr) { 0x20 }

      before { execute([0xc6, target_addr]) }

      specify { expect(cpu.cycles).to eq(5) }

      it "decrements the value" do
        expect(memory.peek(target_addr)).to eq(0x3f)
      end
    end

    describe "zeropage_x addressing" do
      let(:target_addr) { 0x22 }

      before do
        cpu.x = 2
        execute([0xd6, 0x20])
      end

      specify { expect(cpu.cycles).to eq(6) }

      it "decrements the value" do
        expect(memory.peek(target_addr)).to eq(0x3f)
      end
    end

    describe "absolute addressing" do
      let(:target_addr) { 0x2010 }

      before { execute([0xce, 0x10, 0x20]) }

      specify { expect(cpu.cycles).to eq(6) }

      it "decrements the value" do
        expect(memory.peek(target_addr)).to eq(0x3f)
      end
    end

    describe "absolute_x addressing" do
      let(:target_addr) { 0x2012 }

      before do
        cpu.x = 2
        execute([0xde, 0x10, 0x20])
      end

      specify { expect(cpu.cycles).to eq(7) }

      it "decrements the value" do
        expect(memory.peek(target_addr)).to eq(0x3f)
      end
    end
  end

  describe "DEX" do
    before { execute([0xca]) }

    specify { expect(cpu.cycles).to eq(2) }

    it "decrements x by 1" do
      expect(cpu.x).to eq(255)
    end
  end

  describe "DEY" do
    before { execute([0x88]) }

    specify { expect(cpu.cycles).to eq(2) }

    it "decrements y by 1" do
      expect(cpu.y).to eq(255)
    end
  end

  describe "EOR" do
    before do
      cpu.a = 0b00001111
      execute([0x49, 0b10101010])
    end

    specify { expect(cpu.cycles).to eq(2) }

    it "does a bitwise AND on the accumulator" do
      expect(cpu.a).to eq(0b10100101)
    end
  end

  describe "INC" do
    before do
      memory.poke(0x20, 0x40)
      execute([0xe6, 0x20])
    end

    specify { expect(cpu.cycles).to eq(5) }

    it "increments the value" do
      expect(memory.peek(0x20)).to eq(0x41)
    end
  end

  describe "INX" do
    before { execute([0xe8]) }

    specify { expect(cpu.cycles).to eq(2) }

    it "increments x by 1" do
      expect(cpu.x).to eq(1)
    end
  end

  describe "INY" do
    before { execute([0xc8]) }

    specify { expect(cpu.cycles).to eq(2) }

    it "increments y by 1" do
      expect(cpu.y).to eq(1)
    end
  end

  describe "JMP" do
    context "when absolute addressing" do
      before { execute([0x4c, 0x39, 0x05]) }

      specify { expect(cpu.cycles).to eq(3) }

      it "updates the program counter" do
        expect(cpu.program_counter).to eq(0x0539)
      end
    end

    context "when indirect addressing" do
      before do
        memory.write(0x2120, [0x05, 0x39])
        execute([0x6c, 0x20, 0x21])
      end

      specify { expect(cpu.cycles).to eq(5) }

      it "updates the program counter" do
        expect(cpu.program_counter).to eq(0x0539)
      end
    end

    context "when indirect addressing (at page boundary)" do
      before do
        memory.write(0x21ff, [0x05, 0x39])
        execute([0x6c, 0xff, 0x21])
      end

      specify { expect(cpu.cycles).to eq(5) }

      it "updates the program counter" do
        expect(cpu.program_counter).to eq(0x0500)
      end
    end
  end

  describe "JSR" do
    before { execute([0x20, 0x10, 0x20]) }

    specify { expect(cpu.cycles).to eq(6) }
    specify { expect(cpu.program_counter).to eq(0x2010) }
    specify { expect(memory.peek16(0x01fe)).to eq(0xc003) }
    specify { expect(cpu.stack_pointer).to eq(0xfd) }
  end

  describe "LDA" do
    context "when immediate addressing" do
      before { execute([0xa9, 0x40]) }

      specify { expect(cpu.cycles).to eq(2) }

      it "sets the accumulator" do
        expect(cpu.a).to eq(0x40)
      end
    end

    context "when zeropage addressing" do
      before do
        memory.write(0x20, [0x40])
        execute([0xa5, 0x20])
      end

      specify { expect(cpu.cycles).to eq(3) }

      it "sets the accumulator" do
        expect(cpu.a).to eq(0x40)
      end
    end

    context "when zeropage_x addressing" do
      before do
        cpu.x = 0x05
        memory.write(0x25, [0x40])
        execute([0xb5, 0x20])
      end

      specify { expect(cpu.cycles).to eq(4) }

      it "sets the accumulator" do
        expect(cpu.a).to eq(0x40)
      end
    end

    context "when absolute addressing" do
      before do
        memory.write(0x2010, [0x40])
        execute([0xad, 0x10, 0x20])
      end

      specify { expect(cpu.cycles).to eq(4) }

      it "sets the accumulator" do
        expect(cpu.a).to eq(0x40)
      end
    end

    context "when absolute_x addressing" do
      before do
        cpu.x = 0x01
        memory.write(0x2011, [0x40])
        execute([0xbd, 0x10, 0x20])
      end

      specify { expect(cpu.cycles).to eq(4) }

      it "sets the accumulator" do
        expect(cpu.a).to eq(0x40)
      end
    end

    context "when absolute_x addressing at page boundary" do
      before do
        cpu.x = 0x03
        memory.write(0x2101, [0x40])
        execute([0xbd, 0xfe, 0x20])
      end

      specify { expect(cpu.cycles).to eq(5) }

      it "spends an extra cycle" do
        expect(cpu.a).to eq(0x40)
      end
    end

    context "when absolute_y addressing" do
      before do
        cpu.y = 0x03
        memory.write(0x2101, [0x40])
        execute([0xb9, 0xfe, 0x20])
      end

      specify { expect(cpu.cycles).to eq(5) }

      it "sets the accumulator" do
        expect(cpu.a).to eq(0x40)
      end
    end

    context "when indirect_x addressing" do
      before do
        cpu.x = 0x03
        memory.write(0x2110, [0x40])
        memory.write(0x05, [0x10, 0x21])
        execute([0xa1, 0x02])
      end

      specify { expect(cpu.cycles).to eq(6) }

      it "sets the accumulator" do
        expect(cpu.a).to eq(0x40)
      end
    end

    context "when indirect_y addressing" do
      before do
        cpu.y = 0x03
        memory.write(0x2113, [0x40])
        memory.write(0x05, [0x10, 0x21])
        execute([0xb1, 0x05])
      end

      specify { expect(cpu.cycles).to eq(5) }

      it "sets the accumulator" do
        expect(cpu.a).to eq(0x40)
      end
    end

    context "when indirect_y addressing at page boundary" do
      before do
        cpu.y = 0x03
        memory.write(0x2113, [0x40])
        memory.write(0xff, [0x10, 0x21])
        execute([0xb1, 0xff])
      end

      specify { expect(cpu.cycles).to eq(6) }

      it "sets the accumulator" do
        expect(cpu.a).to eq(0x40)
      end
    end
  end

  describe "LDX" do
    before { execute([0xa2, 0x40]) }

    specify { expect(cpu.cycles).to eq(2) }

    it "sets the accumulator" do
      expect(cpu.x).to eq(0x40)
    end
  end

  describe "LDY" do
    before { execute([0xa0, 0x40]) }

    specify { expect(cpu.cycles).to eq(2) }

    it "sets the accumulator" do
      expect(cpu.y).to eq(0x40)
    end
  end

  describe "LSR" do
    context "with accumulator addressing" do
      before do
        cpu.a = 0b11111110
        execute([0x4a])
      end

      specify { expect(cpu.cycles).to eq(2) }
      specify { expect(cpu.a).to eq(0b01111111) }
      specify { expect(cpu.status.carry?).to be(false) }
    end

    context "with carry bit" do
      before do
        cpu.status.carry = 1
        cpu.a = 0b01010101
        execute([0x4a])
      end

      specify { expect(cpu.a).to eq(0b00101010) }
      specify { expect(cpu.status.carry?).to be(true) }
    end
  end

  describe "NOP" do
    before { execute([0xea]) }

    specify { expect(cpu.cycles).to eq(2) }
  end

  describe "ORA" do
    context "when immediate addressing" do
      before do
        cpu.a = 0b00001111
        execute([0x09, 0b10101010])
      end

      specify { expect(cpu.cycles).to eq(2) }

      it "does a bitwise AND on the accumulator" do
        expect(cpu.a).to eq(0b10101111)
      end
    end

    context "when zeropage addressing" do
      before do
        memory.poke(0xbd, 0b10101010)
        cpu.a = 0b00001111
        execute([0x05, 0xbd])
      end

      specify { expect(cpu.cycles).to eq(3) }

      it "does a bitwise AND on the accumulator" do
        expect(cpu.a).to eq(0b10101111)
      end
    end
  end

  describe "PHA" do
    before do
      cpu.a = 0x40
      execute([0x48])
    end

    specify { expect(cpu.cycles).to eq(3) }
    specify { expect(memory.peek(0x01ff)).to eq(0x40) }
    specify { expect(cpu.stack_pointer).to eq(0xfe) }
  end

  describe "PHP" do
    before do
      cpu.p = 0b10101010
      execute([0x08])
    end

    specify { expect(cpu.cycles).to eq(3) }
    specify { expect(memory.peek(0x01ff)).to eq(0b10101010) }
    specify { expect(cpu.stack_pointer).to eq(0xfe) }
  end

  describe "PLA" do
    before do
      memory.poke(0x01ff, 0x20)
      cpu.stack_pointer = 0xfe
      execute([0x68])
    end

    specify { expect(cpu.cycles).to eq(4) }
    specify { expect(cpu.a).to eq(0x20) }
    specify { expect(cpu.stack_pointer).to eq(0xff) }
  end

  describe "PLP" do
    before do
      memory.poke(0x01ff, 0b10101010)
      cpu.stack_pointer = 0xfe
      execute([0x28])
    end

    specify { expect(cpu.cycles).to eq(4) }
    specify { expect(cpu.p).to eq(0b10101010) }
    specify { expect(cpu.stack_pointer).to eq(0xff) }
  end

  describe "ROL" do
    context "with accumulator addressing" do
      before do
        cpu.a = 0b11111111
        execute([0x2a])
      end

      specify { expect(cpu.cycles).to eq(2) }
      specify { expect(cpu.a).to eq(0b11111110) }
      specify { expect(cpu.status.carry?).to be(true) }
    end

    context "with carry bit" do
      before do
        cpu.status.carry = 1
        cpu.a = 0b10101010
        execute([0x2a])
      end

      specify { expect(cpu.a).to eq(0b01010101) }
      specify { expect(cpu.status.carry?).to be(true) }
    end

    context "with zeropage addressing" do
      before do
        memory.poke(0x20, 0b11111111)
        execute([0x26, 0x20])
      end

      specify { expect(cpu.cycles).to eq(5) }
      specify { expect(memory.peek(0x20)).to eq(0b11111110) }
      specify { expect(cpu.status.carry?).to be(true) }
    end

    context "with absolute addressing" do
      before do
        memory.poke(0x2010, 0b01111111)
        execute([0x2e, 0x10, 0x20])
      end

      specify { expect(cpu.cycles).to eq(6) }
      specify { expect(memory.peek(0x2010)).to eq(0b11111110) }
      specify { expect(cpu.status.carry?).to be(false) }
    end

    context "with absolute_x addressing" do
      before do
        cpu.x = 2
        memory.poke(0x2012, 0b01111111)
        execute([0x3e, 0x10, 0x20])
      end

      specify { expect(cpu.cycles).to eq(7) }
      specify { expect(memory.peek(0x2012)).to eq(0b11111110) }
      specify { expect(cpu.status.carry?).to be(false) }
    end
  end

  describe "ROR" do
    context "with accumulator addressing" do
      before do
        cpu.a = 0b11111110
        execute([0x6a])
      end

      specify { expect(cpu.cycles).to eq(2) }
      specify { expect(cpu.a).to eq(0b01111111) }
      specify { expect(cpu.status.carry?).to be(false) }
    end

    context "with carry bit" do
      before do
        cpu.status.carry = 1
        cpu.a = 0b01010101
        execute([0x6a])
      end

      specify { expect(cpu.a).to eq(0b10101010) }
      specify { expect(cpu.status.carry?).to be(true) }
    end
  end

  describe "RTI" do
    before do
      memory.write(0x01fd, [0x40, 0x12, 0x20])
      cpu.stack_pointer = 0xfc
      execute([0x40])
    end

    specify { expect(cpu.p).to eq(0x40) }
    specify { expect(cpu.program_counter).to eq(0x2012) }
    specify { expect(cpu.stack_pointer).to eq(0xff) }
    specify { expect(cpu.cycles).to eq(6) }
  end

  describe "RTS" do
    before do
      memory.write(0x01fe, [0x12, 0x20])
      cpu.stack_pointer = 0xfd
      execute([0x60])
    end

    specify { expect(cpu.program_counter).to eq(0x2012) }
    specify { expect(cpu.stack_pointer).to eq(0xff) }
    specify { expect(cpu.cycles).to eq(6) }
  end

  describe "SBC" do
    describe "subtracting the values" do
      before do
        cpu.a = 0x05
        execute([0xe9, 0x01])
      end

      specify { expect(cpu.a).to eq(0x04) }
      specify { expect(cpu.status.carry?).to be(true) }
      specify { expect(cpu.status.overflow?).to be(false) }
      specify { expect(cpu.cycles).to eq(2) }
    end

    describe "including the carry bit" do
      before do
        cpu.a = 0x05
        cpu.status.carry = true
        execute([0xe9, 0x01])
      end

      specify { expect(cpu.a).to eq(0x03) }
      specify { expect(cpu.status.carry?).to be(true) }
      specify { expect(cpu.status.overflow?).to be(false) }
    end

    describe "setting the carry bit rolling over" do
      before do
        cpu.a = 0x0
        execute([0xe9, 0x01])
      end

      specify { expect(cpu.a).to eq(0xff) }
      specify { expect(cpu.status.carry?).to be(false) }
      specify { expect(cpu.status.overflow?).to be(false) }
    end

    describe "setting the overflow bit" do
      before do
        cpu.a = -128
        execute([0xe9, 1])
      end

      specify { expect(cpu.status.overflow?).to be(true) }
    end
  end

  describe "SBC (decimal mode)" do
    before do
      cpu.a = 0x55
      cpu.status.decimal = true
    end

    describe "subtracting a value" do
      before { execute([0xe9, 0x33]) }

      specify { expect(cpu.a).to eq(0x22) }
      specify { expect(cpu.status.carry?).to be(true) }
    end

    describe "when the carry bit is set" do
      before do
        cpu.status.carry = true
        execute([0xe9, 0x01])
      end

      specify { expect(cpu.a).to eq(0x53) }
      specify { expect(cpu.status.carry?).to be(true) }
    end

    describe "rolling over" do
      before do
        cpu.a = 0x0
        execute([0xe9, 0x01])
      end

      specify { expect(cpu.a).to eq(0x99) }
      specify { expect(cpu.status.carry?).to be(false) }
      specify { expect(cpu.status.overflow?).to be(false) }
    end
  end

  describe "SEC" do
    before { execute([0x38]) }

    specify { expect(cpu.status.carry?).to be(true) }
    specify { expect(cpu.cycles).to eq(2) }
  end

  describe "SED" do
    before { execute([0xf8]) }

    specify { expect(cpu.status.decimal?).to be(true) }
    specify { expect(cpu.cycles).to eq(2) }
  end

  describe "SEI" do
    before { execute([0x78]) }

    specify { expect(cpu.status.interrupt?).to be(true) }
    specify { expect(cpu.cycles).to eq(2) }
  end

  describe "STA" do
    before do
      cpu.a = 0x40
      execute([0x8d, 0x10, 0x20])
    end

    specify { expect(memory.peek(0x2010)).to eq(0x40) }
    specify { expect(cpu.cycles).to eq(4) }
  end

  describe "STX" do
    before do
      cpu.x = 0x40
      execute([0x8e, 0x10, 0x20])
    end

    specify { expect(memory.peek(0x2010)).to eq(0x40) }
    specify { expect(cpu.cycles).to eq(4) }
  end

  describe "STY" do
    before do
      cpu.y = 0x40
      execute([0x8c, 0x10, 0x20])
    end

    specify { expect(memory.peek(0x2010)).to eq(0x40) }
    specify { expect(cpu.cycles).to eq(4) }
  end

  describe "TAX" do
    before do
      cpu.a = 0x40
      execute([0xaa])
    end

    specify { expect(cpu.cycles).to eq(2) }

    it "transfers the accumulator" do
      expect(cpu.x).to eq(0x40)
    end
  end

  describe "TAY" do
    before do
      cpu.a = 0x40
      execute([0xa8])
    end

    specify { expect(cpu.cycles).to eq(2) }

    it "transfers the accumulator" do
      expect(cpu.y).to eq(0x40)
    end
  end

  describe "TSX" do
    before do
      execute([0xba])
    end

    specify { expect(cpu.cycles).to eq(2) }

    it "transfers the stack pointer" do
      expect(cpu.x).to eq(0xff)
    end
  end

  describe "TXA" do
    before do
      cpu.x = 0x40
      execute([0x8a])
    end

    specify { expect(cpu.cycles).to eq(2) }

    it "transfers X to the accumulator" do
      expect(cpu.a).to eq(0x40)
    end
  end

  describe "TXS" do
    before do
      cpu.x = 0x40
      execute([0x9a])
    end

    specify { expect(cpu.cycles).to eq(2) }

    it "transfers X to the accumulator" do
      expect(cpu.stack_pointer).to eq(0x40)
    end
  end

  describe "TYA" do
    before do
      cpu.y = 0x40
      execute([0x98])
    end

    specify { expect(cpu.cycles).to eq(2) }

    it "transfers X to the accumulator" do
      expect(cpu.a).to eq(0x40)
    end
  end
end
