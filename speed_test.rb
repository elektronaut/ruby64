#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require "badline"
require "benchmark/ips"
computer = Badline::Computer.new

Benchmark.ips do |x|
  x.config(time: 10, warmup: 5)
  x.report("CPU cycle") { computer.cycle! }
end

puts "Cycles: #{computer.cycles}, instructions: #{computer.cpu.instructions}"
