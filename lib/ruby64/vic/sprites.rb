# frozen_string_literal: true

require "ruby64/vic/sprite"

module Ruby64
  class VIC < Cycleable
    class Sprites
      # $D019 latch bits raised by the collision registers.
      SPRITE_COLLISION_IRQ = 0x04 # IMMC, mirrors $D01E
      DATA_COLLISION_IRQ   = 0x02 # IMBC, mirrors $D01F

      def initialize(registers, bank)
        @registers = registers
        @bank = bank
        @sprites = Array.new(8) { |i| Sprite.new(i, registers, bank) }
      end

      def [](index) = @sprites[index]

      def start_line(line)
        @sprites.each { |sprite| sprite.start_line(line) }
      end

      def active? = @sprites.any?(&:displaying?)

      def composite(colors, mask, x_start, count)
        raster_x = x_start
        last = x_start + count
        while raster_x < last
          composite_pixel(colors, mask, raster_x)
          raster_x += 1
        end
      end

      private

      def composite_pixel(colors, mask, raster_x)
        winner = nil
        winner_color = nil
        hits = 0
        foreground = mask[raster_x]

        @sprites.each do |sprite|
          next unless sprite.displaying?

          color = sprite.pixel(raster_x)
          next if color.nil?

          hits |= (1 << sprite.index)
          if winner.nil?
            winner = sprite
            winner_color = color
          end
        end
        return if hits.zero?

        register_collisions(hits, foreground)
        colors[raster_x] = winner_color unless winner.priority? && foreground
      end

      def register_collisions(hits, foreground)
        multiple = (hits & (hits - 1)).nonzero?
        @registers.latch_irq!(SPRITE_COLLISION_IRQ) if multiple && @registers.collide!(0x1e, hits)
        return unless foreground && @registers.collide!(0x1f, hits)

        @registers.latch_irq!(DATA_COLLISION_IRQ)
      end
    end
  end
end
