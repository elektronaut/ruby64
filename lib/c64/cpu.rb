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

      @cycles = 0
      @instructions = 0
    end

    def step!
      fetch_instruction unless @instruction && @instruction.alive?
      cycle! while @instruction.alive?
    end

    def cycle!
      unless @instruction && @instruction.alive?
        fetch_instruction
      end
      @instruction.resume
      nil
    end

    private

    def fetch_instruction
      # puts "Fetching instruction"
      @program_counter += 1
      opcode = memory[@program_counter.to_i]
      # puts "starting instruction #{opcode}"
      @cycles += 1
      @instruction = Fiber.new do
        # Run the instruction
        cycle { foo = :bar }
        cycle { foo = :baz }

        # puts "ending instruction"
        @instructions += 1
      end
    end

    def cycle(&block)
      Fiber.yield
      yield
      @cycles += 1
    end
  end
end
