# frozen_string_literal: true

module Ruby64
  class Memory
    class OutOfBoundsError < StandardError; end
    class ReadOnlyMemoryError < StandardError; end

    attr_reader :length, :start, :end

    def initialize(initial = [], length: 2**16, start: 0)
      @length = length
      @start = start
      @end = start + length
      @memory = zero_fill(initial)
    end

    def range
      start..(start + (length - 1))
    end

    def in_range?(addr)
      addr_i = addr.to_i
      addr_i >= @start && addr_i < @end
    end

    def peek(addr)
      Uint8.new(@memory[index(addr)])
    end
    alias [] peek

    def peek16(addr)
      Uint16.new(
        peek(addr),
        peek(addr + 1)
      )
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

    def read(addr, length)
      (addr...(addr + length)).to_a.map { |a| peek(a) }
    end

    def write(addr, bytes)
      Array(bytes).each_with_index { |b, i| poke(addr + i, b) }
    end

    private

    def index(addr)
      unless in_range?(addr.to_i)
        raise OutOfBoundsError, "#{addr.inspect} (#{range})"
      end

      addr.to_i - start
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
