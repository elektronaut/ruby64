# frozen_string_literal: true

module Badline
  module GUI
    class Window
      DEFAULT_REFRESH_RATE = 60

      attr_reader :renderer

      def initialize(title:, width:, height:, scale: 2, vsync: true)
        SDL2.init(SDL2::INIT_VIDEO | SDL2::INIT_EVENTS)
        SDL2::Hints["SDL_RENDER_SCALE_QUALITY"] = "0" # nearest-neighbour

        @window = SDL2::Window.create(
          title,
          SDL2::Window::POS_CENTERED, SDL2::Window::POS_CENTERED,
          width * scale, height * scale,
          SDL2::Window::Flags::RESIZABLE
        )

        flags = SDL2::Renderer::Flags::ACCELERATED
        flags |= SDL2::Renderer::Flags::PRESENTVSYNC if vsync
        @renderer = @window.create_renderer(-1, flags)
        @renderer.logical_size = [width, height]
      end

      def title=(title)
        @window.title = title
      end

      def refresh_rate
        rate = SDL2::Display.displays.first.current_mode.refresh_rate
        rate.positive? ? rate : DEFAULT_REFRESH_RATE
      rescue StandardError
        DEFAULT_REFRESH_RATE
      end

      def draw(panes)
        @renderer.draw_color = [0, 0, 0]
        @renderer.clear
        panes.each { |pane| pane.render(@renderer) }
        @renderer.present
      end
    end
  end
end
