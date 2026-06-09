# frozen_string_literal: true

module Ruby64
  module Traps
    def install_trap(addr, &handler)
      (@traps ||= {})[addr] = handler
    end

    private

    def run_traps
      @traps[@program_counter]&.call if @traps
    end
  end
end
