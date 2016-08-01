# frozen_string_literal: true
module Ruby64
  class ROM < Memory
    class << self
      def load(filename, start = 0x0)
        data = File.read(file_path(filename)).bytes
        new(data, length: data.length, start: start)
      end

      private

      def file_path(filename)
        File.join(File.dirname(__FILE__), "roms", filename)
      end
    end

    def poke(_addr, _value)
      raise ReadOnlyMemoryError
    end
    alias []= poke
  end
end
