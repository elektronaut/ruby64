# frozen_string_literal: true

module Ruby64
  class Status
    attr_accessor :value

    def initialize(flags = [], value: 0x0)
      @value = value
      flags.each_with_index do |name, i|
        next unless name

        mask = 1 << i
        define_singleton_method("#{name}=") do |enabled|
          update(mask, enabled)
        end
        define_singleton_method("#{name}?") do
          !@value.nobits?(mask)
        end
        define_singleton_method(name) do
          @value.nobits?(mask) ? 0 : 1
        end
      end
    end

    private

    def update(mask, enabled)
      @value = if enabled && enabled != 0
                 @value | mask
               else
                 @value & ~mask
               end
    end
  end
end
