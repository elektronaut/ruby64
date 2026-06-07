# frozen_string_literal: true

require "ruby64/vic/bank"
require "ruby64/vic/registers"
require "ruby64/vic/display_state"
require "ruby64/vic/sequencer"
require "ruby64/vic/sprites"

module Ruby64
  class VIC < Cycleable
    include Addressable
    include IntegerHelper

    attr_reader :address_bus, :display, :position, :width, :height, :vic_bank

    def initialize(address_bus = nil, debug: false)
      addressable_at(0xd000, length: 2**10)
      @address_bus = address_bus || AddressBus.new
      @vic_bank = VIC::Bank.new(@address_bus)
      @debug = debug

      @width = 504
      @height = 312

      @registers = VIC::Registers.new
      @display_state = VIC::DisplayState.new(@registers)
      @sequencer = VIC::Sequencer.new(@width, @registers, @vic_bank)
      @sprites = VIC::Sprites.new(@registers, @vic_bank, @width)
      @display = Array.new(@width * @height, 0)

      @position = 0

      @character_buffer = Array.new(40, 0)
      @color_buffer = Array.new(40, 0)

      super()
    end

    def cycle!
      if beginning_of_line?
        @display_state.new_frame if rasterline.zero?
        check_raster_irq!
        @sequencer.new_line(rasterline)
        @sprites.start_line(rasterline)
        @display_state.new_line
      end

      @display_state.cycle(rasterline, column)

      fetch_character_data! if dma_active?

      draw!
      finish_line! if end_of_line?

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
      return false unless @display_state.bad_line?

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

    def draw!
      return if blanking?

      col = column - 16
      unless @display_state.display?
        @sequencer.emit_idle(col)
        return
      end

      cell = (@display_state.vc_base + col) & 0x3ff
      screencode = @character_buffer[col] || 0
      @sequencer.emit(screencode, @color_buffer[col] || 1, col,
                      cell, @display_state.rc)
    end

    def end_of_line? = (@position % @width) == @width - 8

    def finish_line!
      return if vblank?

      # Composite the active sprites over the finished background line
      # and copy the line into the frame display.
      if @sprites.active?
        @sprites.composite(@sequencer.colors, @sequencer.fg)
        @sequencer.apply_border
      end
      line = rasterline
      @display[line * @width, @width] = @sequencer.colors
    end

    def video_matrix(index)
      vic_bank.peek(@registers.screen_base + index)
    end

    def check_raster_irq!
      return unless rasterline == @registers.raster_target

      # Latch the raster IRQ flag. The line asserts via #interrupted? when the
      # matching mask bit in $D01A is set.
      @registers.latch_raster_irq!
    end

    def irq_status
      (@registers[0x19] & 0x0f) | 0x70 | (interrupted? ? 0x80 : 0)
    end

    def fetch_character_data!
      vmli = column - 15
      vc = (@display_state.vc_base + vmli) & 0x3ff
      @character_buffer[vmli] = video_matrix(vc)
      @color_buffer[vmli] = vic_bank.peek_color(vc)
    end
  end
end
