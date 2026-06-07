# frozen_string_literal: true

module Ruby64
  class VIC < Cycleable
    class Sprite
      X_OFFSET = 104
      ROWS = 21

      attr_reader :index

      def initialize(index, registers, bank)
        @index = index
        @registers = registers
        @bank = bank
        @bit = 1 << index
        @displaying = false
        @counter = 0
        @bits = nil
      end

      def displaying? = @displaying

      def enabled? = @registers[0x15].anybits?(@bit)
      def multicolor? = @registers[0x1c].anybits?(@bit)
      def x_expanded? = @registers[0x1d].anybits?(@bit)
      def y_expanded? = @registers[0x17].anybits?(@bit)
      def priority? = @registers[0x1b].anybits?(@bit)

      def x
        msb = @registers[0x10].anybits?(@bit) ? 0x100 : 0
        msb | @registers[index * 2]
      end

      def y = @registers[(index * 2) + 1]
      def color = @registers[0x27 + index] & 0x0f

      def start_line(line)
        if !@displaying && enabled? && line == y
          @displaying = true
          @counter = 0
        end

        return @bits = nil unless @displaying

        row = y_expanded? ? @counter / 2 : @counter
        if row >= ROWS
          @displaying = false
          return @bits = nil
        end

        @counter += 1
        fetch(row)
      end

      def pixel(raster_x)
        return nil unless @bits

        left = x + X_OFFSET
        return nil if raster_x < left

        offset = (raster_x - left) / (x_expanded? ? 2 : 1)
        return nil if offset >= 24

        multicolor? ? multicolor_pixel(offset) : hires_pixel(offset)
      end

      private

      def hires_pixel(offset)
        (@bits >> (23 - offset)).nobits?(1) ? nil : color
      end

      def multicolor_pixel(offset)
        case (@bits >> (22 - (offset & ~1))) & 0b11
        when 0b00 then nil
        when 0b01 then @registers[0x25] & 0x0f
        when 0b10 then color
        else @registers[0x26] & 0x0f
        end
      end

      def fetch(row)
        base = (pointer * 64) + (row * 3)
        @bits = (@bank.peek(base) << 16) |
                (@bank.peek(base + 1) << 8) |
                @bank.peek(base + 2)
      end

      def pointer = @bank.peek(@registers.screen_base + 0x3f8 + index)
    end
  end
end
