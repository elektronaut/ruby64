# frozen_string_literal: true

module Ruby64
  class ColorMemory < Memory
    def poke(addr, value)
      # Only write the lower 4 bits
      super(addr, value & 0x0f)
    end

    private

    def blank_value
      rand(16) << 4
    end
  end
end
