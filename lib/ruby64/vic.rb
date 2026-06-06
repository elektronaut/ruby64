# frozen_string_literal: true

module Ruby64
  # = VIC-II Registers
  #
  # == Sprite positions
  #
  #   $D000: Sprite 0 X
  #   $D001: Sprite 0 Y
  #   $D002: Sprite 1 X
  #   $D003: Sprite 1 Y
  #   $D004: Sprite 2 X
  #   $D005: Sprite 2 Y
  #   $D006: Sprite 3 X
  #   $D007: Sprite 3 Y
  #   $D008: Sprite 4 X
  #   $D009: Sprite 4 Y
  #   $D00A: Sprite 5 X
  #   $D00B: Sprite 5 Y
  #   $D00C: Sprite 6 X
  #   $D00D: Sprite 6 Y
  #   $D00E: Sprite 7 X
  #   $D00F: Sprite 7 Y
  #
  #   $D010: Most Significant Bits of Sprites 0-7 Horizontal Position
  #   $D011: Vertical Fine Scrolling and Control Register
  #   $D012: Rasterline
  #          - Read: Current rasterline
  #          - Write: Set rasterline interrupt
  #
  # == Light pen
  #
  #   $D013: Light Pen Horizontal Position
  #   $D014: Light Pen Vertical Position
  #
  #   $D015: Sprite Enable Register
  #   $D016: Horizontal Fine Scrolling and Control Register
  #   $D017: Sprite Vertical Expansion Register
  #   $D018: VIC-II Chip Memory Control Register
  #   $D019: VIC Interrupt Flag Register
  #   $D01A: IRQ Mask Register
  #   $D01B: Sprite to Foreground Display Priority Register
  #   $D01C: Sprite Multicolor Registers
  #   $D01D: Sprite Horizontal Expansion Register
  #
  # == Sprite collision detection
  #
  #   $D01E: Sprite to Sprite Collision Register
  #   $D01F: Sprite to Foreground Collision Register
  #
  # == Color registers
  #
  # All color registers are 4bit, bits 4-7 always read 1.
  #
  #   $D020: Border color        - Default: 14, light blue
  #   $D021: Background color 0  - Default: 6,  blue
  #   $D022: Background color 1  - Default: 1,  white
  #   $D023: Background color 2  - Default: 2,  red
  #   $D024: Background color 3  - Default: 3,  cyan
  #   $D025: Sprite multicolor 0 - Default: 4,  purple
  #   $D026: Sprite multicolor 1 - Default: 0,  black
  #   $D027: Sprite 0 color      - Default: 1,  white
  #   $D028: Sprite 1 color      - Default: 2,  red
  #   $D029: Sprite 2 color      - Default: 3,  cyan
  #   $D02A: Sprite 3 color      - Default: 4,  purple
  #   $D02B: Sprite 4 color      - Default: 5,  green
  #   $D02C: Sprite 5 color      - Default: 6,  blue
  #   $D02D: Sprite 6 color      - Default: 7,  yellow
  #   $D02E: Sprite 7 color      - Default: 12, medium gray
  #
  # $D02F-$D03F: Not in use, always reads 0xff
  # $D040-$D3FF: Repeat $D0000 to $D03F every 64 bytes
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
      @vic_bank = VICBank.new(@address_bus)
      @debug = debug

      @width = 504
      @height = 312

      @registers = Array.new(2**6, 0)
      @display = Array.new(@width * @height, 0)

      @position = 0
      @interrupted = false

      @character_buffer = Array.new(40, 0)
      @color_buffer = Array.new(40, 0)

      # Initialize default colors
      write_registers(0x20, [14, 6, 1, 2, 3, 4, 0, 1, 2, 3, 4, 5, 6, 7, 12])

      # Initialize VIC control registers with C64 defaults
      write_registers(0x11, [0x1b, 0]) # $D011: DEN=1, RSEL=1, YSCROLL=3
      write_registers(0x16, [0xc8]) # $D016: Text mode, XSCROLL=0
      write_registers(0x19, [0, 0]) # IRQ flags
      super()
    end

    def cycle!
      @interrupted = false
      check_raster_irq! if beginning_of_line?

      fetch_character_data! if dma_active?

      draw!

      @position = (@position + 8) % (width * height)
      nil
    end

    def interrupt!
      @interrupted = true
    end

    def interrupted?
      @interrupted
    end

    def peek(addr)
      i = index(addr) % (2**6)
      case i
      when 0x11 then (@registers[i] & 0x7f) | ((rasterline & 0x100) >> 1)
      when 0x12 then rasterline & 0xff
      when 0x20..0x2e then @registers[i] | 0xf0 # Color registers
      when 0x2f..0x3f then 0xff                 # Not in use
      else @registers[i]
      end
    end

    def poke(addr, value)
      i = index(addr) % (2**6)
      case i
      when 0x19 # IRQ flags - write 1 to clear
        @registers[i] &= ~value
      when 0x1a # IRQ mask
        @registers[i] = value & 0x0f
      else
        @registers[i] = value
      end
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

    def write_registers(addr, bytes)
      bytes.each_with_index { |b, i| @registers[addr + i] = b }
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
      char_offset = (@registers[0x18] & 0b1110) * 0x400
      vic_bank.peek(char_offset + (screencode * 8) + line)
    end

    def draw!
      return if blanking?

      pos = @position
      line = pos / @width
      x_pos = pos % @width
      top = display_top
      col = (x_pos / 8) - 16

      char = read_char(@character_buffer[col] || 0, (line - top) % 8)
      render_row(pos, x_pos, char, col, line_in_display?(line, top))
    end

    def render_row(pos, x_pos, char, col, visible)
      border = @registers[0x20]
      bg = @registers[0x21]
      fg = @color_buffer[col] || 1
      x_lo, x_hi = DISPLAY_X_BOUNDS[csel? ? 1 : 0]

      i = 0
      while i < 8
        px = x_pos + i
        @display[pos + i] =
          if visible && px >= x_lo && px <= x_hi
            char.anybits?(1 << (7 - i)) ? fg : bg
          else
            border
          end
        i += 1
      end
    end

    def line_in_display?(line, top)
      if rsel?
        line.between?(top, top + 199)
      else
        line.between?(top + 4, top + 195)
      end
    end

    def video_matrix(index)
      vic_bank.peek(((@registers[0x0018] >> 4) * 0x400) + index)
    end

    def check_raster_irq!
      return unless rasterline == irq_raster_target

      # Set raster IRQ flag
      @registers[0x19] |= 0x01

      # Trigger interrupt if enabled
      interrupt! if @registers[0x1a].anybits?(0x01)
    end

    def irq_raster_target
      uint16(@registers[0x12],
             (@registers[0x11] & 0x80) >> 7)
    end

    def bad_line?
      return false unless display_enabled?
      return false unless text_mode?

      r = rasterline
      return false unless r.between?(48, 247)

      (r & 0b111) == yscroll
    end

    def display_enabled?
      @registers[0x11].anybits?(0x10)
    end

    def text_mode?
      @registers[0x11].nobits?(0x20) && @registers[0x16].nobits?(0x10)
    end

    def fetch_character_data!
      @character_buffer[char_column + 1] = video_matrix(char_index + 1)
      @color_buffer[char_column + 1] = vic_bank.peek_color(char_index + 1)
    end

    def xscroll
      @registers[0x16] & 0b0111
    end

    def yscroll
      @registers[0x11] & 0b0111
    end

    def rsel?
      @registers[0x11].anybits?(0x08)
    end

    def csel?
      @registers[0x16].anybits?(0x08)
    end

    def display_top
      48 + yscroll
    end
  end
end
