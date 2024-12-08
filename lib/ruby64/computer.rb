# frozen_string_literal: true

module Ruby64
  class Computer
    attr_reader :cpu, :cycles, :memory

    def initialize(debug: false)
      @cia1 = CIA.new(start: 0xDC00)
      @cia2 = CIA.new(start: 0xDD00)
      @memory = MemoryMap.new(io: [@cia1, @cia2])
      @cpu = CPU.new(@memory, debug: debug)
      @cycles = 0
    end

    def cycle!
      @cia1.cycle!
      @cia2.cycle!

      @cpu.irq = true if @cia1.interrupted?
      @cpu.nmi = true if @cia2.interrupted?
      @cpu.cycle!
      @cycles += 1
    end
  end
end
