# frozen_string_literal: true

require "badline/vic/graphics_mode"

module Badline
  class VIC < Cycleable
    # = VIC-II Sequencer
    #
    # Turns fetched graphics data into output pixels.
    class Sequencer
      DISPLAY_X_BOUNDS = [
        [135, 438].freeze,
        [128, 447].freeze
      ].freeze

      # The graphics window always spans the full 40 columns, ignoring CSEL.
      GFX_X_START = DISPLAY_X_BOUNDS[1][0]
      GFX_X_END = DISPLAY_X_BOUNDS[1][1] + 1

      # [left compare, right compare] for the border flip-flop per CSEL state.
      WINDOW_COMPARES = [
        [DISPLAY_X_BOUNDS[0][0], DISPLAY_X_BOUNDS[0][1] + 1].freeze,
        [GFX_X_START, GFX_X_END].freeze
      ].freeze

      BORDER_Y_BOUNDS = [
        [55, 247].freeze,
        [51, 251].freeze
      ].freeze

      # Border coverage per 8-pixel group, tracked so apply_border can skip
      # window groups and bulk-fill full border groups.
      BORDER_FULL  = 0
      BORDER_NONE  = 1
      BORDER_MIXED = 2

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

      attr_reader :colors, :fg, :border, :registers, :bank, :cur_colors
      # The fg masks are shared frozen patterns assigned by reference, never
      # mutated in place.
      attr_accessor :cur_fg

      def initialize(width, registers, bank)
        @width = width
        @registers = registers
        @bank = bank
        @colors = Array.new(width, 0)
        @fg = Array.new(width, false)
        @border = Array.new(width, true)
        @border_groups = Array.new(width / 8, BORDER_FULL)
        @cur_colors = Array.new(8, 0)
        @cur_fg = GraphicsMode::NO_FG
        @prev_colors = Array.new(8, 0)
        @prev_fg = GraphicsMode::NO_FG
        @vertical_border = true
        @main_border = true
        new_line(0)
      end

      # Reset the line buffers at the start of a rasterline and re-evaluate the
      # vertical border flip-flop.
      def new_line(line)
        update_vertical_border(line)
        @colors.fill(@registers.border)
        @fg.fill(false)
        @border_groups.fill(BORDER_FULL)
        @prev_colors.fill(@registers.background)
        @prev_fg = GraphicsMode::NO_FG
      end

      # Repaint the border over the composited line, hiding the sprites.
      def apply_border
        color = @registers.border
        group = 0
        while group < @border_groups.length
          case @border_groups[group]
          when BORDER_FULL then @colors.fill(color, group * 8, 8)
          when BORDER_MIXED then paint_mixed_border(color, group * 8)
          end
          group += 1
        end
      end

      def emit(screencode, color, col, cell, row)
        MODES[@registers.mode].decode(screencode, color, cell, row, self)
        output(col)
        roll
      end

      def emit_idle(col)
        @cur_colors.fill(@registers.background)
        @cur_fg = GraphicsMode::NO_FG
        output(col)
        roll
      end

      private

      # Write the 8-pixel group for a column into the line buffers. The main
      # border flip-flop only changes state in the groups containing the
      # window edge compares, so all other groups take a branch-free bulk
      # path: fully border or fully window.
      def output(col)
        x_pos = (col + 16) * 8
        win_lo, right_compare = WINDOW_COMPARES[@registers.csel? ? 1 : 0]

        if boundary_group?(x_pos, win_lo, right_compare)
          output_boundary(col, x_pos, win_lo, right_compare)
        elsif @main_border || @vertical_border
          output_border(x_pos)
        else
          output_window(col, x_pos)
        end
      end

      # True if the group contains a window edge, where the main border
      # flip-flop can change state.
      def boundary_group?(x_pos, win_lo, right_compare)
        lo_delta = win_lo - x_pos
        hi_delta = right_compare - x_pos
        (lo_delta >= 0 && lo_delta < 8) || (hi_delta >= 0 && hi_delta < 8)
      end

      def output_border(x_pos)
        @colors.fill(@registers.border, x_pos, 8)
        @border_groups[x_pos >> 3] = BORDER_FULL
        @fg.fill(false, x_pos, 8)
      end

      def output_window(col, x_pos)
        in_gfx = x_pos >= GFX_X_START && x_pos < GFX_X_END
        @border_groups[x_pos >> 3] = BORDER_NONE

        if @registers.xscroll.zero?
          @colors[x_pos, 8] = @cur_colors
          if in_gfx
            @fg[x_pos, 8] = @cur_fg
          else
            @fg.fill(false, x_pos, 8)
          end
        else
          output_window_shifted(col, x_pos, in_gfx)
        end
      end

      def output_window_shifted(col, x_pos, in_gfx)
        shift = @registers.xscroll
        keep = 8 - shift

        @colors[x_pos + shift, keep] = @cur_colors[0, keep]
        if col.positive? # the left column only exists from column 1 on
          @colors[x_pos, shift] = @prev_colors[keep, shift]
        else
          @colors.fill(@registers.background, x_pos, shift)
        end
        output_shifted_fg(col, x_pos, in_gfx, shift, keep)
      end

      def output_shifted_fg(col, x_pos, in_gfx, shift, keep)
        return @fg.fill(false, x_pos, 8) unless in_gfx

        @fg[x_pos + shift, keep] = @cur_fg[0, keep]
        if col.positive?
          @fg[x_pos, shift] = @prev_fg[keep, shift]
        else
          @fg.fill(false, x_pos, shift)
        end
      end

      # Slow path for the groups where the border flip-flop can change state.
      def output_boundary(col, x_pos, win_lo, right_compare)
        shift = @registers.xscroll
        bg = @registers.background
        bleed = col.positive?
        border = @registers.border
        @border_groups[x_pos >> 3] = BORDER_MIXED

        i = 0
        while i < 8
          src = i - shift
          if src >= 0
            pixel = @cur_colors[src]
            mask = @cur_fg[src]
          elsif bleed
            pixel = @prev_colors[8 + src]
            mask = @prev_fg[8 + src]
          else
            pixel = bg
            mask = false
          end
          x = x_pos + i
          shown = pixel_shown?(x, win_lo, right_compare)
          @colors[x] = shown ? pixel : border
          @border[x] = !shown
          @fg[x] = x >= GFX_X_START && x < GFX_X_END ? mask : false
          i += 1
        end
      end

      def paint_mixed_border(color, x_pos)
        i = 0
        while i < 8
          @colors[x_pos + i] = color if @border[x_pos + i]
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
    end
  end
end
