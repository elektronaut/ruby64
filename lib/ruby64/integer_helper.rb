# frozen_string_literal: true

module Ruby64
  module IntegerHelper
    def bcd(number)
      high, low = number.divmod(10)
      (high << 4) + low
    end

    def bcd_to_i(number)
      (((number & 0xf0) >> 4) * 10) + (number & 0x0f)
    end

    def format8(number)
      "0x#{number.to_s(16).rjust(2, '0')}"
    end

    def format16(number)
      "0x#{number.to_s(16).rjust(4, '0')}"
    end

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
