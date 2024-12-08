# frozen_string_literal: true

module Ruby64
  class CPU
    class InvalidOpcodeError < StandardError; end
    include IntegerHelper
    include InstructionSet

    CPU_FLAGS = [:carry, :zero, :interrupt, :decimal, :break, nil,
                 :overflow, :negative].freeze

    attr_reader :memory, :cycles, :instructions
    attr_accessor :program_counter, :stack_pointer, :status, :a, :x, :y,
                  :nmi, :irq

    def initialize(memory = nil, debug: false)
      @debug = debug
      @memory = memory || MemoryMap.new
      @status = Status.new(CPU_FLAGS, value: 0b00100000)
      reset_registers

      @nmi = @irq = false

      @loop = Fiber.new { loop { main_loop } }

      @cycles = 0
      @instructions = 0
    end

    def reset!
      status.interrupt = true
      reset_registers
    end

    def p
      status.value
    end

    def p=(new_value)
      status.value = new_value
    end

    def step!
      @loop.resume unless @instruction || @interrupt
      cycle! while @instruction || @interrupt
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

    def handle_interrupt(vector, pre_cycles = 2)
      pre_cycles.times { cycle }
      write_byte(stack_address, high_byte(@program_counter))
      @stack_pointer = (@stack_pointer - 1) & 0xff
      write_byte(stack_address, low_byte(@program_counter))
      @stack_pointer = (@stack_pointer - 1) & 0xff
      write_byte(stack_address, status.value & ~0b00010000)
      @stack_pointer = (@stack_pointer - 1) & 0xff
      status.interrupt = true
      @program_counter = read_word(vector)
    end

    def handle_interrupts
      @interrupt = if nmi
                     0xfffa
                   elsif irq && !status.interrupt?
                     0xfffe
                   end

      handle_interrupt(@interrupt) if @interrupt
      @interrupt = nil
      @nmi = @irq = false
    end

    def read_byte(addr)
      cycle { memory[addr] }
    end

    def read_word(addr)
      uint16(read_byte(addr),
             read_byte(addr + 1))
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

    def reset_registers
      # The program counter is initialized from the reset vector
      @program_counter = @memory.peek16(0xfffc)
      # Stack pointer starts at 0x01ff and grows down
      @stack_pointer = 0xff
      @a = @x = @y = 0x0
    end

    def read_address(instruction, operand)
      case instruction.addressing_mode
      when :implied, :immediate
        nil
      when :accumulator
        :accumulator
      when :relative
        @program_counter + signed_int8(operand) + 1
      when :zeropage, :absolute
        operand
      when :zeropage_x
        cycle { operand + @x }
      when :zeropage_y
        cycle { operand + @y }
      when :absolute_x
        # Do an extra cycle if page boundary is crossed
        cycle if high_byte(operand + @x) != high_byte(operand)
        operand + @x
      when :absolute_y
        # Do an extra cycle if page boundary is crossed
        cycle if high_byte(operand + @y) != high_byte(operand)
        operand + @y
      when :indirect
        # This is only used for JMP. There's no carry associated, so an
        # indirect jump to $30FF will wrap around on the same page and read
        # from [0x30ff, 0x3000].
        uint16(
          read_byte(uint16(
                      (low_byte(operand) + 1) & 0xff, # Wrap around low byte
                      high_byte(operand)
                    )),
          read_byte(operand)
        )
      when :indirect_x
        cycle
        uint16(
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

    def stack_address
      uint16(stack_pointer, 0x01)
    end

    def log(instruction, operand, address)
      return unless @debug

      pc = (@program_counter - 1) - instruction.operand_length
      puts(
        "PC: #{pc.to_s(16)} - " \
        "#{@instruction.name.upcase} #{@instruction.addressing_mode} " \
        "Operand: #{operand.inspect} Address: #{address.inspect}"
      )
    end

    def main_loop
      if nmi || irq
        handle_interrupts
      else
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
      end
      Fiber.yield
    end

    def write_byte(addr, value)
      if addr == :accumulator
        @a = value
      else
        cycle { memory[addr] = value }
      end
    end
  end
end
