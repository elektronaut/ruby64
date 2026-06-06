# frozen_string_literal: true

module Ruby64
  module GUI
    class Palette
      COLORS = [
        "#000000", "#FFFFFF", "#924A40", "#84C5CC",
        "#9351B6", "#72B14B", "#483AAA", "#D5DF7C",
        "#675200", "#C33D00", "#C18178", "#606060",
        "#8A8A8A", "#B3EC91", "#867ADE", "#B3B3B3"
      ].freeze

      def initialize
        @entries = COLORS.map { |hex| pack(hex) }.freeze
      end

      def [](color)
        @entries[color]
      end

      private

      # Pack color as 4-byte little-endian RGBA string.
      def pack(hex)
        r = hex[1, 2].to_i(16)
        g = hex[3, 2].to_i(16)
        b = hex[5, 2].to_i(16)
        [(255 << 24) | (b << 16) | (g << 8) | r].pack("V")
      end
    end
  end
end
