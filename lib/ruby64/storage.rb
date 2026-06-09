# frozen_string_literal: true

require "ruby64/storage/p00"
require "ruby64/storage/host_directory"
require "ruby64/storage/disk_image"
require "ruby64/storage/d64_image"
require "ruby64/storage/d71_image"
require "ruby64/storage/d81_image"

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
