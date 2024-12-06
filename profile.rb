#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require "ruby64"
require "ruby-prof"
cpu = Ruby64::CPU.new
profile = RubyProf::Profile.new

iterations = 100_000

puts "Warming up..."

iterations.times { cpu.cycle! }

puts "Profiling #{iterations} cycles..."
profile.start
iterations.times { cpu.cycle! }
result = profile.stop

puts "Cycles: #{cpu.cycles}, instructions: #{cpu.instructions}"

printer = RubyProf::FlatPrinter.new(result)
printer.print($stdout, {})
