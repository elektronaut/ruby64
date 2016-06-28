module C64
  # Memory layout:
  #
  # 0x0000-0x00FF - Page 0       - Zeropage
  # 0x0100-0x01FF - Page 1       - Stack
  # 0x0200-0x02FF - Page 2       - OS/BASIC pointers
  # 0x0300-0x03FF - Page 3       - OS/BASIC pointers
  # 0x0400-0x07FF - Page 4-7     - Screen memory
  # 0x0800-0x09FF - Page 8-159   - BASIC program storage area
  # 0xA000-0xBFFF - Page 160-191 - Machine code program storage (ROM overlay)
  # 0xC000-0xCFFF - Page 192-207 - Machine code program storage
  # 0xD000-0xD3FF - Page 208-211 - VIC II registers
  # 0xD400-0xD7FF - Page 212-215 - SID registers
  # 0xD800-0xDBFF - Page 216-219 - Color memory
  # 0xDC00-0xDCFF - Page 220     - CIA 1
  # 0xDD00-0xDDFF - Page 221     - CIA 2
  # 0xDE00-0xDEFF - Page 222     - I/O 1
  # 0xDF00-0xDFFF - Page 223     - I/O 2
  # 0xE000-0xFFFF - Page 224-255 - Machine code program storage (ROM overlay)

  # Overlays:
  #
  # 0x8000-0x9FFF - Cartridge ROM (low) - 8kb
  # 0xA000-0xBFFF - BASIC ROM / Cartridge ROM (high) - 8kb
  # 0xD000-0xDFFF - Character ROM / I/O - 4kb
  # 0xE000-0xFFFF - KERNAL ROM / Cartridge ROM (high) - 8kb
  class MemoryMap < Memory
    def initialize(initial = [0xff, 0x07], length: 2**16, start: 0)
      super
      @basic     = ROM.load("basic.rom",     0xa000)
      @character = ROM.load("character.rom", 0xd000)
      @kernal    = ROM.load("kernal.rom",    0xe000)
    end

    def peek(addr)
      if overlay_at(addr)
        overlay_at(addr).peek(addr)
      else
        super
      end
    end
    alias [] peek

    private

    def overlays
      [
        basic?     ? @basic     : nil,
        character? ? @character : nil,
        kernal?    ? @kernal    : nil
      ].compact
    end

    def overlay_at(addr)
      overlays.find { |o| o.in_range?(addr) }
    end

    def basic?
      [31, 27, 15, 11].include?(mode)
    end

    def character?
      [27, 26, 25, 11, 10, 9, 3, 2].include?(mode)
    end

    def io?
      [
        31, 30, 29, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 7, 6, 5
      ].include?(mode)
    end

    def kernal?
      [31, 30, 27, 26, 15, 14, 11, 10, 7, 6, 3, 2].include?(mode)
    end

    def mode
      # The EXROM and GAME bits are hardwired for now
      (@memory[1] & 0b111) + 0b11000
    end
  end
end
