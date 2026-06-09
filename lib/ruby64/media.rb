# frozen_string_literal: true

module Ruby64
  module Media
    def self.attach(computer, path)
      if File.directory?(path)
        computer.mount(Storage::HostDirectory.new(path))
        "Mounted #{path} as device 8"
      else
        attach_prg(computer, path)
      end
    end

    def self.attach_prg(computer, path)
      data = File.binread(path).bytes
      computer.on_init { computer.load_prg(data) }
      "Loading #{path}"
    end
  end
end
