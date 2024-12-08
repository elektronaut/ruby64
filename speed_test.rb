#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require "ruby64"
require "benchmark/ips"
computer = Ruby64::Computer.new

Benchmark.ips do |x|
  x.config(time: 10, warmup: 5)
  x.report("CPU cycle") { computer.cycle! }
end

puts "Cycles: #{computer.cycles}, instructions: #{computer.cpu.instructions}"
