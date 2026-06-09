# frozen_string_literal: true

module Ruby64
  module Storage
    class D81Image < DiskImage
      private

      def directory_track = 40
      def directory_sector = 3

      def sectors_in(_track) = 40
    end
  end
end
