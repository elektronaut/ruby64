# frozen_string_literal: true

module Ruby64
  module Storage
    class D64Image
      SECTOR_SIZE = 256
      DIRECTORY_TRACK = 18
      DIRECTORY_SECTOR = 1
      ENTRY_SIZE = 32
      ENTRIES_PER_SECTOR = 8
      FILETYPE_PRG = 0x02
      NAME_PADDING = 0xa0

      def initialize(path)
        @bytes = File.binread(path).bytes
      end

      def read_file(name)
        pattern = Storage.matcher(name)
        entry = entries.find { |e| pattern.match?(e[:name]) }
        read_chain(entry[:track], entry[:sector]) if entry
      end

      private

      def entries
        @entries ||= each_sector(DIRECTORY_TRACK, DIRECTORY_SECTOR)
                     .flat_map { |data| parse_entries(data) }
      end

      def parse_entries(data)
        (0...ENTRIES_PER_SECTOR).filter_map do |i|
          entry = data[i * ENTRY_SIZE, ENTRY_SIZE]
          next unless (entry[2] & 0x07) == FILETYPE_PRG

          { name: decode_name(entry[5, 16]),
            track: entry[3],
            sector: entry[4] }
        end
      end

      def decode_name(bytes)
        Storage.ascii(bytes.take_while { |b| b != NAME_PADDING }).downcase
      end

      def read_chain(track, sector)
        each_sector(track, sector).flat_map do |data|
          data[0].zero? ? data[2..data[1]] : data[2..]
        end
      end

      def each_sector(track, sector)
        return to_enum(:each_sector, track, sector) unless block_given?

        visited = {}
        while track != 0 && !visited[[track, sector]]
          visited[[track, sector]] = true
          data = sector_at(track, sector)
          yield data
          track, sector = data[0, 2]
        end
      end

      def sector_at(track, sector)
        @bytes[sector_offset(track, sector), SECTOR_SIZE]
      end

      def sector_offset(track, sector)
        ((1...track).sum { |t| sectors_in(t) } + sector) * SECTOR_SIZE
      end

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
