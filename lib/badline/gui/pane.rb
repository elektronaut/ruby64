# frozen_string_literal: true

module Badline
  module GUI
    class Pane
      attr_reader :left, :top, :width, :height

      def initialize(width:, height:, left: 0, top: 0)
        @width = width
        @height = height
        @left = left
        @top = top
        @rect = SDL2::Rect.new(left, top, width, height)
      end

      def render(_renderer)
        raise NotImplementedError, "#{self.class} must implement #render"
      end

      private

      def blit(renderer, pixels)
        surface = SDL2::Surface.from_string(
          pixels, width, height, 32, width * 4,
          0x0000_00ff, 0x0000_ff00, 0x00ff_0000, 0xff00_0000
        )
        texture = renderer.create_texture_from(surface)
        renderer.copy(texture, nil, @rect)
      ensure
        texture&.destroy
        surface&.destroy
      end
    end
  end
end
