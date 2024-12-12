# frozen_string_literal: true

require "ruby64/instruction_set/arithmetic"
require "ruby64/instruction_set/bitwise"
require "ruby64/instruction_set/branch"
require "ruby64/instruction_set/inc_dec"
require "ruby64/instruction_set/flag"
require "ruby64/instruction_set/illegal"
require "ruby64/instruction_set/stack"
require "ruby64/instruction_set/transfer"

module Ruby64
  # http://www.6502.org/tutorials/6502opcodes.html
  # http://www.e-tradition.net/bytes/6502/6502_instruction_set.html
  module InstructionSet
    include InstructionSet::Arithmetic
    include InstructionSet::Bitwise
    include InstructionSet::Branch
    include InstructionSet::IncDec
    include InstructionSet::Flag
    include InstructionSet::Illegal
    include InstructionSet::Stack
    include InstructionSet::Transfer

    # Forces a software interrupt (break).
    # Pushes PC+2 and status to stack, sets break flag, and jumps via IRQ vector.
    #
    # Opcodes:
    #   $00 - implied - 7 cycles
    def brk(_addr, _value)
      status.break = true
      handle_interrupt(0xfffe, brk: true, pre_cycles: 1)
      status.break = false
    end

    # No operation. Does nothing but consume a clock cycle.
    #
    # Opcodes:
    #   $EA                          - implied    - 2 cycles
    #   $04, $44, $64                - zeropage   - 3 cycles  (illegal)
    #   $14, $34, $54, $74, $D4, $F4 - zeropage_x - 4 cycles  (illegal)
    #   $0C                          - absolute   - 4 cycles  (illegal)
    #   $1C, $3C, $5C, $7C, $DC, $FC - absolute_x - 4+ cycles (illegal)
    #   $1A, $3A, $5A, $7A, $DA, $FA - implied    - 2 cycles  (illegal)
    def nop(_addr, _value)
      cycle
    end

    private

    def resolve(value)
      value.is_a?(Proc) ? value.call : value
    end

    def update_number_flags(value)
      status.zero = value.zero?
      status.negative = value.anybits?(0x80)
      value
    end
  end
end
