module C64
  # http://www.6502.org/tutorials/6502opcodes.html
  # http://www.e-tradition.net/bytes/6502/6502_instruction_set.html
  module InstructionSet
    # Add with carry
    def adc(instruction, addr, operand)
      raise "TODO"
    end

    # And (with accumulator)
    def and(instruction, addr, operand)
      raise "TODO"
    end

    # Arithmetic shift left
    def asl(instruction, addr, operand)
      raise "TODO"
    end

    # Branch on carry clear.
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # relative    90       2/3/4
    #
    # Flags: None
    def bcc(instruction, addr, operand)
      return if status.carry?
      cycle {} if addr.high != @program_counter.high
      cycle { @program_counter = addr }
    end

    # Branch on carry set.
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # relative    B0       2/3/4
    #
    # Flags: None
    def bcs(instruction, addr, operand)
      return unless status.carry?
      cycle {} if addr.high != @program_counter.high
      cycle { @program_counter = addr }
    end

    # Branch on equal (zero set)
    def beq(instruction, addr, operand)
      raise "TODO"
    end

    # Bit test
    def bit(instruction, addr, operand)
      raise "TODO"
    end

    # Branch on minus (negative set)
    def bmi(instruction, addr, operand)
      raise "TODO"
    end

    # Branch on not equal (zero clear)
    def bne(instruction, addr, operand)
      raise "TODO"
    end

    # Branch on plus (negative clear)
    def bpl(instruction, addr, operand)
      raise "TODO"
    end

    # Interrupt
    def brk(instruction, addr, operand)
      raise "TODO"
    end

    # Branch on overflow clear
    def bvc(instruction, addr, operand)
      raise "TODO"
    end

    # Branch on overflow set
    def bvs(instruction, addr, operand)
      raise "TODO"
    end

    # Clear carry
    def clc(instruction, addr, operand)
      raise "TODO"
    end

    # Clear decimal
    def cld(instruction, addr, operand)
      raise "TODO"
    end

    # Clear interrupt disable
    def cli(instruction, addr, operand)
      raise "TODO"
    end

    # Clear overflow
    def clv(instruction, addr, operand)
      raise "TODO"
    end

    # Compare (with accumulator)
    def cmp(instruction, addr, operand)
      raise "TODO"
    end

    # Compare with X
    def cpx(instruction, addr, operand)
      raise "TODO"
    end

    # Compare with Y
    def cpy(instruction, addr, operand)
      raise "TODO"
    end

    # Decrement
    def dec(instruction, addr, operand)
      raise "TODO"
    end

    # Decrement X
    def dex(instruction, addr, operand)
      raise "TODO"
    end

    # Decrement Y
    def dey(instruction, addr, operand)
      raise "TODO"
    end

    # Exclusive or (with accumulator)
    def eor(instruction, addr, operand)
      raise "TODO"
    end

    # Increment
    def inc(instruction, addr, operand)
      raise "TODO"
    end

    # Increment X.
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # implied     E8       2
    #
    # Flags: N, Z
    def inx(instruction, addr, operand)
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
    def iny(instruction, addr, operand)
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
    def jmp(instruction, addr, operand)
      @program_counter = addr
    end

    # Jump subroutine
    def jsr(instruction, addr, operand)
      raise "TODO"
    end

    # Load accumulator
    def lda(instruction, addr, operand)
      raise "TODO"
    end

    # Load X
    def ldy(instruction, addr, operand)
      raise "TODO"
    end

    # Load Y
    def ldy(instruction, addr, operand)
      raise "TODO"
    end

    # Logical shift right
    def lsr(instruction, addr, operand)
      raise "TODO"
    end

    # No operation,
    #
    # Addressing  Opcode   Cycles
    # ---------------------------
    # absolute    EA       2
    #
    # Flags: none
    def nop(instruction, addr, operand)
      cycle { nil }
    end

    # Or with accumulator
    def ora(instruction, addr, operand)
      raise "TODO"
    end

    # Push accumulator
    def pha(instruction, addr, operand)
      raise "TODO"
    end

    # Push processor status (SR)
    def php(instruction, addr, operand)
      raise "TODO"
    end

    # Pull accumulator
    def pla(instruction, addr, operand)
      raise "TODO"
    end

    # Pull processor status (SR)
    def plp(instruction, addr, operand)
      raise "TODO"
    end

    # Rotate left
    def rol(instruction, addr, operand)
      raise "TODO"
    end

    # Rotate right
    def ror(instruction, addr, operand)
      raise "TODO"
    end

    # Return from interrupt
    def rti(instruction, addr, operand)
      raise "TODO"
    end

    # Return from subroutine
    def rts(instruction, addr, operand)
      raise "TODO"
    end

    # Subtract with carry
    def sbc(instruction, addr, operand)
      raise "TODO"
    end

    # Set carry
    def sec(instruction, addr, operand)
      raise "TODO"
    end

    # Set decimal
    def sed(instruction, addr, operand)
      raise "TODO"
    end

    # Set interrupt disable
    def sei(instruction, addr, operand)
      raise "TODO"
    end

    # Store accumulator
    def sta(instruction, addr, operand)
      raise "TODO"
    end

    # Store X
    def stx(instruction, addr, operand)
      raise "TODO"
    end

    # Store Y
    def sty(instruction, addr, operand)
      raise "TODO"
    end

    # Transfer accumulator to X
    def tax(instruction, addr, operand)
      raise "TODO"
    end

    # Transfer accumulator to Y
    def tay(instruction, addr, operand)
      raise "TODO"
    end

    # Transfer stack pointer to X
    def tsx(instruction, addr, operand)
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

    def update_number_flags(value)
      status.zero = (value == 0)
      status.negative = (value >> 7 == 1)
    end
  end
end
