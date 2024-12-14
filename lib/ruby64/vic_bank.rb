# frozen_string_literal: true

module Ruby64
  class VICBank
    include Addressable

    attr_reader :address_bus

    def initialize(address_bus = nil)
      addressable_at(0x0000, length: 2**14)
      @address_bus = address_bus || AddressBus.new
    end

    def peek(offset)
      case offset
      when 0x1000..0x1fff
        if character_rom?
          address_bus.character_rom.peek(0xc000 + offset)
        else
          address_bus.ram.peek(start + offset)
        end
      else
        address_bus.ram.peek(start + offset)
      end
    end

    def peek_color(offset)
      address_bus.color_ram.peek(0xd800 + offset) & 0x0f
    end

    def poke(_addr, _value)
      raise ReadOnlyMemoryError
    end

    def start
      case bank_switch_register
      when 0b00 then 0xc000
      when 0b01 then 0x8000
      when 0b10 then 0x4000
      when 0b11 then 0x0000
      end
    end

    private

    def bank_switch_register
      address_bus.cia2.peek(0xdd00) & 0b11
    end

    def character_rom?
      bank_switch_register.allbits?(0b01)
    end
  end
end
