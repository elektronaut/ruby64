#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require "ruby64"
require "ruby-prof"
computer = Ruby64::Computer.new
profile = RubyProf::Profile.new

iterations = 100_000

puts "Warming up..."

iterations.times { computer.cycle! }

puts "Profiling #{iterations} cycles..."
profile.start
iterations.times { computer.cycle! }
result = profile.stop

puts "Cycles: #{computer.cycles}, instructions: #{computer.cpu.instructions}"

printer = RubyProf::FlatPrinter.new(result)
printer.print($stdout, {})
