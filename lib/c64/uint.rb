module C64
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
        [self.class.new(other), self.to_i]
      else
        raise TypeError, "#{self.class} can't be coerced into #{other.class}"
      end
    end

    def <=>(other)
      value <=> convert(other)
    end

    def inspect
      "#{self.class.name}(0x%0#{bytes.length * 2}x)" % value
    end

    def to_int
      value
    end

    alias to_i to_int

    def +(other)
      new(value + other)
    end

    def -(other)
      new(value - other)
    end

    def *(other)
      new(value * other)
    end

    def /(other)
      new(value / other)
    end

    def <<(other)
      new(value << other)
    end

    def >>(other)
      new(value >> other)
    end

    def &(other)
      new(value & other)
    end

    def |(other)
      new(value | other)
    end

    def ^(other)
      new(value ^ other)
    end

    def ~
      new(value ^ mask)
    end

    def [](i)
      value[i]
    end

    def method_missing(name, *args)
      # raise "#{name} called on #{inspect}"
      new(value.send(name, *args))
    end

    private

    def new(value)
      self.class.new(value)
    end

    def convert(value)
      value.to_i & mask
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
  end

  # 16 bit integer, unsigned
  class Uint16 < Uint
    def initialize(value_or_high, low = nil)
      return super(value_or_high) unless low
      @value = convert((value_or_high.to_i << 8) + low.to_i)
    end

    def bytes
      [high, low]
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
  end
end
