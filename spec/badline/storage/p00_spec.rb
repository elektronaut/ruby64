# frozen_string_literal: true

require "spec_helper"

describe Badline::Storage::P00 do
  let(:header) { "C64File\x00".bytes + "GAME".bytes + ([0] * 12) + [0, 0] }
  let(:file_bytes) { header + [0x01, 0x08, 0x99] }

  describe ".wraps?" do
    it "recognizes the magic" do
      expect(described_class.wraps?(file_bytes)).to be(true)
    end

    it "rejects a bare PRG" do
      expect(described_class.wraps?([0x01, 0x08, 0x99])).to be(false)
    end
  end

  describe ".name" do
    it "returns the embedded filename" do
      expect(described_class.name(file_bytes)).to eq("game")
    end
  end

  describe ".data" do
    it "returns the payload after the header" do
      expect(described_class.data(file_bytes)).to eq([0x01, 0x08, 0x99])
    end
  end
end
