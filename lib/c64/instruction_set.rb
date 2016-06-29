module C64
  module InstructionSet
    class << self
      def map
        {
          0x00 => :brk, # implied
          0x01 => :ora, # X, indirect
          0x02 => :x,
          0x03 => :x,
          0x04 => :x,
          0x05 => :ora, # zeropage
          0x06 => :asl, # zeropage
          0x07 => :x,
          0x08 => :php, # implied
          0x09 => :ora, # immediate
          0x0a => :asl, # A
          0x0b => :x,
          0x0c => :x,
          0x0d => :ora, # absolute
          0x0e => :asl, # absolute
          0x0f => :x, #

          0x10 => :bpl, # relative
          0x11 => :ora, # indirect, Y
          0x12 => :x,
          0x13 => :x,
          0x14 => :x,
          0x15 => :ora, # zeropage, X
          0x16 => :asl, # zeropage, X
          0x17 => :x,
          0x18 => :clc, # implied
          0x19 => :ora, # absolute, Y
          0x1a => :x,
          0x1b => :x,
          0x1c => :x,
          0x1d => :ora, # absolute, X
          0x1e => :asl, # absolute, X
          0x1f => :x,

          0x20 => :jsr, # absolute
          0x21 => :and, # X, indirect
          0x22 => :x,
          0x23 => :x,
          0x24 => :bit, # zeropage
          0x25 => :and, # zeropage
          0x26 => :rol, # zeropage
          0x27 => :x,
          0x28 => :plp, # implied
          0x29 => :and, # immediate
          0x2a => :rol, # immediate
          0x2b => :x,
          0x2c => :bit, # absolute
          0x2d => :and, # absolute
          0x2e => :rol, # absolute
          0x2f => :x,

          0x30 => :bmi, # relative
          0x31 => :and, # indirect, Y
          0x32 => :x,
          0x33 => :x,
          0x34 => :x,
          0x35 => :and, # zeropage, X
          0x36 => :rol, # zeropage, X
          0x37 => :x,
          0x38 => :sec, # implied
          0x39 => :and, # absolute, Y
          0x3a => :x,
          0x3b => :x,
          0x3c => :x,
          0x3d => :and, # absolute, X
          0x3e => :rol, # absolute, X
          0x3f => :x,
        }
      end
    end

    # Add with carry
    def adc
      raise "TODO"
    end

    # And (with accumulator)
    def and
      raise "TODO"
    end

    # Arithmetic shift left
    def asl
      raise "TODO"
    end

    # Branch on carry clear
    def bcc
      raise "TODO"
    end

    # Branch on carry set
    def bcs
      raise "TODO"
    end

    # Branch on equal (zero set)
    def beq
      raise "TODO"
    end

    # Bit test
    def bit
      raise "TODO"
    end

    # Branch on minus (negative set)
    def bmi
      raise "TODO"
    end

    # Branch on not equal (zero clear)
    def bne
      raise "TODO"
    end

    # Branch on plus (negative clear)
    def bpl
      raise "TODO"
    end

    # Interrupt
    def brk
      raise "TODO"
    end

    # Branch on overflow clear
    def bvc
      raise "TODO"
    end

    # Branch on overflow set
    def bvs
      raise "TODO"
    end

    # Clear carry
    def clc
      raise "TODO"
    end

    # Clear decimal
    def cld
      raise "TODO"
    end

    # Clear interrupt disable
    def cli
      raise "TODO"
    end

    # Clear overflow
    def clv
      raise "TODO"
    end

    # Compare (with accumulator)
    def cmp
      raise "TODO"
    end

    # Compare with X
    def cpx
      raise "TODO"
    end

    # Compare with Y
    def cpy
      raise "TODO"
    end

    # Decrement
    def dec
      raise "TODO"
    end

    # Decrement X
    def dex
      raise "TODO"
    end

    # Decrement Y
    def dey
      raise "TODO"
    end

    # Exclusive or (with accumulator)
    def eor
      raise "TODO"
    end

    # Increment
    def inc
      raise "TODO"
    end

    # Increment X
    def inx
      raise "TODO"
    end

    # Increment Y
    def iny
      raise "TODO"
    end

    # Jump
    def jmp
      raise "TODO"
    end

    # Jump subroutine
    def jsr
      raise "TODO"
    end

    # Load accumulator
    def lda
      raise "TODO"
    end

    # Load X
    def ldy
      raise "TODO"
    end

    # Load Y
    def ldy
      raise "TODO"
    end

    # Logical shift right
    def lsr
      raise "TODO"
    end

    # No operation
    def nop
      raise "TODO"
    end

    # Or with accumulator
    def ora
      raise "TODO"
    end

    # Push accumulator
    def pha
      raise "TODO"
    end

    # Push processor status (SR)
    def php
      raise "TODO"
    end

    # Pull accumulator
    def pla
      raise "TODO"
    end

    # Pull processor status (SR)
    def plp
      raise "TODO"
    end

    # Rotate left
    def rol
      raise "TODO"
    end

    # Rotate right
    def ror
      raise "TODO"
    end

    # Return from interrupt
    def rti
      raise "TODO"
    end

    # Return from subroutine
    def rts
      raise "TODO"
    end

    # Subtract with carry
    def sbc
      raise "TODO"
    end

    # Set carry
    def sec
      raise "TODO"
    end

    # Set decimal
    def sed
      raise "TODO"
    end

    # Set interrupt disable
    def sei
      raise "TODO"
    end

    # Store accumulator
    def sta
      raise "TODO"
    end

    # Store X
    def stx
      raise "TODO"
    end

    # Store Y
    def sty
      raise "TODO"
    end

    # Transfer accumulator to X
    def tax
      raise "TODO"
    end

    # Transfer accumulator to Y
    def tay
      raise "TODO"
    end

    # Transfer stack pointer to X
    def tsx
      raise "TODO"
    end

    # Transfer X to accumulator
    def txa
      raise "TODO"
    end

    # Transfer X to stack pointer
    def txs
      raise "TODO"
    end

    # Transfer Y to accumulator
    def tya
      raise "TODO"
    end
  end
end
