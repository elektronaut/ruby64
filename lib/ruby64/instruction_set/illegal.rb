# frozen_string_literal: true

module Ruby64
  module InstructionSet
    # Illegal opcodes
    module Illegal
      # Combination of AND and LSR.
      #
      # Opcodes:
      #   $4B - immediate - 2 cycles
      def alr(_addr, value)
        @a &= resolve(value)
        status.carry = @a[0]
        @a = (@a >> 1) & 0xff
        update_number_flags(@a)
      end

      # Combination of AND where carry is set to bit 7 of result.
      #
      # Opcodes:
      #   $0B, $2B - immediate - 2 cycles
      def anc(addr, value)
        self.and(addr, value)
        status.carry = status.negative
      end

      # Unstable instruction. AND's value with A|magic_const and X.
      # Magic constant varies by CPU.
      #
      # Opcodes:
      #   $8B - immediate - 2 cycles
      def ane(_addr, value)
        magic_const = 0xee
        @a = (a | magic_const) & x & resolve(value)
        update_number_flags(@a)
      end

      # Combination of AND and ROR.
      #
      # Opcodes:
      #   $6B - immediate - 2 cycles
      def arr(_addr, value)
        tmp = a & resolve(value)
        result = (tmp >> 1) | (status.carry? ? 0x80 : 0)
        status.zero = result.zero?
        status.negative = status.carry

        if status.decimal?
          status.overflow = (result ^ tmp).anybits?(0x40)

          # Low nibble
          if ((tmp & 0x0f) + (tmp & 0x01)) > 0x05
            result = (result & 0xf0) | ((result + 0x06) & 0x0f)
          end

          # High nibble + carry
          if ((tmp & 0xf0) + (tmp & 0x10)) > 0x50
            result = (result & 0x0f) | ((result + 0x60) & 0xf0)
            status.carry = true
          else
            status.carry = false
          end
        else
          status.carry = tmp[7] == 1
          status.overflow = tmp[7] ^ tmp[6]
        end

        @a = result
      end

      # Combination of DEC and CMP operations.
      #
      # Opcodes:
      #   $C3 - indirect_x - 8 cycles
      #   $C7 - zeropage   - 5 cycles
      #   $CF - absolute   - 6 cycles
      #   $D3 - indirect_y - 8 cycles
      #   $D7 - zeropage_x - 6 cycles
      #   $DB - absolute_y - 7 cycles
      #   $DF - absolute_x - 7 cycles
      def dcp(addr, value)
        cmp(addr, dec(addr, value))
      end

      # Combination of INC and SBC operations.
      #
      # Opcodes:
      #   $E3 - indirect_x - 8 cycles
      #   $E7 - zeropage   - 5 cycles
      #   $EF - absolute   - 6 cycles
      #   $F3 - indirect_y - 8 cycles
      #   $F7 - zeropage_x - 6 cycles
      #   $FB - absolute_y - 7 cycles
      #   $FF - absolute_x - 7 cycles
      def isc(addr, value)
        sbc(addr, inc(addr, value))
      end

      # Freezes the CPU by forcing an infinite loop.
      #
      # Opcodes:
      #   $02, $12, $22, $32, $42, $52, $62, $72, $92, $B2, $D2, $F2
      def jam(addr, value)
        # TODO: Handle jam
        # It is possible to implement with loop { cycle }, but makes
        # testing problematic.
        10.times { cycle }
      end

      # Loads A and S with value AND stack pointer.
      #
      # Opcodes:
      #   $BB - absolute_y - 4 cycles
      def las(_addr, value)
        @a = @x = @stack_pointer = resolve(value) & stack_pointer
        update_number_flags(@a)
      end

      # Combination of LDA and LDX with same value.
      #
      # Opcodes:
      #   $A3 - indirect_x - 6 cycles
      #   $A7 - zeropage   - 3 cycles
      #   $AB - immediate  - 2 cycles # TODO: Not working
      #   $AF - absolute   - 4 cycles
      #   $B3 - indirect_y - 5+ cycles
      #   $B7 - zeropage_y - 4 cycles
      #   $BF - absolute_y - 4+ cycles
      def lax(_addr, value)
        @a = @x = resolve(value)

        update_number_flags(@a)
      end

      # Special no-operation instruction that does not consume a CPU cycle,
      # unlike the standard NOP. Used by some illegal opcodes.
      #
      # Opcodes:
      #   $80, $82, $89, $C2, $E2 - immediate - 2 cycles
      def nop_nocycle(_addr, _value); end

      # Combination of ROL and AND operations.
      #
      # Opcodes:
      #   $23 - indirect_x - 8 cycles
      #   $27 - zeropage   - 5 cycles
      #   $2F - absolute   - 6 cycles
      #   $33 - indirect_y - 8 cycles
      #   $37 - zeropage_x - 6 cycles
      #   $3B - absolute_y - 7 cycles
      #   $3F - absolute_x - 7 cycles
      def rla(addr, value)
        self.and(addr, rol(addr, value))
      end

      # Combination of ROR and ADC operations.
      #
      # Opcodes:
      #   $63 - indirect_x - 8 cycles
      #   $67 - zeropage   - 5 cycles
      #   $6F - absolute   - 6 cycles
      #   $73 - indirect_y - 8 cycles
      #   $77 - zeropage_x - 6 cycles
      #   $7B - absolute_y - 7 cycles
      #   $7F - absolute_x - 7 cycles
      def rra(addr, value)
        adc(addr, ror(addr, value))
      end

      # Store A AND X.
      #
      # Opcodes:
      #   $83 - indirect_x - 6 cycles
      #   $87 - zeropage   - 3 cycles
      #   $8F - absolute   - 4 cycles
      #   $97 - zeropage_y - 4 cycles
      def sax(addr, _value)
        write_byte(addr, @a & @x)
      end

      # AND X register with accumulator and subtract value.
      #
      # Opcodes:
      #   $CB - immediate - 2 cycles
      def sbx(_addr, value)
        v = resolve(value)
        result = (@x & @a) - v
        status.carry = result >= 0
        @x = result & 0xff
        update_number_flags(@x)
      end

      # Stores A AND X AND (high byte of addr + 1) at addr.
      #
      # Opcodes:
      #   $93 - indirect_y - 6 cycles
      #   $9F - absolute_y - 5 cycles
      def sha(addr, _value)
        result = a & x & (high_byte(addr) + 1)
        target = if boundary_crossed # TODO: This is not quite right.
                   uint16(low_byte(addr), result & high_byte(addr))
                 else
                   addr
                 end
        write_byte(target, result)
      end

      # Stores X AND (high byte of addr + 1) at addr.
      #
      # Opcodes:
      #   $9E - absolute_y - 5 cycles
      def shx(addr, _value)
        result = x & (high_byte(addr) + 1)
        target = if boundary_crossed # TODO: This is not quite right.
                   uint16(low_byte(addr), result & high_byte(addr))
                 else
                   addr
                 end
        write_byte(target, result)
      end

      # Stores Y AND (high byte of addr + 1) at addr.
      #
      # Opcodes:
      #   $9C - absolute_x - 5 cycles
      def shy(addr, _value)
        result = y & (high_byte(addr) + 1)
        target = if boundary_crossed # TODO: This is not quite right.
                   uint16(low_byte(addr), result & high_byte(addr))
                 else
                   addr
                 end
        write_byte(target, result)
      end

      # Combination of ASL and ORA operations.
      #
      # Opcodes:
      #   $03 - indirect_x - 8 cycles
      #   $07 - zeropage   - 5 cycles
      #   $0F - absolute   - 6 cycles
      #   $13 - indirect_y - 8 cycles
      #   $17 - zeropage_x - 6 cycles
      #   $1B - absolute_y - 7 cycles
      #   $1F - absolute_x - 7 cycles
      def slo(addr, value)
        ora(addr, asl(addr, value))
      end

      # Combination of LSR and EOR operations.
      #
      # Opcodes:
      #   $43 - indirect_x - 8 cycles
      #   $47 - zeropage   - 5 cycles
      #   $4F - absolute   - 6 cycles
      #   $53 - indirect_y - 8 cycles
      #   $57 - zeropage_x - 6 cycles
      #   $5B - absolute_y - 7 cycles
      #   $5F - absolute_x - 7 cycles
      def sre(addr, value)
        eor(addr, lsr(addr, value))
      end

      # Stores A AND X in SP, then stores SP AND (high byte + 1) at addr.
      #
      # Opcodes:
      #   $9B - absolute_y - 5 cycles
      def tas(addr, _value)
        @stack_pointer = @a & @x
        result = stack_pointer & (high_byte(addr) + 1)
        target = if boundary_crossed # TODO: This is not quite right.
                   uint16(low_byte(addr), result & high_byte(addr))
                 else
                   addr
                 end
        write_byte(target, result)
      end
    end
  end
end
