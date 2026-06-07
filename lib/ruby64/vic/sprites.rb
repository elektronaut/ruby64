# frozen_string_literal: true

require "ruby64/vic/sprite"

module Ruby64
  class VIC < Cycleable
    class Sprites
      # $D019 latch bits raised by the collision registers.
      SPRITE_COLLISION_IRQ = 0x04 # IMMC, mirrors $D01E
      DATA_COLLISION_IRQ   = 0x02 # IMBC, mirrors $D01F

      def initialize(registers, bank, width)
        @registers = registers
        @bank = bank
        @width = width
        @sprites = Array.new(8) { |i| Sprite.new(i, registers, bank, width) }
      end

      def [](index) = @sprites[index]

      def start_line(line)
        @sprites.each { |sprite| sprite.start_line(line) }
      end

      def active? = @sprites.any?(&:displaying?)

      def composite(colors, mask)
        active = @sprites.select(&:displaying?)
        return if active.empty?

        lo, hi = span(active)
        raster_x = lo
        while raster_x < hi
          composite_pixel(active, colors, mask, raster_x)
          raster_x += 1
        end
      end

      private

      def span(active)
        lo = @width
        hi = 0
        active.each do |sprite|
          left = sprite.leftmost
          right = left + sprite.pixel_width
          return [0, @width] if right > @width

          lo = left if left < lo
          hi = right if right > hi
        end
        [lo, hi]
      end

      def composite_pixel(active, colors, mask, raster_x)
        winner = nil
        winner_color = nil
        hits = 0
        foreground = mask[raster_x]

        active.each do |sprite|
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
