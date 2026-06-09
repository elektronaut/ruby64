# frozen_string_literal: true

module Ruby64
  module GUI
    class Application
      PAL_CLOCK_HZ = 985_248
      TITLE = "Ruby64"
      TOGGLE_SYM = SDL2::Key::TAB

      SHARED_KEYS = %i[up left cursor_h cursor_v space].freeze

      def initialize(media_path: nil, debug: false)
        @computer = Computer.new(debug:)
        puts Media.attach(@computer, media_path) if media_path

        @joystick_mode = false
        @panes = [ScreenPane.new(@computer)]
        @window = Window.new(
          title: TITLE,
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
            handle_key_down(event)
          when SDL2::Event::KeyUp
            handle_key_up(event)
          end
        end
      end

      def handle_key_down(event)
        if event.sym == TOGGLE_SYM
          toggle_joystick_mode
        elsif @joystick_mode && (dir = JoyMap.parse(event))
          @computer.joystick2.press(dir)
        else
          @computer.keyboard.press(KeyMap.parse(event))
        end
      end

      def handle_key_up(event)
        return if event.sym == TOGGLE_SYM

        if @joystick_mode && (dir = JoyMap.parse(event))
          @computer.joystick2.release(dir)
        else
          @computer.keyboard.release(KeyMap.parse(event))
        end
      end

      def toggle_joystick_mode
        @joystick_mode = !@joystick_mode
        if @joystick_mode
          SHARED_KEYS.each { |key| @computer.keyboard.release(key) }
        else
          Joystick::DIRECTIONS.each_key { |dir| @computer.joystick2.release(dir) }
        end
        @window.title = @joystick_mode ? "#{TITLE} [JOY]" : TITLE
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
