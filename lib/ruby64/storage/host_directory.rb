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
        pattern = matcher(name)
        entries.find { |e| pattern.match?(File.basename(e, ".*").downcase) }
      end

      def entries
        Dir.children(@path).select { |e| e.downcase.end_with?(".prg") }.sort
      end

      def matcher(name)
        escaped = Regexp.escape(name.downcase)
                        .gsub('\*', ".*")
                        .gsub('\?', ".")
        Regexp.new("\\A#{escaped}\\z")
      end
    end
  end
end
