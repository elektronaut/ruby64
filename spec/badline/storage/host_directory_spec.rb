# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

describe Badline::Storage::HostDirectory do
  subject(:storage) { described_class.new(dir) }

  let(:dir) { Dir.mktmpdir }

  before do
    File.binwrite(File.join(dir, "HELLO.PRG"), [0x01, 0x08, 0x60].pack("C*"))
    File.binwrite(File.join(dir, "intro.prg"), [0x00, 0xc0, 0xaa].pack("C*"))
    File.binwrite(File.join(dir, "notes.txt"), "not a program")
    File.binwrite(File.join(dir, "zz-game.p00"),
                  "C64File\x00LONG NAME#{"\x00" * 9}".b + [0x00, 0x20, 0x77].pack("C*"))
    File.binwrite(File.join(dir, "zz-fake.p00"), "not a container")
  end

  after { FileUtils.remove_entry(dir) }

  describe "#read_file" do
    it "reads a file as bytes" do
      expect(storage.read_file("INTRO")).to eq([0x00, 0xc0, 0xaa])
    end

    it "matches names case-insensitively" do
      expect(storage.read_file("hello")).to eq([0x01, 0x08, 0x60])
    end

    it "returns the first file for a bare wildcard" do
      expect(storage.read_file("*")).to eq([0x01, 0x08, 0x60])
    end

    it "matches a name with a trailing wildcard" do
      expect(storage.read_file("IN*")).to eq([0x00, 0xc0, 0xaa])
    end

    it "matches ? as a single character" do
      expect(storage.read_file("HEL?O")).to eq([0x01, 0x08, 0x60])
    end

    it "returns nil for an unknown name" do
      expect(storage.read_file("MISSING")).to be_nil
    end

    it "ignores files without a .prg extension" do
      expect(storage.read_file("NOTES")).to be_nil
    end

    it "serves a .p00 by its embedded name, header stripped" do
      expect(storage.read_file("long name")).to eq([0x00, 0x20, 0x77])
    end

    it "ignores .p00 files without the magic" do
      expect(storage.read_file("zz-fake")).to be_nil
    end
  end

  describe "#write_file" do
    before { storage.write_file("NEW GAME", [0x00, 0xc0, 0x42]) }

    it "writes a .prg file with a lowercased name" do
      expect(File.binread(File.join(dir, "new game.prg")).bytes).to eq([0x00, 0xc0, 0x42])
    end

    it "serves the written file back" do
      expect(storage.read_file("NEW GAME")).to eq([0x00, 0xc0, 0x42])
    end

    it "overwrites an existing file" do
      storage.write_file("INTRO", [0x00, 0x10, 0x99])
      expect(storage.read_file("INTRO")).to eq([0x00, 0x10, 0x99])
    end

    it "keeps path separators out of the host filename" do
      storage.write_file("A/B", [0x01])
      expect(File.binread(File.join(dir, "a_b.prg")).bytes).to eq([0x01])
    end
  end
end
