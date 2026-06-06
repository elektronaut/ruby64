# frozen_string_literal: true

require "ruby64/vic/graphics_mode"

module Ruby64
  class VIC < Cycleable
    # = VIC-II Sequencer
    #
    # Turns fetched graphics data into output pixels.
    class Sequencer
      # X position bounds of the visible display window, indexed by CSEL.
      DISPLAY_X_BOUNDS = [
        [135, 438].freeze,
        [128, 447].freeze
      ].freeze

      NULL_MODE = GraphicsMode::Null.new
      MODES = [
        GraphicsMode::Text.new,           # 000 standard text
        GraphicsMode::MulticolorText.new, # 001 multicolour text
        NULL_MODE,                        # 010 standard bitmap
        NULL_MODE,                        # 011 multicolour bitmap
        NULL_MODE,                        # 100 ECM text
        NULL_MODE,                        # 101 invalid
        NULL_MODE,                        # 110 invalid
        NULL_MODE                         # 111 invalid
      ].freeze

      attr_reader :colors, :fg, :registers, :bank, :cur_colors, :cur_fg

      def initialize(width, registers, bank)
        @width = width
        @registers = registers
        @bank = bank
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

      def emit(screencode, color, col, line, row)
        MODES[@registers.mode].decode(screencode, color, row, self)
        shift_and_clip(col, (col + 16) * 8, line)
        roll
      end

      private

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
