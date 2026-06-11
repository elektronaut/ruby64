#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require "badline"
require "sdl2"

require_relative "gui/palette"
require_relative "gui/key_map"
require_relative "gui/joy_map"
require_relative "gui/pane"
require_relative "gui/screen_pane"
require_relative "gui/window"
require_relative "gui/application"

autostart = !ARGV.delete("--no-autostart")
media_path = ARGV[0] if ARGV[0] && File.exist?(ARGV[0])

Badline::GUI::Application.new(media_path:, autostart:).run
