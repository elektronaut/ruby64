# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ruby64::Computer do
  let(:computer) { described_class.new }

  describe "VIC-II bad line cycle stealing" do
    before do
      computer.vic.poke(0xd011, 0x1b) # DEN=1, RSEL=1, YSCROLL=3
      computer.vic.poke(0xd016, 0x08) # Text mode
    end

    it "allows CPU to execute during non-bad line cycles" do
      initial_cpu_cycles = computer.cpu.cycles

      ((50 * 63) + 20).times { computer.cycle! }

      expect(computer.cpu.cycles).to be > initial_cpu_cycles
    end

    it "prevents CPU execution during VIC DMA cycles" do
      (51 * 63).times { computer.cycle! }
      initial_cpu_cycles = computer.cpu.cycles

      20.times { computer.cycle! }

      # Some cycles were stolen
      expect(computer.cpu.cycles - initial_cpu_cycles).to be < 20
    end
  end

  describe "#load_prg" do
    subject(:load_addr) { computer.load_prg(prg_data) }

    let(:prg_data) { [0x01, 0x08, 0x1d, 0x08, 0x0a, 0x00, 0x99, 0x20] }

    specify { expect(load_addr).to eq(0x0801) }
    specify { expect(computer.ram.read(load_addr, 6)).to eq(prg_data[2..]) }
  end
end
