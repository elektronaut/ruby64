# frozen_string_literal: true

module Ruby64
  class Memory
    include Addressable

    def initialize(initial = [], length: 2**16, start: 0)
      addressable_at(start, length:)
      @storage = zero_fill(initial)
    end

    def peek(addr)
      @storage[index(addr)]
    end

    def poke(addr, value)
      @storage[index(addr)] = value
      value
    end

    def read(addr, length)
      (addr...(addr + length)).to_a.map { |a| peek(a) }
    end

    def write(addr, bytes)
      Array(bytes).each_with_index { |b, i| poke(addr + i, b) }
    end

    private

    def blank_value
      0
    end

    def zero_fill(initial)
      array = initial.dup
      0.upto(length - 1) do |i|
        array[i] ||= blank_value
      end
      array
    end
  end
end
