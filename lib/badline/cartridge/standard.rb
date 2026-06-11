# frozen_string_literal: true

module Badline
  class Cartridge
    class Standard < Cartridge
      private

      def install_chips(chips)
        chips.each { |chip| install_chip(chip) }
      end

      def install_chip(chip)
        if chip.address >= ULTIMAX_ROMH_START
          @romh = rom_bank(chip.data, ULTIMAX_ROMH_START)
        elsif chip.address >= ROMH_START
          @romh = rom_bank(chip.data, ROMH_START)
        elsif chip.data.length > BANK_SIZE
          install_split_chip(chip)
        else
          @roml = rom_bank(chip.data, ROML_START)
        end
      end

      def install_split_chip(chip)
        # A single 16K chip at $8000 spans both ROML and ROMH.
        @roml = rom_bank(chip.data[0, BANK_SIZE], ROML_START)
        @romh = rom_bank(chip.data[BANK_SIZE, BANK_SIZE], ROMH_START)
      end
    end
  end
end
