#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require "ruby64"
require "ruby2d"

computer = Ruby64::Computer.new(debug: false)

if ARGV[0] && File.exist?(ARGV[0])
  prg_data = File.read(ARGV[0], mode: "rb").bytes

  computer.on_init do
    load_addr = computer.load_prg(prg_data)
    puts "Loaded at $#{load_addr.to_s(16).upcase}"
  end
end

width = 384
height = 272
scale = 2
speed = 1

set(title: "Ruby64", width: width * scale, height: height * scale)

palette = [
  "#000000", "#FFFFFF", "#924A40", "#84C5CC",
  "#9351B6", "#72B14B", "#483AAA", "#D5DF7C",
  "#675200", "#C33D00", "#C18178", "#606060",
  "#8A8A8A", "#B3EC91", "#867ADE", "#B3B3B3"
].map { |c| Color.new(c) }

def parse_key(event)
  { "down" => :cursor_v,
    "right" => :cursor_h,
    "backspace" => :delete,
    "left option" => :cbm,
    "\\" => :"@",
    "left shift" => :lshift,
    "right shift" => :rshift }[event.key] || event.key.to_sym
end

on :key_down do |event|
  computer.keyboard.press(parse_key(event))
end

on :key_up do |event|
  computer.keyboard.release(parse_key(event))
end

update do
  ((width * height / 8) * speed).to_i.times { computer.cycle! }

  (0...height).each do |row|
    (0...width).each do |col|
      c = computer.vic.display[((row + 20) * computer.vic.width) + (col + 96)]
      x = col * scale
      y = row * scale
      Pixel.draw(x:, y:, size: scale, color: palette[c])
    end
  end
end

begin
  show
ensure
  puts computer.cpu.inspect
end
