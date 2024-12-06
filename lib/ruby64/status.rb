# frozen_string_literal: true

module Ruby64
  class Status
    attr_accessor :value

    def initialize(value = 0x0)
      @value = value
    end

    def carry
      carry? ? 1 : 0
    end

    def carry?
      !value.nobits?(masks[:carry])
    end

    def carry=(enabled)
      update(masks[:carry], enabled)
    end

    def zero?
      !value.nobits?(masks[:zero])
    end

    def zero=(enabled)
      update(masks[:zero], enabled)
    end

    def interrupt?
      !value.nobits?(masks[:interrupt])
    end

    def interrupt=(enabled)
      update(masks[:interrupt], enabled)
    end

    def decimal?
      !value.nobits?(masks[:decimal])
    end

    def decimal=(enabled)
      update(masks[:decimal], enabled)
    end

    def break?
      !value.nobits?(masks[:break])
    end

    def break=(enabled)
      update(masks[:break], enabled)
    end

    def overflow?
      !value.nobits?(masks[:overflow])
    end

    def overflow=(enabled)
      update(masks[:overflow], enabled)
    end

    def negative?
      !value.nobits?(masks[:negative])
    end

    def negative=(enabled)
      update(masks[:negative], enabled)
    end

    private

    def masks
      { carry: 0b00000001,
        zero: 0b00000010,
        interrupt: 0b00000100,
        decimal: 0b00001000,
        break: 0b00010000,
        overflow: 0b01000000,
        negative: 0b10000000 }
    end

    def update(mask, enabled)
      @value = if enabled && enabled != 0
                 @value | mask
               else
                 @value & ~mask
               end
    end
  end
end
