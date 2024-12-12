# frozen_string_literal: true

module Ruby64
  class CPU
    STATUS_FLAGS = [:carry, :zero, :interrupt, :decimal, :break, 1,
                    :overflow, :negative].freeze

    class InvalidOpcodeError < StandardError; end
    include IntegerHelper
    include InstructionSet

    attr_reader :memory, :cycles, :instructions
    attr_accessor :program_counter, :stack_pointer, :status, :a, :x, :y,
                  :nmi, :irq

    def initialize(memory = nil, debug: false)
      @debug = debug
      @memory = memory || Memory.new
      @status = Status.new(STATUS_FLAGS, value: 0b00100000)
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

      pc = (program_counter + 1) & 0xffff

      write_byte(stack_address, high_byte(pc))
      @stack_pointer = (@stack_pointer - 1) & 0xff
      write_byte(stack_address, low_byte(pc))
      @stack_pointer = (@stack_pointer - 1) & 0xff
      write_byte(stack_address, status.value)
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
             read_byte((addr + 1) & 0xffff))
    end

    def read_zeropage_word(addr)
      uint16(read_byte(addr & 0xff),
             read_byte((addr + 1) & 0xff))
    end

    def read_instruction
      Instruction.find(memory[program_counter])
    end

    def read_operand(instruction)
      return [] unless instruction.operand?

      if instruction.operand_length == 2
        read_word(program_counter)
      else
        read_byte(program_counter)
      end
    end

    def reset_registers
      # The program counter is initialized from the reset vector
      @program_counter = @memory.peek16(0xfffc)
      # Stack pointer starts at 0x01ff and grows down
      @stack_pointer = 0xff
      @a = @x = @y = 0x0
    end

    def extra_cycle(instruction, boundary_condition)
      return cycle unless instruction.boundary_cycle?

      boundary_condition && cycle
    end

    def read_address(instruction, operand)
      case instruction.addressing_mode
      when :implied, :immediate
        nil
      when :accumulator
        :accumulator
      when :relative
        (@program_counter + signed_int8(operand) + 1) & 0xffff
      when :zeropage, :absolute
        operand
      when :zeropage_x
        cycle { (operand + @x) & 0xff }
      when :zeropage_y
        cycle { (operand + @y) & 0xff }
      when :absolute_x
        # Do an extra cycle if page boundary is crossed
        extra_cycle(instruction, high_byte(operand + @x) != high_byte(operand))
        (operand + @x) & 0xffff
      when :absolute_y
        # Do an extra cycle if page boundary is crossed
        extra_cycle(instruction, high_byte(operand + @y) != high_byte(operand))
        (operand + @y) & 0xffff
      when :indirect
        # This is only used for JMP. There's no carry associated, so an
        # indirect jump to $30FF will wrap around on the same page and read
        # from [0x30ff, 0x3000].
        uint16(
          read_byte(operand),
          read_byte(uint16(
                      (low_byte(operand) + 1) & 0xff, # Wrap around low byte
                      high_byte(operand)
                    ))
        )
      when :indirect_x
        cycle
        read_zeropage_word(operand + @x)
      when :indirect_y
        value = read_zeropage_word(operand)
        # Do an extra cycle if page boundary is crossed
        extra_cycle(instruction, ((value & 0xff) + y) > 0xff)
        (value + y) & 0xffff
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

    def stack_address(offset = 0)
      uint16((stack_pointer + offset) & 0xff, 0x01)
    end

    def log(instruction, operand, address)
      return unless @debug

      pc = (@program_counter - 1) - instruction.operand_length
      puts(
        "#{@cycles}: " \
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

        @program_counter = (@program_counter + 1) & 0xffff
        @cycles += 1

        operand = read_operand(@instruction)
        address = read_address(@instruction, operand)

        @program_counter = (@program_counter + @instruction.operand_length) &
                           0xffff

        log(@instruction, operand, address)

        # Run instruction and update processor status
        send(
          @instruction.name,
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
