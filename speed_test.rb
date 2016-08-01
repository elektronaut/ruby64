#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require "ruby64"
require "benchmark/ips"
cpu = Ruby64::CPU.new

Benchmark.ips do |x|
  x.config(time: 10, warmup: 2)
  x.report("CPU cycle") { cpu.cycle! }
end

puts "Cycles: #{cpu.cycles}, instructions: #{cpu.instructions}"
