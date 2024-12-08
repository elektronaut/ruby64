# frozen_string_literal: true

require "spec_helper"

describe Ruby64::CIA do
  subject(:cia) { described_class.new(start: 0xdc00) }

  let(:boot_time) { Time.local(2024, 9, 1, 23, 2, 11) }
  let(:current_time) { Time.local(2024, 9, 2, 10, 59, 44) }

  before do
    Timecop.freeze(boot_time)
    cia
    Timecop.freeze(current_time)
  end

  after { Timecop.return }

  it "has a default value for data dir A" do
    expect(cia[0xdc02]).to eq(0xff)
  end

  it "has a default value for data dir B" do
    expect(cia[0xdc03]).to eq(0x00)
  end

  it "repeats every 16 bytes" do
    expect(cia[0xdc12]).to eq(0xff)
  end

  describe "reading the ToD clock" do
    specify { expect(cia[0xdc0b]).to eq(0x11) }
    specify { expect(cia[0xdc0a]).to eq(0x57) }
    specify { expect(cia[0xdc09]).to eq(0x33) }
    specify { expect(cia[0xdc08]).to eq(0x00) }

    it "latches the timer when hours are read" do
      cia.peek(0xdc0b)
      Timecop.travel(15 * 60)
      expect(cia[0xdc0a]).to eq(0x57)
    end

    it "clears the latch when tenths are read" do
      cia.peek(0xdc0b)
      Timecop.travel(15 * 60)
      cia.peek(0xdc08)
      expect(cia[0xdc0a]).to eq(0x12)
    end

    it "sets the AM/PM bit" do
      Timecop.travel(12 * 3600)
      expect(cia[0xdc0b]).to eq(0x11 + 0b10000000)
    end
  end

  describe "setting the clock" do
    it "sets the hours" do
      cia.poke(0xdc0b, 0x11 + 0b10000000)
      expect(cia[0xdc0b]).to eq(0x11 + 0b10000000)
    end

    it "sets the minutes" do
      cia.poke(0xdc0a, 0x24)
      expect(cia[0xdc0a]).to eq(0x24)
    end

    it "sets the seconds" do
      cia.poke(0xdc09, 0x31)
      expect(cia[0xdc09]).to eq(0x31)
    end

    it "sets the tenths" do
      cia.poke(0xdc08, 0x09)
      expect(cia[0xdc08]).to eq(0x09)
    end

    it "does not affect the other registers" do
      cia.poke(0xdc0a, 0x24)
      expect(cia[0xdc0b]).to eq(0x11)
    end

    it "latches the timer when hours are set" do
      cia.poke(0xdc0b, 0x11)
      Timecop.travel(15 * 60)
      expect(cia[0xdc0b]).to eq(0x11)
    end

    it "clears the latch when tenths are read" do
      cia.poke(0xdc0b, 0x11)
      Timecop.travel(15 * 60)
      cia.peek(0xdc08)
      expect(cia[0xdc0a]).to eq(0x12)
    end
  end

  describe "interrupt control register" do
    before { cia.interrupt_status.timer_a = true }

    specify { expect(cia[0xdc0d]).to eq(0x01) }

    it "is cleared after reading" do
      cia.peek(0xdc0d)
      expect(cia[0xdc0d]).to eq(0x00)
    end
  end

  describe "timer A" do
    before do
      cia.interrupt_control.timer_a = true
      cia.control_a.start = true
      cia.timer_a = 0xff
      cia.timer_a_latch = 0x43
      cia.cycle!
    end

    specify { expect(cia.timer_a).to eq(0xfe) }
    specify { expect(cia.interrupt_status.timer_a?).to be(false) }
    specify { expect(cia.interrupted?).to be(false) }

    context "when reaching zero" do
      before { 254.times { cia.cycle! } }

      specify { expect(cia.timer_a).to eq(0x43) }
      specify { expect(cia.interrupt_status.timer_a?).to be(true) }
      specify { expect(cia.interrupted?).to be(true) }
      specify { expect(cia.control_a.start?).to be(true) }
    end

    describe "setting the latch" do
      before do
        cia.poke(0xdc04, 0xcd)
        cia.poke(0xdc05, 0xab)
      end

      specify { expect(cia.timer_a_latch).to eq(0xabcd) }
    end

    context "when in one-shot mode" do
      before do
        cia.control_a.run_mode = true
        254.times { cia.cycle! }
      end

      specify { expect(cia.control_a.start?).to be(false) }
    end

    context "when disabled" do
      before { cia.control_a.start = false }

      it "is not decremented" do
        cia.timer_a = 0xffff
        cia.cycle!
        expect(cia.timer_a).to eq(0xffff)
      end
    end
  end

  describe "timer B" do
    before do
      cia.interrupt_control.timer_b = true
      cia.control_b.start = true
      cia.timer_b = 0xff
      cia.timer_b_latch = 0x43
      cia.cycle!
    end

    specify { expect(cia.timer_b).to eq(0xfe) }
    specify { expect(cia.interrupt_status.timer_b?).to be(false) }
    specify { expect(cia.interrupted?).to be(false) }

    context "when reaching zero" do
      before { 254.times { cia.cycle! } }

      specify { expect(cia.timer_b).to eq(0x43) }
      specify { expect(cia.interrupt_status.timer_b?).to be(true) }
      specify { expect(cia.interrupted?).to be(true) }
      specify { expect(cia.control_b.start?).to be(true) }
    end

    describe "setting the latch" do
      before do
        cia.poke(0xdc06, 0x78)
        cia.poke(0xdc07, 0x56)
      end

      specify { expect(cia.timer_b_latch).to eq(0x5678) }
    end

    context "when in one-shot mode" do
      before do
        cia.control_b.run_mode = true
        254.times { cia.cycle! }
      end

      specify { expect(cia.control_b.start?).to be(false) }
    end

    context "when disabled" do
      before { cia.control_b.start = false }

      it "is not decremented" do
        cia.timer_b = 0xffff
        cia.cycle!
        expect(cia.timer_b).to eq(0xffff)
      end
    end
  end
end
