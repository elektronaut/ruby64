# frozen_string_literal: true

require "forwardable"

module Ruby64
  class Computer
    extend Forwardable

    attr_reader :address_bus, :cpu, :cycles

    def_delegators :address_bus, :vic, :cia1, :cia2, :sid

    def initialize(debug: false)
      @address_bus = AddressBus.new
      @cpu = CPU.new(@address_bus, debug:)
      @cycles = 0
    end

    def cycle!
      vic.cycle!
      cia1.cycle!
      cia2.cycle!
      cpu.irq = true if cia1.interrupted?
      cpu.nmi = true if cia2.interrupted?
      cpu.cycle!
      @cycles += 1
    end
  end
end
