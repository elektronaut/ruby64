# frozen_string_literal: true

module Badline
  class Cartridge
    class Ocean < Cartridge
      def poke(addr, value)
        return if addr > 0xdeff

        select_bank((value & 0x3f) % @roml_banks.length)
        changed!
      end

      private

      def select_bank(number)
        @roml = @roml_banks[number]
        @romh = @romh_banks[number] if @romh_banks
      end

      def install_chips(chips)
        @roml_banks = []
        @romh_banks = game.zero? ? [] : nil
        chips.each { |chip| install_chip(chip) }
        select_bank(0)
      end

      def install_chip(chip)
        @roml_banks[chip.bank] = rom_bank(chip.data, ROML_START)
        @romh_banks[chip.bank] = rom_bank(chip.data, ROMH_START) if @romh_banks
      end
    end
  end
end
