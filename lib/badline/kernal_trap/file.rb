# frozen_string_literal: true

module Badline
  module KernalTrap
    class File
      include IntegerHelper

      DEVICE = 8

      MISSING_FILENAME = 0x08

      def initialize(cpu:, bus:, storage:)
        @cpu = cpu
        @bus = bus
        @storage = storage
      end

      private

      def active?
        @bus.io_port.kernal? && @bus.peek(0xba) == DEVICE
      end

      # Filename pointer at $BB/$BC, length at $B7
      def filename
        pointer = uint16(@bus.peek(0xbb), @bus.peek(0xbc))
        bytes = Array.new(@bus.peek(0xb7)) do |i|
          @bus.peek((pointer + i) & 0xffff)
        end
        strip_drive_prefix(Storage.ascii(bytes))
      end

      # CBM DOS drive prefix — "0:NAME" selects a drive, "@0:NAME" is
      # save-with-replace
      def strip_drive_prefix(name)
        name.sub(/\A@?\d*:/, "")
      end

      def error(code)
        @cpu.a = code
        @cpu.status.carry = true
      end

      def return_to_caller
        @cpu.program_counter = (uint16(pull_byte, pull_byte) + 1) & 0xffff
      end

      def pull_byte
        @cpu.stack_pointer = (@cpu.stack_pointer + 1) & 0xff
        @bus.peek(0x0100 + @cpu.stack_pointer)
      end
    end
  end
end
