# frozen_string_literal: true

module Badline
  module Storage
    class HostDirectory
      def initialize(path)
        @path = path
      end

      def read_file(name)
        entry = find(name)
        return unless entry

        bytes = File.binread(File.join(@path, entry[:file])).bytes
        P00.wraps?(bytes) ? P00.data(bytes) : bytes
      end

      def write_file(name, bytes)
        host_name = "#{name.downcase.tr('/', '_')}.prg"
        File.binwrite(File.join(@path, host_name), bytes.pack("C*"))
      end

      private

      def find(name)
        pattern = Storage.matcher(name)
        entries.find { |e| pattern.match?(e[:name]) }
      end

      def entries
        Dir.children(@path).sort.filter_map { |f| entry_for(f) }
      end

      def entry_for(file)
        case File.extname(file).downcase
        when ".prg"
          { name: File.basename(file, ".*").downcase, file: }
        when ".p00"
          p00_entry(file)
        end
      end

      def p00_entry(file)
        header = File.binread(File.join(@path, file), P00::HEADER_SIZE).bytes
        { name: P00.name(header), file: } if P00.wraps?(header)
      end
    end
  end
end
