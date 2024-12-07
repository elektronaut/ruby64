# frozen_string_literal: true

module Ruby64
  module IntegerHelper
    def high_byte(number)
      (number >> 8) & 0xff
    end

    def low_byte(number)
      number & 0xff
    end

    def signed_int8(number)
      uint = number & 0xff
      uint > 127 ? uint - 256 : uint
    end

    def uint16(low, high)
      (high << 8) + low
    end
  end
end
