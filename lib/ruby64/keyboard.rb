# frozen_string_literal: true

module Ruby64
  class Keyboard
    include IntegerHelper

    attr_reader :keys, :matrix

    def initialize
      @keys = []

      @matrix = [
        %i[delete return cursor_h f7 f1 f3 cursor_v],
        %i[3 w a 4 z s e lshift],
        %i[5 r d 6 c f t x],
        %i[7 y g 8 b h u v],
        %i[9 i j 0 m k o n],
        %i[+ p l - . : @ ,],
        %i[£ * ; clr_home rshift = up /],
        %i[1 left control 2 space cbm q run_stop]
      ]
    end

    def press(key)
      @keys << key if valid_key?(key)
    end

    def read_a(port_a, _port_b)
      port_a
    end

    def read_b(port_a, _port_b)
      return 0xff unless keys.any?

      output = 0xff

      matrix.each_with_index do |row, a|
        next unless (port_a[a]).zero?

        row.each_with_index do |key, b|
          output -= (1 << b) if keys.include?(key)
        end
      end

      output
    end

    def release(key)
      @keys.reject! { |k| k == key }
    end

    private

    def valid_key?(key)
      matrix.flatten.include?(key)
    end
  end
end
