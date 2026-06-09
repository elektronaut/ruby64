# frozen_string_literal: true

module Ruby64
  class VIC < Cycleable
    # The 16K window the VIC sees into RAM, selected by CIA2 $DD00. Character
    # ROM shadows $1000-$1FFF in banks 0 and 2.
    class Bank
      include Addressable

      # The CIA2 port A bank bits are inverted: %11 selects bank 0.
      BANK_STARTS = [0xc000, 0x8000, 0x4000, 0x0000].freeze

      attr_reader :address_bus

      def initialize(address_bus = nil)
        addressable_at(0x0000, length: 2**14)
        @address_bus = address_bus || AddressBus.new
      end

      def peek(offset)
        bits = bank_switch_register
        if bits.allbits?(0b01) && (offset & 0xf000) == 0x1000
          @address_bus.character_rom.peek(0xc000 + offset)
        else
          @address_bus.ram.peek(BANK_STARTS[bits] + offset)
        end
      end

      def peek_color(offset)
        address_bus.color_ram.peek(0xd800 + offset) & 0x0f
      end

      def poke(_addr, _value)
        raise ReadOnlyMemoryError
      end

      def start
        BANK_STARTS[bank_switch_register]
      end

      private

      def bank_switch_register
        @address_bus.cia2.port_a_lines & 0b11
      end

      def character_rom?
        bank_switch_register.allbits?(0b01)
      end
    end
  end
end
