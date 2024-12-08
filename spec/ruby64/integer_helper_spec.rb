# frozen_string_literal: true

require "spec_helper"

describe Ruby64::IntegerHelper do
  include described_class

  describe ".bcd" do
    specify { expect(bcd(53)).to eq(0x53) }
  end

  describe ".bcd_to_i" do
    specify { expect(bcd_to_i(0x53)).to eq(53) }
  end

  describe ".high_byte" do
    specify { expect(high_byte(1337)).to eq(5) }
  end

  describe ".low_byte" do
    specify { expect(low_byte(1337)).to eq(57) }
  end

  describe ".signed_int8" do
    specify { expect(signed_int8(127)).to eq(127) }
    specify { expect(signed_int8(128)).to eq(-128) }
    specify { expect(signed_int8(255)).to eq(-1) }
  end

  describe ".uint16" do
    specify { expect(uint16(0x39, 0x05)).to eq(0x0539) }
  end
end
