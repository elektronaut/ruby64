# frozen_string_literal: true

require "spec_helper"

describe Ruby64::Status do
  subject(:value) { status.value }

  let(:status) { described_class.new(flags) }
  let(:flags) { [:foo, :bar, nil, :baz, 0] }

  it { is_expected.to eq(0x0) }

  it "defines setter methods" do
    status.foo = true
    status.baz = true
    expect(status.value).to eq(0x09)
  end

  it "defines boolean methods" do
    status.baz = true
    expect(status.baz?).to be(true)
  end

  it "defines accessor methods" do
    status.baz = true
    expect(status.baz).to be(1)
  end

  describe ".bitmask" do
    subject { status.bitmask }

    it { is_expected.to eq(0b00001011) }
  end

  context "when flag is always 1" do
    let(:flags) { [:a, :b, 1, :c, 1, nil, 0] }

    before { status.value = 0x0 }

    it { is_expected.to eq(0b00010100) }

    specify { expect(status.high_mask).to eq(0b00010100) }
  end

  context "when flag is always 0" do
    let(:flags) { [:a, :b, 0, :c, 0, nil, 1] }

    before { status.value = 0xff }

    it { is_expected.to eq(0b11101011) }

    specify { expect(status.low_mask).to eq(0b00010100) }
  end
end
