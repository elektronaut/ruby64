#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "lib"))

require "c64"
require "benchmark/ips"
cpu = C64::CPU.new

Benchmark.ips do |x|
  x.config(time: 10, warmup: 2)
  x.report("Simple addition") { 1 + 2 }
  x.report("CPU cycle") { cpu.cycle! }
end

puts "Cycles: #{cpu.cycles}, instructions: #{cpu.instructions}"
