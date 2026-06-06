# frozen_string_literal: true

require "ruby64/vic/bank"
require "ruby64/vic/registers"

module Ruby64
  class VIC < Cycleable
    include Addressable
    include IntegerHelper

    attr_reader :address_bus, :display, :position, :width, :height, :vic_bank

    # X position bounds of the visible display window, indexed by CSEL.
    DISPLAY_X_BOUNDS = [
      [135, 438].freeze,
      [128, 447].freeze
    ].freeze

    def initialize(address_bus = nil, debug: false)
      addressable_at(0xd000, length: 2**10)
      @address_bus = address_bus || AddressBus.new
      @vic_bank = VIC::Bank.new(@address_bus)
      @debug = debug

      @width = 504
      @height = 312

      @registers = VIC::Registers.new
      @display = Array.new(@width * @height, 0)

      @position = 0

      @character_buffer = Array.new(40, 0)
      @color_buffer = Array.new(40, 0)

      super()
    end

    def cycle!
      check_raster_irq! if beginning_of_line?

      fetch_character_data! if dma_active?

      draw!

      @position = (@position + 8) % (width * height)
      nil
    end

    # The IRQ line is held asserted while any enabled latch bit is set in
    # $D019/$D01A, until the program acknowledges it by writing to $D019.
    def interrupted?
      (@registers[0x19] & @registers[0x1a]).anybits?(0x0f)
    end

    def peek(addr)
      i = index(addr) % (2**6)
      case i
      when 0x11 then (@registers[0x11] & 0x7f) | ((rasterline & 0x100) >> 1)
      when 0x12 then rasterline & 0xff
      when 0x19 then irq_status # Latch + master IRQ bit, unused bits read 1
      else @registers.read(i)
      end
    end

    def poke(addr, value)
      @registers.write(index(addr) % (2**6), value)
    end

    def column
      (position % width) / 8
    end

    def rasterline
      position / width
    end

    def dma_active?
      return false unless bad_line?

      c = column
      c >= 15 && c < 55
    end

    def hblank?
      c = column
      c < 10 || c > 60
    end

    def vblank?
      r = rasterline
      r < 16 || r > 299
    end

    def blanking?
      vblank? || hblank?
    end

    private

    def beginning_of_line?
      (position % width).zero?
    end

    def char_row
      (rasterline - display_top) / 8
    end

    def char_column
      column - 16
    end

    def char_index
      (char_row * 40) + char_column
    end

    def read_char(screencode, line)
      vic_bank.peek(@registers.char_base + (screencode * 8) + line)
    end

    def draw!
      return if blanking?

      pos = @position
      line = pos / @width
      top = display_top
      col = ((pos % @width) / 8) - 16
      char_line = (line - top) % 8

      char = read_char(@character_buffer[col] || 0, char_line)
      render_row(pos, char, prev_char(col, char_line), col, line_in_display?(line, top))
    end

    def prev_char(col, char_line)
      return 0 unless @registers.xscroll.positive? && col.positive?

      read_char(@character_buffer[col - 1] || 0, char_line)
    end

    def render_row(pos, char, prev_char, col, visible)
      border = @registers.border
      bg = @registers.background
      fg = @color_buffer[col] || 1
      prev_fg = left_fg(col, bg)
      window = (prev_char << 8) | char
      x_pos = pos % @width
      shift = @registers.xscroll

      i = 0
      while i < 8
        j = (8 + i) - shift
        @display[pos + i] =
          if !visible || !in_window?(x_pos + i)
            border
          elsif window.anybits?(1 << (15 - j))
            j < 8 ? prev_fg : fg
          else
            bg
          end
        i += 1
      end
    end

    def in_window?(pixel_x)
      x_lo, x_hi = DISPLAY_X_BOUNDS[@registers.csel? ? 1 : 0]
      pixel_x.between?(x_lo, x_hi)
    end

    # Foreground colour of the column to the left, which bleeds into the shifted-in pixels.
    # Falls back to background at the left display edge.
    def left_fg(col, background)
      col.positive? ? (@color_buffer[col - 1] || 1) : background
    end

    def line_in_display?(line, top)
      if @registers.rsel?
        line.between?(top, top + 199)
      else
        line.between?(top + 4, top + 195)
      end
    end

    def video_matrix(index)
      vic_bank.peek(@registers.screen_base + index)
    end

    def check_raster_irq!
      return unless rasterline == @registers.raster_target

      # Latch the raster IRQ flag; the line asserts via #interrupted? when the
      # matching mask bit in $D01A is set.
      @registers.latch_raster_irq!
    end

    def irq_status
      (@registers[0x19] & 0x0f) | 0x70 | (interrupted? ? 0x80 : 0)
    end

    def bad_line?
      return false unless @registers.display_enabled?
      return false unless @registers.text_mode?

      r = rasterline
      return false unless r.between?(48, 247)

      (r & 0b111) == @registers.yscroll
    end

    def fetch_character_data!
      @character_buffer[char_column + 1] = video_matrix(char_index + 1)
      @color_buffer[char_column + 1] = vic_bank.peek_color(char_index + 1)
    end

    def display_top
      48 + @registers.yscroll
    end
  end
end
