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
  class VIC
    include Addressable

    WIDTH = 504
    HEIGHT = 312

    attr_reader :address_bus

    def initialize(address_bus = nil, debug: false)
      addressable_at(0xd000, length: 2**10)
      @address_bus = address_bus || AddressBus.new
      @debug = debug
      @cycles = 0
      @position = 0

      @registers = Memory.new(length: 2**6)
    end

    def cycle!
      log
      @position = (@position + 8) % (WIDTH * HEIGHT)
      @cycles += 1
    end

    def rasterline
      @position / WIDTH
    end

    def peek(addr)
      # Access rasterline first at 1919830

      i = index(addr) % (2**6)
      case i
      when 0x12 then rasterline
      when 0x20..0x2e then @registers.peek(i) | 0xf0 # Color registers
      when 0x2f..0x3f then 0xff                      # Not in use
      else @registers.peek(i)
      end
    end

    def poke(addr, value)
      i = index(addr) % (2**5)
      @registers.poke(i, value)
    end

    private

    def log
      return unless @debug

      #puts "VIC raster line: #{rasterline}"
    end
  end
end
