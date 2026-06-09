# frozen_string_literal: true

module Ruby64
  class VIC < Cycleable
    module GraphicsMode
      # Foreground masks depend only on the data byte, so each byte maps to a
      # precomputed frozen pattern shared by reference instead of being
      # written out pixel by pixel.
      HIRES_FG = Array.new(256) do |data|
        Array.new(8) { |i| data.anybits?(1 << (7 - i)) }.freeze
      end.freeze

      # The high bit of each 2-bit pair (10/11) is foreground.
      PAIR_FG = Array.new(256) do |data|
        Array.new(8) { |i| (data >> (6 - (i & ~1))).allbits?(0b10) }.freeze
      end.freeze

      NO_FG = HIRES_FG[0]

      module Hires
        def paint_hires(data, color, background, seq)
          seq.cur_fg = HIRES_FG[data]
          colors = seq.cur_colors
          return colors.fill(background) if data.zero?

          i = 0
          while i < 8
            colors[i] = data.anybits?(1 << (7 - i)) ? color : background
            i += 1
          end
        end
      end

      # Decodes 2-bit pixel pairs into double-wide pixels. The colour for each
      # pair is supplied by the block.
      module Multicolor
        def paint_pairs(data, seq)
          seq.cur_fg = PAIR_FG[data]
          colors = seq.cur_colors
          i = 0
          while i < 8
            colors[i] = yield((data >> (6 - (i & ~1))) & 0b11)
            i += 1
          end
        end
      end

      class Text
        include Hires

        def decode(screencode, color, _cell, row, seq)
          registers = seq.registers
          data = seq.bank.peek(registers.char_base + (screencode * 8) + row)
          paint_hires(data, color, registers.background, seq)
        end
      end

      class MulticolorText
        include Hires
        include Multicolor

        def decode(screencode, color, _cell, row, seq)
          registers = seq.registers
          data = seq.bank.peek(registers.char_base + (screencode * 8) + row)
          if color.anybits?(0x08)
            paint_pairs(data, seq) do |pair|
              multicolor_pixel(pair, color, registers)
            end
          else
            paint_hires(data, color & 0x07, registers.background, seq)
          end
        end

        private

        def multicolor_pixel(pair, color, registers)
          case pair
          when 0b00 then registers.background(0)
          when 0b01 then registers.background(1)
          when 0b10 then registers.background(2)
          else color & 0x07
          end
        end
      end

      class ExtendedBackgroundText
        include Hires

        def decode(screencode, color, _cell, row, seq)
          registers = seq.registers
          background = registers.background((screencode >> 6) & 0b11)
          data = seq.bank.peek(registers.char_base + ((screencode & 0x3f) * 8) + row)
          paint_hires(data, color, background, seq)
        end
      end

      class Bitmap
        include Hires

        def decode(screencode, _color, cell, row, seq)
          data = seq.bank.peek(seq.registers.bitmap_base + (cell * 8) + row)
          foreground = (screencode >> 4) & 0x0f
          background = screencode & 0x0f
          paint_hires(data, foreground, background, seq)
        end
      end

      class MulticolorBitmap
        include Multicolor

        def decode(screencode, color, cell, row, seq)
          registers = seq.registers
          data = seq.bank.peek(registers.bitmap_base + (cell * 8) + row)
          paint_pairs(data, seq) do |pair|
            multicolor_pixel(pair, screencode, color, registers)
          end
        end

        private

        def multicolor_pixel(pair, screencode, color, registers)
          case pair
          when 0b00 then registers.background(0)
          when 0b01 then (screencode >> 4) & 0x0f
          when 0b10 then screencode & 0x0f
          else color & 0x0f
          end
        end
      end

      class Null
        def decode(_screencode, _color, _cell, _row, seq)
          seq.cur_fg = NO_FG
          seq.cur_colors.fill(0)
        end
      end
    end
  end
end
