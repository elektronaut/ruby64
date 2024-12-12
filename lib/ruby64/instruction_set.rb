# frozen_string_literal: true

module Ruby64
  # http://www.6502.org/tutorials/6502opcodes.html
  # http://www.e-tradition.net/bytes/6502/6502_instruction_set.html
  module InstructionSet
    # Add with carry.
    def adc(_addr, value)
      v = value.call
      result = a + v + status.carry
      status.zero = result.nobits?(0xff)

      if status.decimal?
        result = (a & 0x0f) + (v & 0x0f) + status.carry
        result += 0x06 if result > 0x09
        c = result > 0x0f ? 1 : 0
        result = (a & 0xf0) + (v & 0xf0) + (c << 4) + (result & 0x0f)
        update_calculation_flags(v, result)
        result += 0x60 if result > 0x9f
      else
        update_calculation_flags(v, result)
      end

      status.carry = result > 0xff
      @a = result & 0xff
    end

    # And (with accumulator)
    def and(_addr, value)
      @a &= value.call
      update_number_flags(@a)
    end

    # Arithmetic shift left
    def asl(addr, value)
      v = value.call
      result = (v << 1) & 0xff
      status.carry = v[7]
      cycle { write_byte(addr, result) }
      update_number_flags(result)
    end

    # Branch on carry clear
    def bcc(addr, _value)
      branch(addr) unless status.carry?
    end

    # Branch on carry set
    def bcs(addr, _value)
      branch(addr) if status.carry?
    end

    # Branch on equal (zero set)
    def beq(addr, _value)
      branch(addr) if status.zero?
    end

    # Bit test
    def bit(_addr, value)
      v = value.call
      status.value = ((status.value & 0b00111111) +
                      (v & 0b11000000)).to_i
      status.zero = (a & v).nobits?(0xff)
    end

    # Branch on minus (negative set)
    def bmi(addr, _value)
      branch(addr) if status.negative?
    end

    # Branch on not equal (zero clear)
    def bne(addr, _value)
      branch(addr) unless status.zero?
    end

    # Branch on plus (negative clear)
    def bpl(addr, _value)
      branch(addr) unless status.negative?
    end

    # Interrupt
    def brk(_addr, _value)
      status.break = true
      handle_interrupt(0xfffe, 1) # unless status.interrupt?
      status.break = false
    end

    # Branch on overflow clear
    def bvc(addr, _value)
      branch(addr) unless status.overflow?
    end

    # Branch on overflow set
    def bvs(addr, _value)
      branch(addr) if status.overflow?
    end

    # Clear carry
    def clc(_addr, _value)
      cycle { status.carry = false }
    end

    # Clear decimal
    def cld(_addr, _value)
      cycle { status.decimal = false }
    end

    # Clear interrupt disable
    def cli(_addr, _value)
      cycle { status.interrupt = false }
    end

    # Clear overflow
    def clv(_addr, _value)
      cycle { status.overflow = false }
    end

    # Compare (with accumulator)
    def cmp(_addr, value)
      v = value.call
      status.carry = (@a >= v)
      update_number_flags(@a - v)
    end

    # Compare with X
    def cpx(_addr, value)
      v = value.call
      status.carry = @x >= v
      update_number_flags(@x - v)
    end

    # Compare with Y
    def cpy(_addr, value)
      v = value.call
      status.carry = @y >= v
      update_number_flags(@y - v)
    end

    # Decrement
    def dec(addr, value)
      v = cycle { value.call - 1 } & 0xff
      write_byte(addr, v)
      update_number_flags(v)
    end

    # Decrement X
    def dex(_addr, _value)
      cycle { @x = (@x - 1) & 0xff }
      update_number_flags(@x)
    end

    # Decrement Y
    def dey(_addr, _value)
      cycle { @y = (@y - 1) & 0xff }
      update_number_flags(@y)
    end

    # Exclusive or (with accumulator)
    def eor(_addr, value)
      @a = (@a ^ value.call) & 0xff
      update_number_flags(@a)
    end

    # Increment
    def inc(addr, value)
      v = cycle { (value.call + 1) & 0xff }
      write_byte(addr, v)
      update_number_flags(v)
    end

    # Increment X
    def inx(_addr, _value)
      cycle { @x = (@x + 1) & 0xff }
      update_number_flags(@x)
    end

    # Increment Y
    def iny(_addr, _value)
      cycle { @y = (@y + 1) & 0xff }
      update_number_flags(@y)
    end

    # Jump to new location
    def jmp(addr, _value)
      @program_counter = addr
    end

    # Jump subroutine
    def jsr(addr, _value)
      stack_push16((program_counter - 1) & 0xffff)

      @program_counter = uint16(
        low_byte(addr),
        # In case we're running inside the stack for some reason, compensate
        # for the fact that pushing the program counter has garbled our
        # program.
        memory[(program_counter - 1) & 0xffff]
      )
    end

    # Load accumulator
    def lda(_addr, value)
      @a = value.call
      update_number_flags(@a)
    end

    # Load X
    def ldx(_addr, value)
      @x = value.call
      update_number_flags(@x)
    end

    # Load Y
    def ldy(_addr, value)
      @y = value.call
      update_number_flags(@y)
    end

    # Logical shift right
    def lsr(addr, value)
      v = value.call
      result = (v >> 1) & 0xff
      status.carry = v[0]
      cycle { write_byte(addr, result) }
      update_number_flags(result)
    end

    # No operation
    def nop(_addr, _value)
      cycle { nil }
    end

    # Or with accumulator
    def ora(_addr, value)
      @a |= value.call
      update_number_flags(@a)
    end

    # Push accumulator
    def pha(_addr, _value)
      stack_push(@a)
    end

    # Push processor status (SR)
    def php(_addr, _value)
      stack_push(p | 0b00010000)
    end

    # Pull accumulator
    def pla(_addr, _value)
      cycle { @a = stack_pull }
      update_number_flags(@a)
    end

    # Pull processor status (SR)
    def plp(_addr, _value)
      cycle { status.value = stack_pull & 0b11101111 }
    end

    # Rotate left
    def rol(addr, value)
      v = value.call
      result = ((v << 1) + status.carry) & 0xff
      status.carry = v[7]
      cycle { write_byte(addr, result) }
      update_number_flags(result)
    end

    # Rotate right
    def ror(addr, value)
      v = value.call
      result = ((v >> 1) + (status.carry? ? 0x80 : 0)) & 0xff
      status.carry = v[0]
      cycle { write_byte(addr, result) }
      update_number_flags(result)
    end

    # Return from interrupt
    def rti(_addr, _value)
      cycle do
        @stack_pointer = (@stack_pointer + 1) & 0xff
        @status.value = memory[stack_address]
        @status.break = false
      end
      @program_counter = uint16(stack_pull, stack_pull)
    end

    # Return from subroutine
    def rts(_addr, _value)
      cycle do
        @program_counter = (uint16(stack_pull, stack_pull) + 1) & 0xffff
      end
    end

    # Subtract with carry
    def sbc(_addr, value)
      v = value.call
      v_inv = ~v & 0xff
      carry = status.carry? ? 0 : -1

      result = a + v_inv + status.carry
      status.zero = result.nobits?(0xff)
      status.carry = result > 0xff
      update_calculation_flags(v_inv, result)

      if status.decimal?
        al = (a & 0x0f) - (v & 0x0f) + carry
        al = ((al - 0x06) & 0x0F) - 0x10 if al.negative?

        result = (a & 0xf0) - (v & 0xf0) + al
        result -= 0x60 if result.negative?
      end

      @a = result & 0xff
    end

    # Set carry
    def sec(_addr, _value)
      cycle { status.carry = true }
    end

    # Set decimal
    def sed(_addr, _value)
      cycle { status.decimal = true }
    end

    # Set interrupt disable
    def sei(_addr, _value)
      cycle { status.interrupt = true }
    end

    # Store accumulator
    def sta(addr, _value)
      write_byte(addr, @a)
    end

    # Store X
    def stx(addr, _value)
      write_byte(addr, @x)
    end

    # Store Y
    def sty(addr, _value)
      write_byte(addr, @y)
    end

    # Transfer accumulator to X
    def tax(_addr, _value)
      cycle { @x = a }
      update_number_flags(@x)
    end

    # Transfer accumulator to Y
    def tay(_addr, _value)
      cycle { @y = a }
      update_number_flags(@y)
    end

    # Transfer stack pointer to X
    def tsx(_addr, _value)
      cycle { @x = stack_pointer }
      update_number_flags(@x)
    end

    # Transfer X to accumulator
    def txa(_addr, _operand)
      cycle { @a = x }
      update_number_flags(@a)
    end

    # Transfer X to stack pointer
    def txs(_addr, _operand)
      cycle { @stack_pointer = x }
    end

    # Transfer Y to accumulator
    def tya(_addr, _operand)
      cycle { @a = y }
      update_number_flags(@a)
    end

    private

    def branch(addr)
      cycle if high_byte(addr) != high_byte(@program_counter)
      cycle { @program_counter = addr }
    end

    def stack_pull
      cycle { @stack_pointer = (@stack_pointer + 1) & 0xff }
      read_byte(stack_address)
    end

    def stack_push(value)
      write_byte(stack_address, value)
      cycle { @stack_pointer = (@stack_pointer - 1) & 0xff }
    end

    def stack_push16(value)
      write_byte(stack_address, high_byte(value))
      write_byte(stack_address(-1), low_byte(value))
      cycle { @stack_pointer = (@stack_pointer - 2) & 0xff }
    end

    def update_calculation_flags(value, result)
      status.negative = result.anybits?(0x80)
      status.overflow = (a ^ value).nobits?(0x80) &&
                        (a ^ result).anybits?(0x80)
    end

    def update_number_flags(value)
      status.zero = value.zero?
      status.negative = value.anybits?(0x80)
    end
  end
end
