# frozen_string_literal: true

module Ruby64
  class VIC < Cycleable
    # = VIC-II Sequencer
    #
    # Turns fetched graphics data into output pixels.
    class Sequencer
      include IntegerHelper

      # X position bounds of the visible display window, indexed by CSEL.
      DISPLAY_X_BOUNDS = [
        [135, 438].freeze,
        [128, 447].freeze
      ].freeze

      attr_reader :colors, :fg

      def initialize(width, registers)
        @width = width
        @registers = registers
        @colors = Array.new(width, 0)
        @fg = Array.new(width, false)
        @cur_colors = Array.new(8, 0)
        @cur_fg = Array.new(8, false)
        @prev_colors = Array.new(8, 0)
        @prev_fg = Array.new(8, false)
        new_line
      end

      # Reset the rolling cell window at the start of a rasterline so the first
      # display column bleeds background, never the previous line's content.
      def new_line
        @prev_colors.fill(@registers.background)
        @prev_fg.fill(false)
      end

      def emit(char, foreground, col, x_pos, line)
        decode_text(char, foreground)
        shift_and_clip(col, x_pos, line)
        roll
      end

      private

      # Standard text: each set bit is a foreground pixel.
      def decode_text(char, foreground)
        bg = @registers.background
        i = 0
        while i < 8
          set = char.anybits?(1 << (7 - i))
          @cur_colors[i] = set ? foreground : bg
          @cur_fg[i] = set
          i += 1
        end
      end

      def shift_and_clip(col, x_pos, line)
        shift = @registers.xscroll
        border = @registers.border
        bg = @registers.background
        visible = line_in_display?(line)
        bleed = col.positive? # the left column only exists from column 1 on

        i = 0
        while i < 8
          x = x_pos + i
          if !visible || !in_window?(x)
            @colors[x] = border
            @fg[x] = false
          elsif (src = i - shift) >= 0
            @colors[x] = @cur_colors[src]
            @fg[x] = @cur_fg[src]
          elsif bleed
            @colors[x] = @prev_colors[8 + src]
            @fg[x] = @prev_fg[8 + src]
          else
            @colors[x] = bg
            @fg[x] = false
          end
          i += 1
        end
      end

      def roll
        @prev_colors, @cur_colors = @cur_colors, @prev_colors
        @prev_fg, @cur_fg = @cur_fg, @prev_fg
      end

      def in_window?(pixel_x)
        x_lo, x_hi = DISPLAY_X_BOUNDS[@registers.csel? ? 1 : 0]
        pixel_x.between?(x_lo, x_hi)
      end

      def line_in_display?(line)
        top = 48 + @registers.yscroll
        if @registers.rsel?
          line.between?(top, top + 199)
        else
          line.between?(top + 4, top + 195)
        end
      end
    end
  end
end
