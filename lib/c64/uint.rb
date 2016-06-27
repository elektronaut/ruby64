module C64
  # Abstract unsigned integer
  class Uint
    include Comparable

    attr_reader :value

    def initialize(value)
      @value = convert(value)
    end

    def coerce(other)
      [self.class.new(other), self]
    end

    def <=>(other)
      value <=> convert(other)
    end

    def inspect
      "#{self.class.name}(0x%0#{bytes.length * 2}x)" % value
    end

    def to_i
      value
    end

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
  end

  # 16 bit integer, unsigned, big-endian
  class Uint16 < Uint
    def initialize(value_or_low, high = nil)
      return super(value_or_low) unless high
      @value = convert((high << 8) + value_or_low)
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
  end
end
