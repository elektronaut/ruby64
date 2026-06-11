# frozen_string_literal: true

module Badline
  module Storage
    module P00
      MAGIC = "C64File\x00".bytes.freeze
      HEADER_SIZE = 26

      class << self
        def wraps?(bytes)
          bytes[0, 8] == MAGIC
        end

        def name(bytes)
          Storage.ascii(bytes[8, 16].take_while(&:positive?)).downcase
        end

        def data(bytes)
          bytes[HEADER_SIZE..]
        end
      end
    end
  end
end
