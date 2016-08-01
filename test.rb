#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require "ruby64"
cpu = Ruby64::CPU.new(nil, debug: true)

begin
  loop { cpu.step! }
ensure
  puts "Cycles: #{cpu.cycles}, instructions: #{cpu.instructions}"
end
