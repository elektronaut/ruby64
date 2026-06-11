# frozen_string_literal: true

module Badline
  module GUI
    class ScreenPane < Pane
      WIDTH = 384
      HEIGHT = 272
      COL_OFFSET = 96
      ROW_OFFSET = 20

      ROW_BYTES = WIDTH * 4

      def initialize(computer, left: 0, top: 0, palette: Palette.new)
        super(width: WIDTH, height: HEIGHT, left:, top:)
        @computer = computer
        @palette = palette.dwords
        @buffer = ("\x00" * (HEIGHT * ROW_BYTES)).b
      end

      def render(renderer)
        blit(renderer, framebuffer)
      end

      private

      # Repack only the scanlines the VIC has touched since the last frame.
      def framebuffer
        vic = @computer.vic
        display = vic.display
        vic_width = vic.width
        dirty = vic.dirty_lines

        HEIGHT.times do |row|
          next unless dirty[row + ROW_OFFSET]

          @buffer[row * ROW_BYTES, ROW_BYTES] =
            pack_row(display, vic_width, row)
        end
        vic.clear_dirty_lines!
        @buffer
      end

      def pack_row(display, vic_width, row)
        line = display[((row + ROW_OFFSET) * vic_width) + COL_OFFSET, WIDTH]
        line.map! { |c| @palette[c] }
        line.pack("V*")
      end
    end
  end
end
