# frozen_string_literal: true

require "forwardable"

module Ruby64
  class Computer
    include IntegerHelper
    extend Forwardable

    attr_reader :address_bus, :cpu, :cycles

    def_delegators :address_bus, :vic, :cia1, :cia2, :sid, :ram, :keyboard, :joystick2

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

    INIT_THRESHOLD = 2_500_000

    def cycle!
      handle_init if @cycles == INIT_THRESHOLD

      @vic.cycle!
      @cia1.cycle!
      @cia2.cycle!

      @cpu.irq = @cia1.interrupted? || @vic.interrupted?

      nmi = @cia2.interrupted?
      @cpu.nmi = true if nmi && !@nmi_asserted
      @nmi_asserted = nmi

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
      @init_handlers.each(&:call)
    end

    def init_threshold
      INIT_THRESHOLD
    end
  end
end
