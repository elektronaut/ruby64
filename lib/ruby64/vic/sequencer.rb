# frozen_string_literal: true

require "ruby64/vic/graphics_mode"

module Ruby64
  class VIC < Cycleable
    # = VIC-II Sequencer
    #
    # Turns fetched graphics data into output pixels.
    class Sequencer
      DISPLAY_X_BOUNDS = [
        [135, 438].freeze,
        [128, 447].freeze
      ].freeze

      BORDER_Y_BOUNDS = [
        [55, 247].freeze,
        [51, 251].freeze
      ].freeze

      NULL_MODE = GraphicsMode::Null.new
      MODES = [
        GraphicsMode::Text.new,                   # 000 standard text
        GraphicsMode::MulticolorText.new,         # 001 multicolour text
        GraphicsMode::Bitmap.new,                 # 010 standard bitmap
        GraphicsMode::MulticolorBitmap.new,       # 011 multicolour bitmap
        GraphicsMode::ExtendedBackgroundText.new, # 100 ECM text
        NULL_MODE,                                # 101 invalid
        NULL_MODE,                                # 110 invalid
        NULL_MODE                                 # 111 invalid
      ].freeze

      attr_reader :colors, :fg, :border, :registers, :bank, :cur_colors, :cur_fg

      def initialize(width, registers, bank)
        @width = width
        @registers = registers
        @bank = bank
        @colors = Array.new(width, 0)
        @fg = Array.new(width, false)
        @border = Array.new(width, true)
        @cur_colors = Array.new(8, 0)
        @cur_fg = Array.new(8, false)
        @prev_colors = Array.new(8, 0)
        @prev_fg = Array.new(8, false)
        @win_colors = Array.new(8, 0)
        @win_fg = Array.new(8, false)
        @vertical_border = true
        @main_border = true
        new_line(0)
      end

      # Reset the line buffers at the start of a rasterline and re-evaluate the
      # vertical border flip-flop.
      def new_line(line)
        @line = line
        update_vertical_border(line)
        @colors.fill(@registers.border)
        @fg.fill(false)
        @border.fill(true)
        @prev_colors.fill(@registers.background)
        @prev_fg.fill(false)
      end

      # Repaint the border over the composited line, hiding the sprites.
      def apply_border
        color = @registers.border
        x = 0
        while x < @width
          @colors[x] = color if @border[x]
          x += 1
        end
      end

      def emit(screencode, color, col, cell = nil, row = nil)
        top = display_top
        row ||= (@line - top) % 8
        cell ||= (((@line - top) / 8) * 40) + col
        MODES[@registers.mode].decode(screencode, color, cell, row, self)
        shift_and_clip(col, (col + 16) * 8)
        roll
      end

      def emit_idle(col)
        @cur_colors.fill(@registers.background)
        @cur_fg.fill(false)
        shift_and_clip(col, (col + 16) * 8)
        roll
      end

      private

      def display_top = 48 + @registers.yscroll

      def shift_and_clip(col, x_pos)
        shift_window(col)
        clip(x_pos)
      end

      # Slice the XSCROLL-shifted pixels out of the rolling window.
      def shift_window(col)
        shift = @registers.xscroll
        bg = @registers.background
        bleed = col.positive? # the left column only exists from column 1 on

        i = 0
        while i < 8
          src = i - shift
          if src >= 0
            @win_colors[i] = @cur_colors[src]
            @win_fg[i] = @cur_fg[src]
          elsif bleed
            @win_colors[i] = @prev_colors[8 + src]
            @win_fg[i] = @prev_fg[8 + src]
          else
            @win_colors[i] = bg
            @win_fg[i] = false
          end
          i += 1
        end
      end

      def clip(x_pos)
        border = @registers.border
        graphics_line = line_in_graphics?(@line)
        win_lo, win_hi = DISPLAY_X_BOUNDS[@registers.csel? ? 1 : 0]
        right_compare = win_hi + 1
        gfx_lo, gfx_hi = DISPLAY_X_BOUNDS[1] # full 40 columns, ignoring CSEL

        i = 0
        while i < 8
          x = x_pos + i
          shown = pixel_shown?(x, win_lo, right_compare)
          @colors[x] = shown ? @win_colors[i] : border
          @border[x] = !shown
          @fg[x] = graphics_line && x >= gfx_lo && x <= gfx_hi ? @win_fg[i] : false
          i += 1
        end
      end

      def pixel_shown?(pixel_x, left_compare, right_compare)
        @main_border = true if pixel_x == right_compare
        @main_border = false if pixel_x == left_compare && !@vertical_border
        !(@main_border || @vertical_border)
      end

      def roll
        @prev_colors, @cur_colors = @cur_colors, @prev_colors
        @prev_fg, @cur_fg = @cur_fg, @prev_fg
      end

      def update_vertical_border(line)
        top, bottom = BORDER_Y_BOUNDS[@registers.rsel? ? 1 : 0]
        @vertical_border = true if line == bottom
        @vertical_border = false if line == top && @registers.display_enabled?
      end

      # The full 25-row graphics region, regardless of the RSEL clip.
      def line_in_graphics?(line)
        top = display_top
        line.between?(top, top + 199)
      end
    end
  end
end
