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

    def cycle(&block)
      Fiber.yield
      result = yield
      @cycles += 1
      result
    end

    def read_byte(addr)
      cycle { memory[addr] }
    end

    def read_word(addr)
      Uint16.new(read_byte(addr).to_i, read_byte(addr + 1).to_i)
    end

    def read_instruction
      @program_counter += 1
      Instruction.find(memory[@program_counter])
    end

    def read_operand(instruction)
      return [] unless instruction.operand?
      if instruction.operand_length == 2
        read_word(@program_counter + 1)
      else
        read_byte(@program_counter + 1)
      end
    end

    def word(bytes)
      Uint16.new(bytes[0], bytes[1])
    end

    def read_address(instruction, operand)
      case instruction.addressing_mode
      when :implied, :immediate, :accumulator
        nil
      when :relative
        operand.signed + @program_counter
      when :zeropage
        operand
      when :zeropage_x
        operand + x
      when :zeropage_y
        operand + y
      when :absolute
        operand
      when :absolute_x
        # TODO: Handle page boundary
        operand + x
      when :absolute_y
        # TODO: Handle page boundary
        operand + y
      when :indirect
        # This is only used for JMP. There's no carry associated, so an
        # indirect jump to $30FF will wrap around on the same page and read
        # from [0x30ff, 0x3000].
        Uint16.new(
          read_byte(operand),
          read_byte(Uint16.new(
            operand.high,
            (operand.low + 1) # Wrap around low byte
          ))
        )
      when :indirect_x
        read_word(operand + x)
      when :indirect_y
        # TODO: Handle page boundary
        read_word(operand + y)
      end
    end

    def update_status(flags = {})
      return nil unless flags && flags.any?
      raise "TODO: Modify processor status"
    end

    def main_loop
      @instruction = read_instruction
      @cycles += 1

      operand = read_operand(@instruction)
      address = read_address(@instruction, operand)

      @program_counter += @instruction.operand_length

      # Run instruction and update processor status
      update_status(
        self.send(@instruction.name, @instruction, address, operand)
      )

      @instructions += 1
      @instruction = nil
      Fiber.yield
    end
  end
end
