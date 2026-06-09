# frozen_string_literal: true

module Ruby64
  module Storage
    class << self
      # Folds shifted PETSCII letters to their ASCII equivalents.
      def ascii(bytes)
        bytes.map { |b| b.between?(0xc1, 0xda) ? b - 0x80 : b }.pack("C*")
      end

      # CBM-style filename pattern: "*" and "?" wildcards, case-insensitive.
      def matcher(name)
        escaped = Regexp.escape(name.downcase)
                        .gsub('\*', ".*")
                        .gsub('\?', ".")
        Regexp.new("\\A#{escaped}\\z")
      end
    end
  end
end
