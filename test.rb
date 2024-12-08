#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require "ruby64"
computer = Ruby64::Computer.new(debug: true)

begin
  loop { computer.cycle! }
ensure
  puts "Cycles: #{computer.cycles}, instructions: #{computer.cpu.instructions}"
end
