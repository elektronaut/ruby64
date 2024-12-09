# frozen_string_literal: true

module Ruby64
  module Addressable
    include IntegerHelper

    class ReadOnlyMemoryError < StandardError; end
    class OutOfBoundsError < StandardError; end

    attr_reader :start, :length, :end

    def addressable_at(start = 0, length: 2**16)
      @start = start
      @length = length
      @end = start + length
    end

    def range
      start..(start + (length - 1))
    end

    def in_range?(addr)
      addr_i = addr.to_i
      addr_i >= @start && addr_i < @end
    end

    def peek(_addr)
      raise NoMethodError
    end

    def peek16(addr)
      uint16(peek(addr), peek(addr + 1))
    end

    def poke(_addr, _value)
      raise NoMethodError
    end

    def poke16(addr, value)
      poke(addr, low_byte(value))
      poke(addr + 1, high_byte(value))
      value
    end

    def [](addr)
      peek(addr)
    end

    def []=(addr, value)
      poke(addr, value)
    end

    private

    def index(addr)
      unless in_range?(addr.to_i)
        raise OutOfBoundsError, "#{addr.inspect} (#{range})"
      end

      addr.to_i - start
    end
  end
end
