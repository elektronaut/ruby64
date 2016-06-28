module C64
  class CPU
    attr_reader :memory
    attr_reader :program_counter, :stack_pointer
    attr_reader :p, :a, :x, :y

    def initialize(memory = nil)
      @memory = memory || MemoryMap.new()
      # The program counter is initialized from 0xfffc
      @program_counter = @memory.peek_16(0xfffc)
      # Stack pointer starts at 0x01ff and grows down
      @stack_pointer = Uint8.new(0xff)
      @p = Uint8.new(0x0)
      @a = Uint8.new(0x0)
      @x = Uint8.new(0x0)
      @y = Uint8.new(0x0)
    end
  end
end
