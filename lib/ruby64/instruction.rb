# frozen_string_literal: true

module Ruby64
  class Instruction
    attr_reader :name, :addressing_mode

    def initialize(name, addressing_mode)
      @name = name
      @addressing_mode = addressing_mode
    end

    class << self
      def map
        @map ||= {
          0x00 => new(:brk, :implied),
          0x01 => new(:ora, :indirect_x),
          0x05 => new(:ora, :zeropage),
          0x06 => new(:asl, :zeropage),
          0x08 => new(:php, :implied),
          0x09 => new(:ora, :immediate),
          0x0a => new(:asl, :accumulator),
          0x0d => new(:ora, :absolute),
          0x0e => new(:asl, :absolute),
          0x10 => new(:bpl, :relative),
          0x11 => new(:ora, :indirect_y),
          0x15 => new(:ora, :zeropage_x),
          0x16 => new(:asl, :zeropage_x),
          0x18 => new(:clc, :implied),
          0x19 => new(:ora, :absolute_y),
          0x1d => new(:ora, :absolute_x),
          0x1e => new(:asl, :absolute_x),
          0x20 => new(:jsr, :absolute),
          0x21 => new(:and, :indirect_x),
          0x24 => new(:bit, :zeropage),
          0x25 => new(:and, :zeropage),
          0x26 => new(:rol, :zeropage),
          0x28 => new(:plp, :implied),
          0x29 => new(:and, :immediate),
          0x2a => new(:rol, :accumulator),
          0x2c => new(:bit, :absolute),
          0x2d => new(:and, :absolute),
          0x2e => new(:rol, :absolute),
          0x30 => new(:bmi, :relative),
          0x31 => new(:and, :indirect_y),
          0x35 => new(:and, :zeropage_x),
          0x36 => new(:rol, :zeropage_x),
          0x38 => new(:sec, :implied),
          0x39 => new(:and, :absolute_y),
          0x3d => new(:and, :absolute_x),
          0x3e => new(:rol, :absolute_x),
          0x40 => new(:rti, :implied),
          0x41 => new(:eor, :indirect_x),
          0x45 => new(:eor, :zeropage),
          0x46 => new(:lsr, :zeropage),
          0x48 => new(:pha, :implied),
          0x49 => new(:eor, :immediate),
          0x4a => new(:lsr, :accumulator),
          0x4c => new(:jmp, :absolute),
          0x4d => new(:eor, :absolute),
          0x4e => new(:lsr, :absolute),
          0x50 => new(:bvc, :relative),
          0x51 => new(:eor, :indirect_y),
          0x55 => new(:eor, :zeropage_x),
          0x56 => new(:lsr, :zeropage_x),
          0x58 => new(:cli, :implied),
          0x59 => new(:eor, :absolute_y),
          0x5d => new(:eor, :absolute_x),
          0x5e => new(:lsr, :absolute_x),
          0x60 => new(:rts, :implied),
          0x61 => new(:adc, :indirect_x),
          0x65 => new(:adc, :zeropage),
          0x66 => new(:ror, :zeropage),
          0x68 => new(:pla, :implied),
          0x69 => new(:adc, :immediate),
          0x6a => new(:ror, :accumulator),
          0x6c => new(:jmp, :indirect),
          0x6d => new(:adc, :absolute),
          0x6e => new(:ror, :absolute),
          0x70 => new(:bvs, :relative),
          0x71 => new(:adc, :indirect_y),
          0x75 => new(:adc, :zeropage_x),
          0x76 => new(:ror, :zeropage_x),
          0x78 => new(:sei, :implied),
          0x79 => new(:adc, :absolute_y),
          0x7d => new(:adc, :absolute_x),
          0x7e => new(:ror, :absolute_x),
          0x81 => new(:sta, :indirect_x),
          0x84 => new(:sty, :zeropage),
          0x85 => new(:sta, :zeropage),
          0x86 => new(:stx, :zeropage),
          0x88 => new(:dey, :implied),
          0x8a => new(:txa, :implied),
          0x8c => new(:sty, :absolute),
          0x8d => new(:sta, :absolute),
          0x8e => new(:stx, :absolute),
          0x90 => new(:bcc, :relative),
          0x91 => new(:sta, :indirect_y),
          0x94 => new(:sty, :zeropage_x),
          0x95 => new(:sta, :zeropage_x),
          0x96 => new(:stx, :zeropage_y),
          0x98 => new(:tya, :implied),
          0x99 => new(:sta, :absolute_y),
          0x9a => new(:txs, :implied),
          0x9d => new(:sta, :absolute_x),
          0xa0 => new(:ldy, :immediate),
          0xa1 => new(:lda, :indirect_x),
          0xa2 => new(:ldx, :immediate),
          0xa4 => new(:ldy, :zeropage),
          0xa5 => new(:lda, :zeropage),
          0xa6 => new(:ldx, :zeropage),
          0xa8 => new(:tay, :implied),
          0xa9 => new(:lda, :immediate),
          0xaa => new(:tax, :implied),
          0xac => new(:ldy, :absolute),
          0xad => new(:lda, :absolute),
          0xae => new(:ldx, :absolute),
          0xb0 => new(:bcs, :relative),
          0xb1 => new(:lda, :indirect_y),
          0xb4 => new(:ldy, :zeropage_x),
          0xb5 => new(:lda, :zeropage_x),
          0xb6 => new(:ldx, :zeropage_y),
          0xb8 => new(:clv, :implied),
          0xb9 => new(:lda, :absolute_y),
          0xba => new(:tsx, :implied),
          0xbc => new(:ldy, :absolute_x),
          0xbd => new(:lda, :absolute_x),
          0xbe => new(:ldx, :absolute_y),
          0xc0 => new(:cpy, :immediate),
          0xc1 => new(:cmp, :indirect_x),
          0xc4 => new(:cpy, :zeropage),
          0xc5 => new(:cmp, :zeropage),
          0xc6 => new(:dec, :zeropage),
          0xc8 => new(:iny, :implied),
          0xc9 => new(:cmp, :immediate),
          0xca => new(:dex, :implied),
          0xcc => new(:cpy, :absolute),
          0xcd => new(:cmp, :absolute),
          0xce => new(:dec, :absolute),
          0xd0 => new(:bne, :relative),
          0xd1 => new(:cmp, :indirect_y),
          0xd5 => new(:cmp, :zeropage_x),
          0xd6 => new(:dec, :zeropage_x),
          0xd8 => new(:cld, :implied),
          0xd9 => new(:cmp, :absolute_y),
          0xdd => new(:cmp, :absolute_x),
          0xde => new(:dec, :absolute_x),
          0xe0 => new(:cpx, :immediate),
          0xe1 => new(:sbc, :indirect_x),
          0xe4 => new(:cpx, :zeropage),
          0xe5 => new(:sbc, :zeropage),
          0xe6 => new(:inc, :zeropage),
          0xe8 => new(:inx, :implied),
          0xe9 => new(:sbc, :immediate),
          0xea => new(:nop, :implied),
          0xec => new(:cpx, :absolute),
          0xed => new(:sbc, :absolute),
          0xee => new(:inc, :absolute),
          0xf0 => new(:beq, :relative),
          0xf1 => new(:sbc, :indirect_y),
          0xf5 => new(:sbc, :zeropage_x),
          0xf6 => new(:inc, :zeropage_x),
          0xf8 => new(:sed, :implied),
          0xf9 => new(:sbc, :absolute_y),
          0xfd => new(:sbc, :absolute_x),
          0xfe => new(:inc, :absolute_x)
        }
      end

      def find(opcode)
        map[opcode.to_i]
      end
    end

    def length
      1 + operand_length
    end

    def operand?
      operand_length.positive?
    end

    def operand_length
      case addressing_mode
      when :implied, :accumulator
        0
      when :immediate, :relative, :zeropage, :zeropage_x, :zeropage_y,
          :indirect_x, :indirect_y
        1
      when :absolute, :absolute_x, :absolute_y, :indirect
        2
      end
    end
  end
end
