# frozen_string_literal: true

module Ruby64
  class VIC < Cycleable
    class Sprite
      X_OFFSET = 104
      ROWS = 21

      attr_reader :index, :line_pixels

      def initialize(index, registers, bank, width)
        @index = index
        @registers = registers
        @bank = bank
        @width = width
        @bit = 1 << index
        @displaying = false
        @counter = 0
        @bits = nil
        @line_pixels = nil
        @pixel_buffer = Array.new(48)
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

      def leftmost = (x + X_OFFSET) % @width
      def pixel_width = x_expanded? ? 48 : 24

      def start_line(line)
        if !@displaying && enabled? && line == y
          @displaying = true
          @counter = 0
        end

        return @line_pixels = nil unless @displaying

        row = y_expanded? ? @counter / 2 : @counter
        if row >= ROWS
          @displaying = false
          return @line_pixels = nil
        end

        @counter += 1
        fetch(row)
        decode_line
      end

      def pixel(raster_x)
        return nil unless @line_pixels

        dist = raster_x - leftmost
        dist += @width if dist.negative?
        dist < pixel_width ? @line_pixels[dist] : nil
      end

      private

      # Decode the fetched 24 data bits into a buffer of pixel colors (nil is
      # transparent), so compositing can read pixels without re-deriving them.
      def decode_line(pixels = @pixel_buffer)
        @line_pixels = pixels
        if multicolor?
          decode_multicolor(pixels, x_expanded?)
        else
          decode_hires(pixels, x_expanded?)
        end
      end

      def decode_hires(pixels, expanded)
        own = color
        last = expanded ? 48 : 24
        i = 0
        while i < last
          offset = expanded ? i >> 1 : i
          pixels[i] = (@bits >> (23 - offset)).anybits?(1) ? own : nil
          i += 1
        end
      end

      def decode_multicolor(pixels, expanded)
        shared1 = @registers[0x25] & 0x0f
        shared2 = @registers[0x26] & 0x0f
        own = color
        last = expanded ? 48 : 24
        i = 0
        while i < last
          offset = expanded ? i >> 1 : i
          pixels[i] = case (@bits >> (22 - (offset & ~1))) & 0b11
                      when 0b01 then shared1
                      when 0b10 then own
                      when 0b11 then shared2
                      end
          i += 1
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
