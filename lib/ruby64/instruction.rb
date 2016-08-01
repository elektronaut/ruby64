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
          0x00 => Instruction.new(:brk, :implied),
          0x01 => Instruction.new(:ora, :indirect_x),
          0x05 => Instruction.new(:ora, :zeropage),
          0x06 => Instruction.new(:asl, :zeropage),
          0x08 => Instruction.new(:php, :implied),
          0x09 => Instruction.new(:ora, :immediate),
          0x0a => Instruction.new(:asl, :accumulator),
          0x0d => Instruction.new(:ora, :absolute),
          0x0e => Instruction.new(:asl, :absolute),
          0x10 => Instruction.new(:bpl, :relative),
          0x11 => Instruction.new(:ora, :indirect_y),
          0x15 => Instruction.new(:ora, :zeropage_x),
          0x16 => Instruction.new(:asl, :zeropage_x),
          0x18 => Instruction.new(:clc, :implied),
          0x19 => Instruction.new(:ora, :absolute_y),
          0x1d => Instruction.new(:ora, :absolute_x),
          0x1e => Instruction.new(:asl, :absolute_x),
          0x20 => Instruction.new(:jsr, :absolute),
          0x21 => Instruction.new(:and, :indirect_x),
          0x24 => Instruction.new(:bit, :zeropage),
          0x25 => Instruction.new(:and, :zeropage),
          0x26 => Instruction.new(:rol, :zeropage),
          0x28 => Instruction.new(:plp, :implied),
          0x29 => Instruction.new(:and, :immediate),
          0x2a => Instruction.new(:rol, :accumulator),
          0x2c => Instruction.new(:bit, :absolute),
          0x2d => Instruction.new(:and, :absolute),
          0x2e => Instruction.new(:rol, :absolute),
          0x30 => Instruction.new(:bmi, :relative),
          0x31 => Instruction.new(:and, :indirect_y),
          0x35 => Instruction.new(:and, :zeropage_x),
          0x36 => Instruction.new(:rol, :zeropage_x),
          0x38 => Instruction.new(:sec, :implied),
          0x39 => Instruction.new(:and, :absolute_y),
          0x3d => Instruction.new(:and, :absolute_x),
          0x3e => Instruction.new(:rol, :absolute_x),
          0x40 => Instruction.new(:rti, :implied),
          0x41 => Instruction.new(:eor, :indirect_x),
          0x45 => Instruction.new(:eor, :zeropage),
          0x46 => Instruction.new(:lsr, :zeropage),
          0x48 => Instruction.new(:pha, :implied),
          0x49 => Instruction.new(:eor, :immediate),
          0x4a => Instruction.new(:lsr, :accumulator),
          0x4c => Instruction.new(:jmp, :absolute),
          0x4d => Instruction.new(:eor, :absolute),
          0x4e => Instruction.new(:lsr, :absolute),
          0x50 => Instruction.new(:bvc, :relative),
          0x51 => Instruction.new(:eor, :indirect_y),
          0x55 => Instruction.new(:eor, :zeropage_x),
          0x56 => Instruction.new(:lsr, :zeropage_x),
          0x58 => Instruction.new(:cli, :implied),
          0x59 => Instruction.new(:eor, :absolute_y),
          0x5d => Instruction.new(:eor, :absolute_x),
          0x5e => Instruction.new(:lsr, :absolute_x),
          0x60 => Instruction.new(:rts, :implied),
          0x61 => Instruction.new(:adc, :indirect_x),
          0x65 => Instruction.new(:adc, :zeropage),
          0x66 => Instruction.new(:ror, :zeropage),
          0x68 => Instruction.new(:pla, :implied),
          0x69 => Instruction.new(:adc, :immediate),
          0x6a => Instruction.new(:ror, :accumulator),
          0x6c => Instruction.new(:jmp, :indirect),
          0x6d => Instruction.new(:adc, :absolute),
          0x6e => Instruction.new(:ror, :absolute),
          0x70 => Instruction.new(:bvs, :relative),
          0x71 => Instruction.new(:adc, :indirect_y),
          0x75 => Instruction.new(:adc, :zeropage_x),
          0x76 => Instruction.new(:ror, :zeropage_x),
          0x78 => Instruction.new(:sei, :implied),
          0x79 => Instruction.new(:adc, :absolute_y),
          0x7d => Instruction.new(:adc, :absolute_x),
          0x7e => Instruction.new(:ror, :absolute_x),
          0x81 => Instruction.new(:sta, :indirect_x),
          0x84 => Instruction.new(:sty, :zeropage),
          0x85 => Instruction.new(:sta, :zeropage),
          0x86 => Instruction.new(:stx, :zeropage),
          0x88 => Instruction.new(:dey, :implied),
          0x8a => Instruction.new(:txa, :implied),
          0x8c => Instruction.new(:sty, :absolute),
          0x8d => Instruction.new(:sta, :absolute),
          0x8e => Instruction.new(:stx, :absolute),
          0x90 => Instruction.new(:bcc, :relative),
          0x91 => Instruction.new(:sta, :indirect_y),
          0x94 => Instruction.new(:sty, :zeropage_x),
          0x95 => Instruction.new(:sta, :zeropage_x),
          0x96 => Instruction.new(:stx, :zeropage_y),
          0x98 => Instruction.new(:tya, :implied),
          0x99 => Instruction.new(:sta, :absolute_y),
          0x9a => Instruction.new(:txs, :implied),
          0x9d => Instruction.new(:sta, :absolute_x),
          0xa0 => Instruction.new(:ldy, :immediate),
          0xa1 => Instruction.new(:lda, :indirect_x),
          0xa2 => Instruction.new(:ldx, :immediate),
          0xa4 => Instruction.new(:ldy, :zeropage),
          0xa5 => Instruction.new(:lda, :zeropage),
          0xa6 => Instruction.new(:ldx, :zeropage),
          0xa8 => Instruction.new(:tay, :implied),
          0xa9 => Instruction.new(:lda, :immediate),
          0xaa => Instruction.new(:tax, :implied),
          0xac => Instruction.new(:ldy, :absolute),
          0xad => Instruction.new(:lda, :absolute),
          0xae => Instruction.new(:ldx, :absolute),
          0xb0 => Instruction.new(:bcs, :relative),
          0xb1 => Instruction.new(:lda, :indirect_y),
          0xb4 => Instruction.new(:ldy, :zeropage_x),
          0xb5 => Instruction.new(:lda, :zeropage_x),
          0xb6 => Instruction.new(:ldx, :zeropage_y),
          0xb8 => Instruction.new(:clv, :implied),
          0xb9 => Instruction.new(:lda, :absolute_y),
          0xba => Instruction.new(:tsx, :implied),
          0xbc => Instruction.new(:ldy, :absolute_x),
          0xbd => Instruction.new(:lda, :absolute_x),
          0xbe => Instruction.new(:ldx, :absolute_y),
          0xc0 => Instruction.new(:cpy, :immediate),
          0xc1 => Instruction.new(:cmp, :indirect_x),
          0xc4 => Instruction.new(:cpy, :zeropage),
          0xc5 => Instruction.new(:cmp, :zeropage),
          0xc6 => Instruction.new(:dec, :zeropage),
          0xc8 => Instruction.new(:iny, :implied),
          0xc9 => Instruction.new(:cmp, :immediate),
          0xca => Instruction.new(:dex, :implied),
          0xcc => Instruction.new(:cpy, :absolute),
          0xcd => Instruction.new(:cmp, :absolute),
          0xce => Instruction.new(:dec, :absolute),
          0xd0 => Instruction.new(:bne, :relative),
          0xd1 => Instruction.new(:cmp, :indirect_y),
          0xd5 => Instruction.new(:cmp, :zeropage_x),
          0xd6 => Instruction.new(:dec, :zeropage_x),
          0xd8 => Instruction.new(:cld, :implied),
          0xd9 => Instruction.new(:cmp, :absolute_y),
          0xdd => Instruction.new(:cmp, :absolute_x),
          0xde => Instruction.new(:dec, :absolute_x),
          0xe0 => Instruction.new(:cpx, :immediate),
          0xe1 => Instruction.new(:sbc, :indirect_x),
          0xe4 => Instruction.new(:cpx, :zeropage),
          0xe5 => Instruction.new(:sbc, :zeropage),
          0xe6 => Instruction.new(:inc, :zeropage),
          0xe8 => Instruction.new(:inx, :implied),
          0xe9 => Instruction.new(:sbc, :immediate),
          0xea => Instruction.new(:nop, :implied),
          0xec => Instruction.new(:cpx, :absolute),
          0xed => Instruction.new(:sbc, :absolute),
          0xee => Instruction.new(:inc, :absolute),
          0xf0 => Instruction.new(:beq, :relative),
          0xf1 => Instruction.new(:sbc, :indirect_y),
          0xf5 => Instruction.new(:sbc, :zeropage_x),
          0xf6 => Instruction.new(:inc, :zeropage_x),
          0xf8 => Instruction.new(:sed, :implied),
          0xf9 => Instruction.new(:sbc, :absolute_y),
          0xfd => Instruction.new(:sbc, :absolute_x),
          0xfe => Instruction.new(:inc, :absolute_x)
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
