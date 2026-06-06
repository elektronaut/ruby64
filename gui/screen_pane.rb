# frozen_string_literal: true

module Ruby64
  module GUI
    class ScreenPane < Pane
      WIDTH = 384
      HEIGHT = 272
      COL_OFFSET = 96
      ROW_OFFSET = 20

      def initialize(computer, left: 0, top: 0, palette: Palette.new)
        super(width: WIDTH, height: HEIGHT, left:, top:)
        @computer = computer
        @palette = palette
      end

      def render(renderer)
        blit(renderer, framebuffer)
      end

      private

      def framebuffer
        display = @computer.vic.display
        vic_width = @computer.vic.width

        pixels = []
        HEIGHT.times do |row|
          base = ((row + ROW_OFFSET) * vic_width) + COL_OFFSET
          pixels.concat(display[base, WIDTH])
        end
        pixels.map! { |c| @palette[c] }
        pixels.join
      end
    end
  end
end
