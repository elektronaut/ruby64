# frozen_string_literal: true

module Ruby64
  module Media
    AUTOSTART = %(lO"*",8,1\rrun\r)

    def self.attach(computer, path, autostart: true)
      if File.directory?(path)
        computer.mount(Storage::HostDirectory.new(path))
        "Mounted #{path} as device 8"
      elsif path.downcase.end_with?(".d64")
        attach_d64(computer, path, autostart:)
      else
        attach_prg(computer, path)
      end
    end

    def self.attach_d64(computer, path, autostart:)
      computer.mount(Storage::D64Image.new(path))
      computer.type_text(AUTOSTART) if autostart
      "Mounted #{path} as device 8"
    end

    def self.attach_prg(computer, path)
      data = File.binread(path).bytes
      computer.on_init { computer.load_prg(data) }
      "Loading #{path}"
    end
  end
end
