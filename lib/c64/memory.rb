module C64
  class Memory
    class OutOfBoundsError < StandardError; end
    class ReadOnlyMemoryError < StandardError; end

    attr_reader :length, :start

    def initialize(initial = [], length: 2**16, start: 0)
      @length = length
      @start = start
      @memory = zero_fill(initial)
    end

    def range
      start..(start + (length - 1))
    end

    def in_range?(addr)
      range.include?(addr)
    end

    def peek(addr)
      Uint8.new(@memory[index(addr)])
    end
    alias [] peek

    def peek_16(addr)
      Uint16.new(peek(addr).to_i, peek(addr + 1).to_i)
    end

    def poke(addr, value)
      if value.is_a?(Uint16)
        @memory[index(addr)] = value.low.to_i
        @memory[index(addr + 1)] = value.high.to_i
      else
        @memory[index(addr)] = value.to_i
      end
      value
    end
    alias []= poke

    private

    def index(addr)
      raise OutOfBoundsError unless in_range?(addr)
      addr - start
    end

    def zero_fill(initial)
      array = initial.dup
      0.upto(length - 1) do |i|
        array[i] ||= 0
      end
      array
    end
  end
end
