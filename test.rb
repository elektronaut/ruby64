$:.unshift(File.join(File.dirname(__FILE__), "lib"))

require "c64"
cpu = C64::CPU.new(nil, debug: true)

cpu.step! while true

puts "Cycles: #{cpu.cycles}, instructions: #{cpu.instructions}"
