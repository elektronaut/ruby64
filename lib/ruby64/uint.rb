# frozen_string_literal: true
module Ruby64
  # Abstract unsigned integer
  class Uint
    include Comparable

    attr_reader :value

    def initialize(value)
      @value = convert(value)
    end

    def coerce(other)
      case other
      when self.class
        [other, self]
      when Numeric
        [self.class.new(other), to_i]
      else
        raise TypeError, "#{self.class} can't be coerced into #{other.class}"
      end
    end

    def <=>(other)
      case other
      when Uint, Numeric
        value <=> convert(other)
      else
        value <=> other
      end
    end

    def inspect
      format("#{self.class.name}(0x%0#{bytes.length * 2}x)", value)
    end

    def to_int
      value
    end

    alias to_i to_int

    def +(other)
      new(value + convert(other))
    end

    def -(other)
      new(value - convert(other))
    end

    def *(other)
      new(value * convert(other))
    end

    def /(other)
      new(value / convert(other))
    end

    def <<(other)
      new(value << convert(other))
    end

    def >>(other)
      new(value >> convert(other))
    end

    def &(other)
      new(value & convert(other))
    end

    def |(other)
      new(value | convert(other))
    end

    def ^(other)
      new(value ^ convert(other))
    end

    def ~
      new(value ^ mask)
    end

    def [](i)
      value[i]
    end

    def respond_to_missing?(name)
      value.respond_to_missing?(name) || super
    end

    def method_missing(name, *args)
      new(value.send(name, *args)) || super
    end

    def nonzero?
      value.nonzero?
    end

    def positive?
      value.positive?
    end

    def zero?
      value.zero?
    end

    private

    def new(value)
      self.class.new(value)
    end
  end

  # 8 bit integer, unsigned
  class Uint8 < Uint
    def bytes
      [self]
    end

    def mask
      0xff
    end

    def signed
      value > 127 ? value - 256 : value
    end

    private

    def convert(value)
      value.to_i & 0xff
    end
  end

  # 16 bit integer, unsigned, little endian
  class Uint16 < Uint
    def initialize(value_or_low, high = nil)
      return super(value_or_low) unless high
      @value = convert((high.to_i << 8) + value_or_low.to_i)
    end

    def bytes
      [low, high]
    end

    def high
      Uint8.new(value >> 8)
    end

    def low
      Uint8.new(value)
    end

    def mask
      0xffff
    end

    private

    def convert(value)
      value.to_i & 0xffff
    end
  end
end
