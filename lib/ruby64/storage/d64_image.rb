# frozen_string_literal: true

module Ruby64
  module Storage
    class D64Image < DiskImage
      private

      def directory_track = 18
      def directory_sector = 1

      def sectors_in(track)
        case track
        when 1..17 then 21
        when 18..24 then 19
        when 25..30 then 18
        else 17
        end
      end
    end
  end
end
