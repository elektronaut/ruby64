# frozen_string_literal: true

module Badline
  # CIA 1 peripheral combining the keyboard matrix with the control ports.
  #
  # Joystick switches share the same lines as the keyboard matrix and are
  # wired-AND with it (active low). Port 2 sits on Port A.
  class ControlPorts
    attr_reader :keyboard, :joystick2

    def initialize(keyboard:, joystick2:)
      @keyboard = keyboard
      @joystick2 = joystick2
    end

    def read_a(port_a, port_b)
      keyboard.read_a(port_a, port_b) & joystick2.port_bits
    end

    def read_b(port_a, port_b)
      keyboard.read_b(port_a, port_b)
    end
  end
end
