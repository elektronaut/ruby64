# frozen_string_literal: true

require "badline/vic/sprite"

module Badline
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
        @hits = Array.new(width, 0)
        @win_color = Array.new(width, 0)
        @win_priority = Array.new(width, false)
      end

      def [](index) = @sprites[index]

      def start_line(line)
        @sprites.each { |sprite| sprite.start_line(line) }
      end

      def active? = @sprites.any?(&:displaying?)

      # Merge each displaying sprite's line into the scratch buffers, then
      # apply the winners over the background in a single pass over the
      # touched span.
      def composite(colors, mask)
        @sprite_clash = 0
        @data_clash = 0
        lo = @width
        hi = 0

        @sprites.each do |sprite|
          next unless sprite.displaying?

          seg_lo, seg_hi = merge(sprite, mask)
          lo = seg_lo if seg_lo < lo
          hi = seg_hi if seg_hi > hi
        end

        apply(colors, mask, lo, hi)
        register_collisions
      end

      private

      # Write one sprite's pixels into the scratch line. The first sprite to
      # claim a pixel wins (lowest index has priority); later hits only
      # accumulate collision bits.
      def merge(sprite, mask)
        left = sprite.leftmost
        pixels = sprite.line_pixels
        last = sprite.pixel_width
        bit = 1 << sprite.index
        priority = sprite.priority?

        i = 0
        while i < last
          color = pixels[i]
          if color
            x = left + i
            x -= @width if x >= @width
            merge_pixel(x, color, bit, priority, mask)
          end
          i += 1
        end

        right = left + last
        right > @width ? [0, @width] : [left, right]
      end

      def merge_pixel(pos, color, bit, priority, mask)
        bits = @hits[pos]
        if bits.zero?
          @win_color[pos] = color
          @win_priority[pos] = priority
        else
          @sprite_clash |= bits | bit
        end
        @hits[pos] = bits | bit
        @data_clash |= bit if mask[pos]
      end

      def apply(colors, mask, from, upto)
        pos = from
        while pos < upto
          if @hits[pos].nonzero?
            colors[pos] = @win_color[pos] unless @win_priority[pos] && mask[pos]
            @hits[pos] = 0
          end
          pos += 1
        end
      end

      def register_collisions
        if @sprite_clash.nonzero? && @registers.collide!(0x1e, @sprite_clash)
          @registers.latch_irq!(SPRITE_COLLISION_IRQ)
        end
        return if @data_clash.zero?
        return unless @registers.collide!(0x1f, @data_clash)

        @registers.latch_irq!(DATA_COLLISION_IRQ)
      end
    end
  end
end
