# frozen_string_literal: true

module Ruby64
  module Storage
    class HostDirectory
      def initialize(path)
        @path = path
      end

      def read_file(name)
        entry = find(name)
        File.binread(File.join(@path, entry)).bytes if entry
      end

      private

      def find(name)
        pattern = Storage.matcher(name)
        entries.find { |e| pattern.match?(File.basename(e, ".*").downcase) }
      end

      def entries
        Dir.children(@path).select { |e| e.downcase.end_with?(".prg") }.sort
      end
    end
  end
end
