# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

describe Ruby64::Media do
  let(:computer) { Ruby64::Computer.new }
  let(:dir) { Dir.mktmpdir }

  after { FileUtils.remove_entry(dir) }

  describe ".attach" do
    context "with a directory" do
      it "mounts it as device 8" do
        allow(computer).to receive(:mount)
        described_class.attach(computer, dir)
        expect(computer)
          .to have_received(:mount)
          .with(instance_of(Ruby64::Storage::HostDirectory))
      end

      it "returns a mount message" do
        expect(described_class.attach(computer, dir)).to include("device 8")
      end
    end

    context "with a D64 image" do
      let(:d64_path) do
        File.join(dir, "disk.d64").tap do |path|
          File.binwrite(path, "\x00" * 174_848)
        end
      end

      it "mounts it as device 8" do
        allow(computer).to receive(:mount)
        described_class.attach(computer, d64_path)
        expect(computer)
          .to have_received(:mount)
          .with(instance_of(Ruby64::Storage::D64Image))
      end

      it "types the autostart command" do
        allow(computer).to receive(:type_text)
        described_class.attach(computer, d64_path)
        expect(computer)
          .to have_received(:type_text).with(%(lO"*",8,1\rrun\r))
      end

      it "skips autostart when disabled" do
        allow(computer).to receive(:type_text)
        described_class.attach(computer, d64_path, autostart: false)
        expect(computer).not_to have_received(:type_text)
      end

      it "returns a mount message" do
        expect(described_class.attach(computer, d64_path))
          .to include("device 8")
      end
    end

    context "with a PRG file" do
      let(:prg_path) do
        File.join(dir, "test.prg").tap do |path|
          File.binwrite(path, [0x00, 0x10, 0x99].pack("C*"))
        end
      end

      it "loads the program on init" do
        allow(computer).to receive(:on_init).and_yield
        described_class.attach(computer, prg_path)
        expect(computer.ram.read(0x1000, 1)).to eq([0x99])
      end

      it "returns a loading message" do
        expect(described_class.attach(computer, prg_path))
          .to include("test.prg")
      end
    end
  end
end
