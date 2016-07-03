#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "lib"))

require "c64"
cpu = C64::CPU.new(nil, debug: true)

begin
  cpu.step! while true
ensure
  puts "Cycles: #{cpu.cycles}, instructions: #{cpu.instructions}"
end
