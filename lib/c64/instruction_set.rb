module C64
  # http://www.6502.org/tutorials/6502opcodes.html
  # http://www.e-tradition.net/bytes/6502/6502_instruction_set.html
  module InstructionSet
    # Add with carry.
    def adc(instruction, addr, value)
      if status.decimal?
        raise "BCD mode not implemented yet"
      end
      v = value.call
      result = a.to_i + v.to_i + status.carry
      signed_result = Uint8.new(a).signed + v.signed + status.carry
      status.carry = result > 0xff
      status.overflow = !(-128..127).include?(signed_result)
      @a = Uint8.new(result)
      update_number_flags(@a)
    end

    # And (with accumulator)
    def and(instruction, addr, value)
      @a &= value.call
      update_number_flags(@a)
    end

    # Arithmetic shift left
    def asl(instruction, addr, value)
      cycle {} if instruction.addressing_mode == :absolute_x
      v = value.call
      result = Uint8.new(v << 1)
      status.carry = v[7]
      cycle { write_byte(addr, result) }
      update_number_flags(result)
    end

    # Branch on carry clear
    def bcc(instruction, addr, value)
      branch(addr) if !status.carry?
    end

    # Branch on carry set
    def bcs(instruction, addr, value)
      branch(addr) if status.carry?
    end

    # Branch on equal (zero set)
    def beq(instruction, addr, value)
      branch(addr) if status.zero?
    end

    # Bit test
    def bit(instruction, addr, value)
      v = value.call
      status.value = (status.value & 0b00111111) +
                     (v & 0b11000000)
      status.zero = (Uint8.new(a & v) == 0x00)
    end

    # Branch on minus (negative set)
    def bmi(instruction, addr, value)
      branch(addr) if status.negative?
    end

    # Branch on not equal (zero clear)
    def bne(instruction, addr, value)
      branch(addr) if !status.zero?
    end

    # Branch on plus (negative clear)
    def bpl(instruction, addr, value)
      branch(addr) if !status.negative?
    end

    # Interrupt
    def brk(instruction, addr, value)
      6.times { cycle {} }
      status.break = true
    end

    # Branch on overflow clear
    def bvc(instruction, addr, value)
      branch(addr) if !status.overflow?
    end

    # Branch on overflow set
    def bvs(instruction, addr, value)
      branch(addr) if status.overflow?
    end

    # Clear carry
    def clc(instruction, addr, value)
      cycle { status.carry = false }
    end

    # Clear decimal
    def cld(instruction, addr, value)
      cycle { status.decimal = false }
    end

    # Clear interrupt disable
    def cli(instruction, addr, value)
      cycle { status.interrupt = false }
    end

    # Clear overflow
    def clv(instruction, addr, value)
      cycle { status.overflow = false }
    end

    # Compare (with accumulator)
    def cmp(instruction, addr, value)
      v = value.call
      status.carry = @a >= v
      update_number_flags(@a - v)
    end

    # Compare with X
    def cpx(instruction, addr, value)
      v = value.call
      status.carry = @x >= v
      update_number_flags(@x - v)
    end

    # Compare with Y
    def cpy(instruction, addr, value)
      v = value.call
      status.carry = @y >= v
      update_number_flags(@y - v)
    end

    # Decrement
    def dec(instruction, addr, value)
      cycle {} if instruction.addressing_mode == :absolute_x
      v = cycle { value.call - 1 }
      write_byte(addr, v)
      update_number_flags(v)
    end

    # Decrement X
    def dex(instruction, addr, value)
      cycle { @x -= 1 }
      update_number_flags(@x)
    end

    # Decrement Y
    def dey(instruction, addr, value)
      cycle { @y -= 1 }
      update_number_flags(@y)
    end

    # Exclusive or (with accumulator)
    def eor(instruction, addr, value)
      @a ^= value.call
      update_number_flags(@a)
    end

    # Increment
    def inc(instruction, addr, value)
      cycle {} if instruction.addressing_mode == :absolute_x
      v = cycle { value.call + 1 }
      write_byte(addr, v)
      update_number_flags(v)
    end

    # Increment X
    def inx(instruction, addr, value)
      cycle { @x += 1 }
      update_number_flags(@x)
    end

    # Increment Y
    def iny(instruction, addr, value)
      cycle { @y += 1 }
      update_number_flags(@y)
    end

    # Jump to new location
    def jmp(instruction, addr, value)
      @program_counter = addr
    end

    # Jump subroutine
    def jsr(instruction, addr, value)
      stack_push(program_counter)
      @program_counter = addr
    end

    # Load accumulator
    def lda(instruction, addr, value)
      @a = value.call
      update_number_flags(@a)
    end

    # Load X
    def ldx(instruction, addr, value)
      @x = value.call
      update_number_flags(@x)
    end

    # Load Y
    def ldy(instruction, addr, value)
      @y = value.call
      update_number_flags(@y)
    end

    # Logical shift right
    def lsr(instruction, addr, value)
      cycle {} if instruction.addressing_mode == :absolute_x
      v = value.call
      result = Uint8.new(v >> 1)
      status.carry = v[0]
      cycle { write_byte(addr, result) }
      update_number_flags(result)
    end

    # No operation
    def nop(instruction, addr, value)
      cycle { nil }
    end

    # Or with accumulator
    def ora(instruction, addr, value)
      @a |= value.call
      update_number_flags(@a)
    end

    # Push accumulator
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
      cycle {} if instruction.addressing_mode == :absolute_x
      v = value.call
      result = Uint8.new((v << 1) + status.carry)
      status.carry = v[7]
      cycle { write_byte(addr, result) }
      update_number_flags(result)
    end

    # Rotate right
    def ror(instruction, addr, value)
      cycle {} if instruction.addressing_mode == :absolute_x
      v = value.call
      result = Uint8.new((v >> 1) + (status.carry? ? 0x80 : 0))
      status.carry = v[0]
      cycle { write_byte(addr, result) }
      update_number_flags(result)
    end

    # Return from interrupt
    def rti(instruction, addr, value)
      cycle do
        @stack_pointer += 1
        @status.value = memory[stack_address]
      end
      @program_counter = Uint16.new(
        stack_pull,
        stack_pull
      )
    end

    # Return from subroutine
    def rts(instruction, addr, value)
      cycle do
        @program_counter = Uint16.new(
          stack_pull,
          stack_pull
        ) + 1
      end
    end

    # Subtract with carry
    def sbc(instruction, addr, value)
      if status.decimal?
        raise "BCD mode not implemented yet"
      end
      v = value.call
      result = a.to_i - v.to_i - status.carry
      signed_result = Uint8.new(a).signed - v.signed - status.carry
      status.carry = result > 0x0
      status.overflow = !(-128..127).include?(signed_result)
      @a = Uint8.new(result)
      update_number_flags(@a)
    end

    # Set carry
    def sec(instruction, addr, value)
      cycle { status.carry = true }
    end

    # Set decimal
    def sed(instruction, addr, value)
      cycle { status.decimal = true }
    end

    # Set interrupt disable
    def sei(instruction, addr, value)
      cycle { status.interrupt = true }
    end

    # Store accumulator
    def sta(instruction, addr, value)
      write_byte(addr, @a)
    end

    # Store X
    def stx(instruction, addr, value)
      write_byte(addr, @x)
    end

    # Store Y
    def sty(instruction, addr, value)
      write_byte(addr, @y)
    end

    # Transfer accumulator to X
    def tax(instruction, addr, value)
      cycle { @x = a }
      update_number_flags(@x)
    end

    # Transfer accumulator to Y
    def tay(instruction, addr, value)
      cycle { @y = a }
      update_number_flags(@y)
    end

    # Transfer stack pointer to X
    def tsx(instruction, addr, value)
      cycle { @x = stack_pointer }
      update_number_flags(@x)
    end

    # Transfer X to accumulator
    def txa(instruction, addr, operand)
      cycle { @a = x }
      update_number_flags(@a)
    end

    # Transfer X to stack pointer
    def txs(instruction, addr, operand)
      cycle { @stack_pointer = x }
      update_number_flags(@stack_pointer)
    end

    # Transfer Y to accumulator
    def tya(instruction, addr, operand)
      cycle { @a = y }
      update_number_flags(@a)
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
      if value.kind_of?(Uint16)
        write_byte(stack_address, value.high)
        write_byte(stack_address - 1, value.low)
        cycle { @stack_pointer -= 2 }
      else
        write_byte(stack_address, value)
        cycle { @stack_pointer -= 1 }
      end
    end

    def update_number_flags(value)
      status.zero = (value == 0)
      status.negative = (value >> 7 == 1)
    end

    def write_byte(addr, value)
      if addr == :accumulator
        @a = value
      else
        cycle { memory[addr] = value }
      end
    end
  end
end
