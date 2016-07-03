#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "lib"))

require "c64"
require "ruby-prof"
cpu = C64::CPU.new

iterations = 100_000

puts "Profiling #{iterations} cycles..."
RubyProf.start
iterations.times { cpu.cycle! }
result = RubyProf.stop

puts "Cycles: #{cpu.cycles}, instructions: #{cpu.instructions}"

printer = RubyProf::GraphPrinter.new(result)
printer.print(STDOUT, {})
