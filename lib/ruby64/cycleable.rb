# frozen_string_literal: true

module Ruby64
  class Cycleable
    attr_reader :cycles

    def initialize
      @loop = Fiber.new { loop { main_loop } }
      @cycles = 0
    end

    def cycle!
      @loop.resume
      nil
    end

    private

    def cycle
      Fiber.yield
      result = yield if block_given?
      @cycles += 1
      result
    end

    def main_loop
      Fiber.yield
    end
  end
end
