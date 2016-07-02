module C64
  class Status
    attr_accessor :value

    def initialize(value = 0x0)
      @value = value
    end

    def carry?
      @value & masks[:carry] != 0
    end

    def carry=(enabled)
      update(masks[:carry], enabled)
    end

    def zero?
      @value & masks[:zero] != 0
    end

    def zero=(enabled)
      update(masks[:zero], enabled)
    end

    def interrupt?
      @value & masks[:interrupt] != 0
    end

    def interrupt=(enabled)
      update(masks[:interrupt], enabled)
    end

    def decimal?
      @value & masks[:decimal] != 0
    end

    def decimal=(enabled)
      update(masks[:decimal], enabled)
    end

    def break?
      @value & masks[:break] != 0
    end

    def break=(enabled)
      update(masks[:break], enabled)
    end

    def overflow?
      @value & masks[:overflow] != 0
    end

    def overflow=(enabled)
      update(masks[:overflow], enabled)
    end

    def negative?
      @value & masks[:negative] != 0
    end

    def negative=(enabled)
      update(masks[:negative], enabled)
    end

    private

    def masks
      { carry:     0b00000001,
        zero:      0b00000010,
        interrupt: 0b00000100,
        decimal:   0b00001000,
        break:     0b00010000,
        overflow:  0b01000000,
        negative:  0b10000000 }
    end

    def update(mask, enabled)
      if enabled
        @value = @value | mask
      else
        @value = @value & ~mask
      end
    end
  end
end
