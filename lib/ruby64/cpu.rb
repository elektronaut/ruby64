# frozen_string_literal: true

module Ruby64
  class CPU
    class InvalidOpcodeError < StandardError; end
    include InstructionSet

    attr_reader :memory, :cycles, :instructions
    attr_accessor :program_counter, :stack_pointer, :status, :a, :x, :y

    def initialize(memory = nil, debug: false)
      @debug = debug
      @memory = memory || MemoryMap.new
      # The program counter is initialized from 0xfffc
      @program_counter = @memory.peek16(0xfffc)
      # Stack pointer starts at 0x01ff and grows down
      @stack_pointer = Uint8.new(0xff)
      @status = Status.new(0b00100000)
      @a = Uint8.new(0x0)
      @x = Uint8.new(0x0)
      @y = Uint8.new(0x0)

      @loop = Fiber.new { loop { main_loop } }

      @cycles = 0
      @instructions = 0
    end

    def p
      @status.value
    end

    def p=(new_value)
      @status.value = new_value
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

    def cycle
      Fiber.yield
      result = yield if block_given?
      @cycles += 1
      result
    end

    def read_byte(addr)
      cycle { memory[addr] }
    end

    def read_word(addr)
      Uint16.new(
        read_byte(addr),
        read_byte(addr.to_i + 1)
      )
    end

    def read_instruction
      Instruction.find(memory[@program_counter])
    end

    def read_operand(instruction)
      return [] unless instruction.operand?

      if instruction.operand_length == 2
        read_word(@program_counter)
      else
        read_byte(@program_counter)
      end
    end

    def word(bytes)
      Uint16.new(bytes[0], bytes[1])
    end

    def read_address(instruction, operand)
      case instruction.addressing_mode
      when :implied, :immediate
        nil
      when :accumulator
        :accumulator
      when :relative
        @program_counter + operand.signed + 1
      when :zeropage, :absolute
        operand
      when :zeropage_x
        cycle { operand + @x }
      when :zeropage_y
        cycle { operand + @y }
      when :absolute_x
        # Do an extra cycle if page boundary is crossed
        cycle if (operand + @x).high != operand.high
        operand + @x
      when :absolute_y
        # Do an extra cycle if page boundary is crossed
        cycle if (operand + @y).high != operand.high
        operand + @y
      when :indirect
        # This is only used for JMP. There's no carry associated, so an
        # indirect jump to $30FF will wrap around on the same page and read
        # from [0x30ff, 0x3000].
        Uint16.new(
          read_byte(Uint16.new(
                      (operand.low + 1), # Wrap around low byte
                      operand.high
                    )),
          read_byte(operand)
        )
      when :indirect_x
        cycle
        Uint16.new(
          read_byte(operand + @x),
          read_byte(operand + @x + 1) # Wrap around low byte
        )
      when :indirect_y
        # Do an extra cycle if page boundary is crossed
        cycle if operand == 0xff
        read_word(operand) + y
      end
    end

    def realize_value(instruction, operand, address)
      case instruction.addressing_mode
      when :implied
        raise "Implied value can't be realized"
      when :accumulator
        @a
      when :immediate
        operand
      else
        read_byte(address)
      end
    end

    def log(instruction, operand, address)
      return unless @debug

      pc = (@program_counter - 1) - instruction.operand_length
      puts(
        "PC: #{pc.inspect} - " \
        "#{@instruction.name.upcase} #{@instruction.addressing_mode} " \
        "Operand: #{operand.inspect} Address: #{address.inspect}"
      )
    end

    def main_loop
      @instruction = read_instruction
      raise InvalidOpcodeError unless @instruction

      @program_counter += 1
      @cycles += 1

      operand = read_operand(@instruction)
      address = read_address(@instruction, operand)
      @program_counter += @instruction.operand_length

      log(@instruction, operand, address)

      # Run instruction and update processor status
      send(
        @instruction.name,
        @instruction,
        address,
        -> { realize_value(@instruction, operand, address) }
      )

      @instructions += 1
      @instruction = nil
      Fiber.yield
    end
  end
end
