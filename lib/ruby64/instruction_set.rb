# frozen_string_literal: true

module Ruby64
  # http://www.6502.org/tutorials/6502opcodes.html
  # http://www.e-tradition.net/bytes/6502/6502_instruction_set.html
  module InstructionSet
    # Add with carry.
    def adc(_instruction, _addr, value)
      raise "BCD mode not implemented yet" if status.decimal?

      v = value.call
      result = a.to_i + v.to_i + status.carry
      signed_result = Uint8.new(a).signed + v.signed + status.carry
      status.carry = result > 0xff
      status.overflow = !(-128..127).cover?(signed_result)
      @a = Uint8.new(result)
      update_number_flags(@a)
    end

    # And (with accumulator)
    def and(_instruction, _addr, value)
      @a &= value.call
      update_number_flags(@a)
    end

    # Arithmetic shift left
    def asl(instruction, addr, value)
      cycle if instruction.addressing_mode == :absolute_x
      v = value.call
      result = Uint8.new(v << 1)
      status.carry = v[7]
      cycle { write_byte(addr, result) }
      update_number_flags(result)
    end

    # Branch on carry clear
    def bcc(_instruction, addr, _value)
      branch(addr) unless status.carry?
    end

    # Branch on carry set
    def bcs(_instruction, addr, _value)
      branch(addr) if status.carry?
    end

    # Branch on equal (zero set)
    def beq(_instruction, addr, _value)
      branch(addr) if status.zero?
    end

    # Bit test
    def bit(_instruction, _addr, value)
      v = value.call
      status.value = ((status.value & 0b00111111) +
                      (v & 0b11000000)).to_i
      status.zero = Uint8.new(a & v).zero?
    end

    # Branch on minus (negative set)
    def bmi(_instruction, addr, _value)
      branch(addr) if status.negative?
    end

    # Branch on not equal (zero clear)
    def bne(_instruction, addr, _value)
      branch(addr) unless status.zero?
    end

    # Branch on plus (negative clear)
    def bpl(_instruction, addr, _value)
      branch(addr) unless status.negative?
    end

    # Interrupt
    def brk(_instruction, _addr, _value)
      6.times { cycle }
      status.break = true
    end

    # Branch on overflow clear
    def bvc(_instruction, addr, _value)
      branch(addr) unless status.overflow?
    end

    # Branch on overflow set
    def bvs(_instruction, addr, _value)
      branch(addr) if status.overflow?
    end

    # Clear carry
    def clc(_instruction, _addr, _value)
      cycle { status.carry = false }
    end

    # Clear decimal
    def cld(_instruction, _addr, _value)
      cycle { status.decimal = false }
    end

    # Clear interrupt disable
    def cli(_instruction, _addr, _value)
      cycle { status.interrupt = false }
    end

    # Clear overflow
    def clv(_instruction, _addr, _value)
      cycle { status.overflow = false }
    end

    # Compare (with accumulator)
    def cmp(_instruction, _addr, value)
      v = value.call
      status.carry = (@a >= v)
      update_number_flags(@a - v)
    end

    # Compare with X
    def cpx(_instruction, _addr, value)
      v = value.call
      status.carry = @x >= v
      update_number_flags(@x - v)
    end

    # Compare with Y
    def cpy(_instruction, _addr, value)
      v = value.call
      status.carry = @y >= v
      update_number_flags(@y - v)
    end

    # Decrement
    def dec(instruction, addr, value)
      cycle if instruction.addressing_mode == :absolute_x
      v = cycle { value.call - 1 }
      write_byte(addr, v)
      update_number_flags(v)
    end

    # Decrement X
    def dex(_instruction, _addr, _value)
      cycle { @x -= 1 }
      update_number_flags(@x)
    end

    # Decrement Y
    def dey(_instruction, _addr, _value)
      cycle { @y -= 1 }
      update_number_flags(@y)
    end

    # Exclusive or (with accumulator)
    def eor(_instruction, _addr, value)
      @a ^= value.call
      update_number_flags(@a)
    end

    # Increment
    def inc(instruction, addr, value)
      cycle if instruction.addressing_mode == :absolute_x
      v = cycle { value.call + 1 }
      write_byte(addr, v)
      update_number_flags(v)
    end

    # Increment X
    def inx(_instruction, _addr, _value)
      cycle { @x += 1 }
      update_number_flags(@x)
    end

    # Increment Y
    def iny(_instruction, _addr, _value)
      cycle { @y += 1 }
      update_number_flags(@y)
    end

    # Jump to new location
    def jmp(_instruction, addr, _value)
      @program_counter = addr
    end

    # Jump subroutine
    def jsr(_instruction, addr, _value)
      stack_push(program_counter)
      @program_counter = addr
    end

    # Load accumulator
    def lda(_instruction, _addr, value)
      @a = value.call
      update_number_flags(@a)
    end

    # Load X
    def ldx(_instruction, _addr, value)
      @x = value.call
      update_number_flags(@x)
    end

    # Load Y
    def ldy(_instruction, _addr, value)
      @y = value.call
      update_number_flags(@y)
    end

    # Logical shift right
    def lsr(instruction, addr, value)
      cycle if instruction.addressing_mode == :absolute_x
      v = value.call
      result = Uint8.new(v >> 1)
      status.carry = v[0]
      cycle { write_byte(addr, result) }
      update_number_flags(result)
    end

    # No operation
    def nop(_instruction, _addr, _value)
      cycle { nil }
    end

    # Or with accumulator
    def ora(_instruction, _addr, value)
      @a |= value.call
      update_number_flags(@a)
    end

    # Push accumulator
    def pha(_instruction, _addr, _value)
      stack_push(@a)
    end

    # Push processor status (SR)
    def php(_instruction, _addr, _value)
      stack_push(p)
    end

    # Pull accumulator
    def pla(_instruction, _addr, _value)
      cycle { @a = stack_pull }
      update_number_flags(@a)
    end

    # Pull processor status (SR)
    def plp(_instruction, _addr, _value)
      cycle { status.value = stack_pull }
    end

    # Rotate left
    def rol(instruction, addr, value)
      cycle if instruction.addressing_mode == :absolute_x
      v = value.call
      result = Uint8.new((v << 1) + status.carry)
      status.carry = v[7]
      cycle { write_byte(addr, result) }
      update_number_flags(result)
    end

    # Rotate right
    def ror(instruction, addr, value)
      cycle if instruction.addressing_mode == :absolute_x
      v = value.call
      result = Uint8.new((v >> 1) + (status.carry? ? 0x80 : 0))
      status.carry = v[0]
      cycle { write_byte(addr, result) }
      update_number_flags(result)
    end

    # Return from interrupt
    def rti(_instruction, _addr, _value)
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
    def rts(_instruction, _addr, _value)
      cycle do
        @program_counter = Uint16.new(
          stack_pull,
          stack_pull
        )
      end
    end

    # Subtract with carry
    def sbc(_instruction, _addr, value)
      raise "BCD mode not implemented yet" if status.decimal?

      v = value.call
      result = a.to_i - v.to_i - status.carry
      signed_result = Uint8.new(a).signed - v.signed - status.carry
      status.carry = result.positive?
      status.overflow = !(-128..127).cover?(signed_result)
      @a = Uint8.new(result)
      update_number_flags(@a)
    end

    # Set carry
    def sec(_instruction, _addr, _value)
      cycle { status.carry = true }
    end

    # Set decimal
    def sed(_instruction, _addr, _value)
      cycle { status.decimal = true }
    end

    # Set interrupt disable
    def sei(_instruction, _addr, _value)
      cycle { status.interrupt = true }
    end

    # Store accumulator
    def sta(_instruction, addr, _value)
      write_byte(addr, @a)
    end

    # Store X
    def stx(_instruction, addr, _value)
      write_byte(addr, @x)
    end

    # Store Y
    def sty(_instruction, addr, _value)
      write_byte(addr, @y)
    end

    # Transfer accumulator to X
    def tax(_instruction, _addr, _value)
      cycle { @x = a }
      update_number_flags(@x)
    end

    # Transfer accumulator to Y
    def tay(_instruction, _addr, _value)
      cycle { @y = a }
      update_number_flags(@y)
    end

    # Transfer stack pointer to X
    def tsx(_instruction, _addr, _value)
      cycle { @x = stack_pointer }
      update_number_flags(@x)
    end

    # Transfer X to accumulator
    def txa(_instruction, _addr, _operand)
      cycle { @a = x }
      update_number_flags(@a)
    end

    # Transfer X to stack pointer
    def txs(_instruction, _addr, _operand)
      cycle { @stack_pointer = x }
      update_number_flags(@stack_pointer)
    end

    # Transfer Y to accumulator
    def tya(_instruction, _addr, _operand)
      cycle { @a = y }
      update_number_flags(@a)
    end

    private

    def branch(addr)
      cycle if addr.high != @program_counter.high
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
      if value.is_a?(Uint16)
        write_byte(stack_address, value.high)
        write_byte(stack_address - 1, value.low)
        cycle { @stack_pointer -= 2 }
      else
        write_byte(stack_address, value)
        cycle { @stack_pointer -= 1 }
      end
    end

    def update_number_flags(value)
      status.zero = value.zero?
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
