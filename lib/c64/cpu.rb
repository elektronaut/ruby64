module C64
  class CPU
    include InstructionSet

    attr_reader :memory
    attr_reader :program_counter, :stack_pointer
    attr_reader :p, :a, :x, :y

    attr_reader :cycles, :instructions

    def initialize(memory = nil)
      @memory = memory || MemoryMap.new
      # The program counter is initialized from 0xfffc
      @program_counter = @memory.peek_16(0xfffc)
      # Stack pointer starts at 0x01ff and grows down
      @stack_pointer = Uint8.new(0xff)
      @p = Uint8.new(0x0)
      @a = Uint8.new(0x0)
      @x = Uint8.new(0x0)
      @y = Uint8.new(0x0)

      @loop = Fiber.new { main_loop while true }

      @cycles = 0
      @instructions = 0
    end

    def step!
      @loop.resume unless @instruction
      cycle! while @instruction
    end

    def cycle!
      @loop.resume
      nil
    end

    private

    def fetch_instruction
      @program_counter += 1
      memory[@program_counter.to_i]
    end

    def main_loop
      @instruction = fetch_instruction
      @cycles += 1

      # Do the instruction here
      cycle { 1 + 2 }
      cycle { 3 + 4 }

      @instructions += 1
      @instruction = nil
      Fiber.yield
    end

    def cycle(&block)
      Fiber.yield
      yield
      @cycles += 1
    end
  end
end
