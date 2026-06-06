# frozen_string_literal: true

module Ruby64
  module GUI
    class Application
      PAL_CLOCK_HZ = 985_248

      def initialize(prg_path: nil, debug: false)
        @computer = Computer.new(debug:)
        load_prg(prg_path) if prg_path

        @panes = [ScreenPane.new(@computer)]
        @window = Window.new(
          title: "Ruby64",
          width: canvas_width, height: canvas_height,
          vsync: ENV["NOVSYNC"].nil?
        )

        rate = @window.refresh_rate
        @cycles_per_frame = PAL_CLOCK_HZ / rate
        puts "Display #{rate} Hz -> #{@cycles_per_frame} cycles/frame"
      end

      def run
        @running = true
        while @running
          handle_events
          @cycles_per_frame.times { @computer.cycle! }
          @window.draw(@panes)
        end
      ensure
        puts @computer.cpu.inspect
      end

      private

      def handle_events
        while (event = SDL2::Event.poll)
          case event
          when SDL2::Event::Quit
            @running = false
          when SDL2::Event::KeyDown
            @computer.keyboard.press(KeyMap.parse(event))
          when SDL2::Event::KeyUp
            @computer.keyboard.release(KeyMap.parse(event))
          end
        end
      end

      def load_prg(path)
        data = File.read(path, mode: "rb").bytes
        @computer.on_init do
          load_addr = @computer.load_prg(data)
          puts "Loaded at $#{load_addr.to_s(16).upcase}"
        end
      end

      def canvas_width
        @panes.map { |pane| pane.left + pane.width }.max
      end

      def canvas_height
        @panes.map { |pane| pane.top + pane.height }.max
      end
    end
  end
end
