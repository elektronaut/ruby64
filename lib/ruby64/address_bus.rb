# frozen_string_literal: true

module Ruby64
  # Memory layout:
  #
  # 0x0000-0x00FF - Page 0       - Zeropage
  # 0x0100-0x01FF - Page 1       - Stack
  # 0x0200-0x02FF - Page 2       - OS/BASIC pointers
  # 0x0300-0x03FF - Page 3       - OS/BASIC pointers
  # 0x0400-0x07FF - Page 4-7     - Screen memory
  # 0x0800-0x9FFF - Page 8-159   - BASIC program storage area
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
  class AddressBus
    include Addressable

    attr_reader :io_port, :ram, :basic_rom, :character_rom, :kernal_rom,
                :vic, :sid, :color_ram, :cia1, :cia2, :keyboard

    def initialize
      @ram = Memory.new([0xff, 0x07], length: 2**16, start: 0)

      @basic_rom     = ROM.load("basic.rom",     0xa000)
      @character_rom = ROM.load("character.rom", 0xd000)
      @kernal_rom    = ROM.load("kernal.rom",    0xe000)

      @keyboard = Keyboard.new
      @vic  = VIC.new(self)
      @cia1 = CIA.new(start: 0xdc00, peripheral: @keyboard)
      @cia2 = CIA.new(start: 0xdd00)
      @sid  = SID.new

      @color_ram = ColorMemory.new(start: 0xd800, length: 2**10)

      @io_port = Status.new(%i[basic kernal io tape_out tape_switch tape_motor],
                            value: 0b00110111)
    end

    def disable_overlays!
      poke(1, 0)
    end

    def peek(addr)
      case addr
      when 0x01 then @io_port.value
      else read_source(addr).peek(addr)
      end
    end

    def poke(addr, value)
      case addr
      when 0x01 then @io_port.value = value
      else write_target(addr).poke(addr, value)
      end
    end

    private

    def io_source(addr)
      case addr
      when 0xd000..0xd3ff then vic
      when 0xd400..0xd7ff then sid
      when 0xd800..0xdbff then color_ram
      when 0xdc00..0xdcff then cia1
      when 0xdd00..0xddff then cia2
      end
    end

    def read_source(addr)
      source = case addr
               when 0xa000..0xbfff then basic? && basic_rom
               when 0xd000..0xdfff
                 if io?
                   io_source(addr)
                 elsif character?
                   character_rom
                 end
               when 0xe000..0xffff then kernal? && kernal_rom
               end
      source || ram
    end

    def write_target(addr)
      return ram unless io?

      io_source(addr) || ram
    end

    def basic?
      io_port.kernal? && io_port.basic?
    end

    def character?
      (io_port.basic? || io_port.kernal?) && !io_port.io?
    end

    def io?
      (io_port.basic? || io_port.kernal?) && io_port.io?
    end

    def kernal?
      io_port.kernal?
    end
  end
end
