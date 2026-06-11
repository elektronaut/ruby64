# frozen_string_literal: true

module Badline
  class Joystick
    DIRECTIONS = { up: 0, down: 1, left: 2, right: 3, fire: 4 }.freeze

    def initialize
      @pressed = {}
    end

    def press(direction)
      @pressed[direction] = true if DIRECTIONS.key?(direction)
    end

    def release(direction)
      @pressed.delete(direction)
    end

    def port_bits
      bits = 0xff
      DIRECTIONS.each { |dir, bit| bits &= ~(1 << bit) if @pressed[dir] }
      bits
    end
  end
end
