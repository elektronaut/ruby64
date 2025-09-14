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

    def initialize(address_bus = nil, debug: false)
      addressable_at(0xd000, length: 2**10)
      @address_bus = address_bus || AddressBus.new
      @vic_bank = VICBank.new(@address_bus)
      @debug = debug

      @width = 504
      @height = 312

      @registers = Memory.new(length: 2**6)
      @display = Array.new(@width * @height, 0)

      @position = 0
      @interrupted = false

      @character_buffer = Array.new(40, 0)
      @color_buffer = Array.new(40, 0)

      # Initialize default colors
      @registers.write(0x20, [14, 6, 1, 2, 3, 4, 0, 1, 2, 3, 4, 5, 6, 7, 12])

      # Initialize VIC control registers with C64 defaults
      @registers.write(0x11, [0x1b, 0]) # $D011: DEN=1, RSEL=1, YSCROLL=3
      @registers.write(0x16, [0xc8]) # $D016: Text mode, XSCROLL=0
      @registers.write(0x19, [0, 0]) # IRQ flags
      super()
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
      when 0x11 then (@registers.peek(i) & 0x7f) | ((rasterline & 0x100) >> 1)
      when 0x12 then rasterline & 0xff
      when 0x20..0x2e then @registers.peek(i) | 0xf0 # Color registers
      when 0x2f..0x3f then 0xff                      # Not in use
      else @registers.peek(i)
      end
    end

    def poke(addr, value)
      i = index(addr) % (2**6)
      case i
      when 0x19 # IRQ flags - write 1 to clear
        @registers.poke(i, @registers.peek(i) & ~value)
      when 0x1a # IRQ mask
        @registers.poke(i, value & 0x0f)
      else
        @registers.poke(i, value)
      end
    end

    def column
      (position % width) / 8
    end

    def rasterline
      position / width
    end

    def dma_active?
      bad_line? && (15...55).include?(column) && (56...256).include?(rasterline)
    end

    def hblank?
      !(10..60).include?(column)
    end

    def vblank?
      !(16..299).include?(rasterline)
    end

    private

    def main_loop
      @interrupted = false
      check_raster_irq! if beginning_of_line?

      cycle { fetch_character_data! } if dma_active?

      draw!

      @position = (@position + 8) % (width * height)
      Fiber.yield
    end

    def beginning_of_line?
      (position % width).zero?
    end

    def background_color
      @registers.peek(0x21)
    end

    def foreground_color
      @color_buffer[char_column] || 1
    end

    def char_row
      # TODO: scroll
      (rasterline - 56) / 8
    end

    def char_column
      column - 16
    end

    def char_index
      (char_row * 40) + char_column
    end

    def display_area?
      (16...56).include?(column) && (56...256).include?(rasterline)
    end

    def read_char(screencode, line)
      char_offset = (@registers.peek(0x18) & 0b1110) * 0x400
      vic_bank.peek(char_offset + (screencode * 8) + line)
    end

    def draw!
      return if vblank? || hblank?

      pixels = if display_area?
                 screencode = @character_buffer[char_column] || 0
                 char = read_char(screencode, (rasterline - 56) % 8)
                 8.times.map do |i|
                   char[7 - i] == 1 ? foreground_color : background_color
                 end
               else
                 # Draw border
                 [@registers.peek(0x20)] * 8
               end

      pixels.each_with_index { |p, i| display[position + i] = p }
    end

    def video_matrix(index)
      vic_bank.peek(((@registers.peek(0x0018) >> 4) * 0x400) + index)
    end

    def check_raster_irq!
      return unless rasterline == irq_raster_target

      # Set raster IRQ flag
      @registers.poke(0x19, @registers.peek(0x19) | 0x01)

      # Trigger interrupt if enabled
      interrupt! if @registers.peek(0x1a).anybits?(0x01)
    end

    def irq_raster_target
      uint16(@registers.peek(0x12),
             (@registers.peek(0x11) & 0x80) >> 7)
    end

    def bad_line?
      return false unless display_enabled?
      return false unless text_mode?
      return false if rasterline < 48 || rasterline > 247

      if @registers.peek(0x11).anybits?(0x08)
        (rasterline - 48) % 8 == yscroll
      else
        (rasterline - 48) % 8 == yscroll && rasterline >= 55
      end
    end

    def display_enabled?
      @registers.peek(0x11).anybits?(0x10)
    end

    def text_mode?
      @registers.peek(0x11).nobits?(0x20) && @registers.peek(0x16).nobits?(0x10)
    end

    def fetch_character_data!
      @character_buffer[char_column + 1] = video_matrix(char_index + 1)
      @color_buffer[char_column + 1] = vic_bank.peek_color(char_index + 1)
    end

    def xscroll
      @registers.peek(0x16) & 0b0111
    end

    def yscroll
      0

      # TODO: scroll
      # @registers.peek(0x11) & 0b0111
    end
  end
end
