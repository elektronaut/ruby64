module C64
  # http://www.6502.org/tutorials/6502opcodes.html
  # http://www.e-tradition.net/bytes/6502/6502_instruction_set.html
  module InstructionSet
    # Add with carry.
    def adc(instruction, addr, value)
      raise "TODO"
    end

    # And (with accumulator)
    def and(instruction, addr, value)
      @a &= value.call
      update_number_flags(@a)
    end

    # Arithmetic shift left
    def asl(instruction, addr, value)
      raise "TODO"
    end

    # Branch on carry clear.
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # relative    90       2/3/4
    #
    # Flags: None
    def bcc(instruction, addr, value)
      branch(addr) if !status.carry?
    end

    # Branch on carry set.
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # relative    B0       2/3/4
    #
    # Flags: None
    def bcs(instruction, addr, value)
      branch(addr) if status.carry?
    end

    # Branch on equal (zero set)
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # relative    F0       2/3/4
    #
    # Flags: None
    def beq(instruction, addr, value)
      branch(addr) if status.zero?
    end

    # Bit test
    def bit(instruction, addr, value)
      raise "TODO"
    end

    # Branch on minus (negative set).
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # relative    30       2/3/4
    #
    # Flags: None
    def bmi(instruction, addr, value)
      branch(addr) if status.negative?
    end

    # Branch on not equal (zero clear).
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # relative    D0       2/3/4
    #
    # Flags: None
    def bne(instruction, addr, value)
      branch(addr) if !status.zero?
    end

    # Branch on plus (negative clear).
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # relative    10       2/3/4
    #
    # Flags: None
    def bpl(instruction, addr, value)
      branch(addr) if !status.negative?
    end

    # Interrupt
    def brk(instruction, addr, value)
      raise "TODO"
    end

    # Branch on overflow clear.
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # relative    50       2/3/4
    #
    # Flags: None
    def bvc(instruction, addr, value)
      branch(addr) if !status.overflow?
    end

    # Branch on overflow set.
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # relative    70       2/3/4
    #
    # Flags: None
    def bvs(instruction, addr, value)
      branch(addr) if status.overflow?
    end

    # Clear carry.
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # implied     18       2
    #
    # Flags: C
    def clc(instruction, addr, value)
      cycle { status.carry = false }
    end

    # Clear decimal.
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # implied     D8       2
    #
    # Flags: D
    def cld(instruction, addr, value)
      cycle { status.decimal = false }
    end

    # Clear interrupt disable
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # implied     58       2
    #
    # Flags: I
    def cli(instruction, addr, value)
      cycle { status.interrupt = false }
    end

    # Clear overflow
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # implied     B8       2
    #
    # Flags: V
    def clv(instruction, addr, value)
      cycle { status.overflow = false }
    end

    # Compare (with accumulator)
    def cmp(instruction, addr, value)
      raise "TODO"
    end

    # Compare with X
    def cpx(instruction, addr, value)
      raise "TODO"
    end

    # Compare with Y
    def cpy(instruction, addr, value)
      raise "TODO"
    end

    # Decrement
    def dec(instruction, addr, value)
      raise "TODO"
    end

    # Decrement X
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # implied     CA       2
    #
    # Flags: V
    def dex(instruction, addr, value)
      cycle { @x -= 1 }
      update_number_flags(@x)
    end

    # Decrement Y
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # implied     88       2
    #
    # Flags: V
    def dey(instruction, addr, value)
      cycle { @y -= 1 }
      update_number_flags(@y)
    end

    # Exclusive or (with accumulator)
    def eor(instruction, addr, value)
      raise "TODO"
    end

    # Increment
    def inc(instruction, addr, value)
      raise "TODO"
    end

    # Increment X.
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # implied     E8       2
    #
    # Flags: N, Z
    def inx(instruction, addr, value)
      cycle { @x += 1 }
      update_number_flags(@x)
    end

    # Increment Y.
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # implied     C8       2
    #
    # Flags: N, Z
    def iny(instruction, addr, value)
      cycle { @y += 1 }
      update_number_flags(@y)
    end

    # Jump to new location.
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # absolute    4C       3
    # indirect    6C       5
    #
    # Flags: none
    def jmp(instruction, addr, value)
      @program_counter = addr
    end

    # Jump subroutine
    def jsr(instruction, addr, value)
      raise "TODO"
    end

    # Load accumulator.
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # immediate   A9       2
    # zeropage    A5       3
    # zeropage_x  B5       4
    # absolute    AD       4
    # absolute_x  BD       4/5
    # absolute_y  B9       4/5
    # indirect_x  A1       6
    # indirect_y  B1       5/6
    #
    # Flags: N, Z
    def lda(instruction, addr, value)
      @a = value.call
      update_number_flags(@a)
    end

    # Load X.
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # immediate   A2       2
    # zeropage    A6       3
    # zeropage_y  B6       4
    # absolute    AE       4
    # absolute_y  BE       4/5
    #
    # Flags: N, Z
    def ldx(instruction, addr, value)
      @x = value.call
      update_number_flags(@x)
    end

    # Load Y.
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # immediate   A0       2
    # zeropage    A4       3
    # zeropage_x  B4       4
    # absolute    AC       4
    # absolute_x  BC       4/5
    #
    # Flags: N, Z
    def ldy(instruction, addr, value)
      @y = value.call
      update_number_flags(@y)
    end

    # Logical shift right
    def lsr(instruction, addr, value)
      raise "TODO"
    end

    # No operation,
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # absolute    EA       2
    #
    # Flags: none
    def nop(instruction, addr, value)
      cycle { nil }
    end

    # Or with accumulator
    def ora(instruction, addr, value)
      raise "TODO"
    end

    # Push accumulator.
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # implied     48       3
    #
    # Flags: None
    def pha(instruction, addr, value)
      stack_push(@a)
    end

    # Push processor status (SR)
    def php(instruction, addr, value)
      stack_push(p)
    end

    # Pull accumulator
    def pla(instruction, addr, value)
      cycle { @a = stack_pull }
      update_number_flags(@a)
    end

    # Pull processor status (SR)
    def plp(instruction, addr, value)
      cycle { status.value = stack_pull }
    end

    # Rotate left
    def rol(instruction, addr, value)
      raise "TODO"
    end

    # Rotate right
    def ror(instruction, addr, value)
      raise "TODO"
    end

    # Return from interrupt
    def rti(instruction, addr, value)
      raise "TODO"
    end

    # Return from subroutine
    def rts(instruction, addr, value)
      raise "TODO"
    end

    # Subtract with carry
    def sbc(instruction, addr, value)
      raise "TODO"
    end

    # Set carry
    def sec(instruction, addr, value)
      raise "TODO"
    end

    # Set decimal
    def sed(instruction, addr, value)
      raise "TODO"
    end

    # Set interrupt disable
    def sei(instruction, addr, value)
      raise "TODO"
    end

    # Store accumulator
    def sta(instruction, addr, value)
      raise "TODO"
    end

    # Store X
    def stx(instruction, addr, value)
      raise "TODO"
    end

    # Store Y
    def sty(instruction, addr, value)
      raise "TODO"
    end

    # Transfer accumulator to X
    def tax(instruction, addr, value)
      raise "TODO"
    end

    # Transfer accumulator to Y
    def tay(instruction, addr, value)
      raise "TODO"
    end

    # Transfer stack pointer to X
    def tsx(instruction, addr, value)
      raise "TODO"
    end

    # Transfer X to accumulator
    def txa(instruction, addr, operand)
      raise "TODO"
    end

    # Transfer X to stack pointer
    def txs(instruction, addr, operand)
      raise "TODO"
    end

    # Transfer Y to accumulator
    def tya(instruction, addr, operand)
      raise "TODO"
    end

    private

    def branch(addr)
      cycle {} if addr.high != @program_counter.high
      cycle { @program_counter = addr }
    end

    def stack_address
      Uint16.new(stack_pointer, 0x01)
    end

    def stack_pull
      cycle { @stack_pointer += 1 }
      read_byte(stack_address)
    end

    def stack_push(value)
      cycle { memory[stack_address] = value }
      cycle { @stack_pointer -= 1 }
    end

    def update_number_flags(value)
      status.zero = (value == 0)
      status.negative = (value >> 7 == 1)
    end
  end
end
