# frozen_string_literal: true

module Badline
  module GUI
    class JoyMap
      MAP = {
        "Up" => :up,
        "Down" => :down,
        "Left" => :left,
        "Right" => :right,
        "Space" => :fire
      }.freeze

      def self.parse(event)
        MAP[SDL2::Key.name_of(event.sym)]
      end
    end
  end
end
