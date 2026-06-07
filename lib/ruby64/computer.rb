# frozen_string_literal: true

require "forwardable"

module Ruby64
  class Computer
    include IntegerHelper
    extend Forwardable

    attr_reader :address_bus, :cpu, :cycles

    def_delegators :address_bus, :vic, :cia1, :cia2, :sid, :ram, :keyboard

    def initialize(debug: false)
      @address_bus = AddressBus.new
      @cpu = CPU.new(@address_bus, debug:)
      @vic = @address_bus.vic
      @cia1 = @address_bus.cia1
      @cia2 = @address_bus.cia2
      @cycles = 0
      @nmi_asserted = false
      @init_handlers = []
    end

    def cycle!
      handle_init

      @vic.cycle!
      @cia1.cycle!
      @cia2.cycle!

      @cpu.irq = true if @cia1.interrupted? || @vic.interrupted?

      @cpu.nmi = true if @cia2.interrupted? && !@nmi_asserted
      @nmi_asserted = @cia2.interrupted?

      @cpu.cycle! if @cpu.pending_write? || !@vic.ba_low?

      @cycles += 1
    end

    def load_prg(data)
      uint16(data[0], data[1]).tap do |load_addr|
        ram.write(load_addr, data[2..])
      end
    end

    def on_init(&block)
      if booting?
        @init_handlers << block
      else
        block.call
      end
    end

    private

    def booting?
      @cycles < init_threshold
    end

    def handle_init
      return unless cycles == init_threshold

      @init_handlers.each(&:call)
    end

    def init_threshold
      2_500_000
    end
  end
end
