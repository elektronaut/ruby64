# frozen_string_literal: true

module Ruby64
  module Storage
    class D71Image < D64Image
      private

      def sectors_in(track)
        track > 35 ? super(track - 35) : super
      end
    end
  end
end
