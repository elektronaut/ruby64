# frozen_string_literal: true

module Ruby64
  class VIC < Cycleable
    module GraphicsMode
      module Hires
        def paint_hires(data, color, background, colors, mask)
          i = 0
          while i < 8
            set = data.anybits?(1 << (7 - i))
            colors[i] = set ? color : background
            mask[i] = set
            i += 1
          end
        end
      end

      class Text
        include Hires

        def decode(screencode, color, row, seq)
          registers = seq.registers
          data = seq.bank.peek(registers.char_base + (screencode * 8) + row)
          paint_hires(data, color, registers.background, seq.cur_colors, seq.cur_fg)
        end
      end

      class MulticolorText
        include Hires

        def decode(screencode, color, row, seq)
          registers = seq.registers
          data = seq.bank.peek(registers.char_base + (screencode * 8) + row)
          if color.anybits?(0x08)
            paint_multicolor(data, color, registers, seq.cur_colors, seq.cur_fg)
          else
            paint_hires(data, color & 0x07, registers.background, seq.cur_colors, seq.cur_fg)
          end
        end

        private

        def paint_multicolor(data, color, registers, colors, mask)
          i = 0
          while i < 8
            pair = (data >> (6 - (i & ~1))) & 0b11
            colors[i] = multicolor_pixel(pair, color, registers)
            mask[i] = pair.anybits?(0b10)
            i += 1
          end
        end

        def multicolor_pixel(pair, color, registers)
          case pair
          when 0b00 then registers.background(0)
          when 0b01 then registers.background(1)
          when 0b10 then registers.background(2)
          else color & 0x07
          end
        end
      end

      class Null
        def decode(_screencode, _color, _row, seq)
          colors = seq.cur_colors
          mask = seq.cur_fg
          i = 0
          while i < 8
            colors[i] = 0
            mask[i] = false
            i += 1
          end
        end
      end
    end
  end
end
