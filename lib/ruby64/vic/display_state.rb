# frozen_string_literal: true

module Ruby64
  class VIC < Cycleable
    class DisplayState
      FIRST_LINE = 0x30 # 48: bad lines and the DEN-at-$30 latch begin here
      LAST_LINE  = 0xf7 # 247
      COLUMNS_PER_ROW = 40

      attr_reader :vc_base, :rc

      def initialize(registers)
        @registers = registers
        @vc_base = 0
        @rc = 0
        @display = false
        @bad_lines_enabled = false
        @bad_line = false
      end

      def display? = @display
      def idle? = !@display
      def bad_line? = @bad_line

      def new_frame
        @vc_base = 0
        @bad_lines_enabled = false
      end

      def new_line
        @bad_line = false
      end

      def cycle(rasterline, column)
        @bad_lines_enabled = true if rasterline == FIRST_LINE && @registers.display_enabled?

        load_vc(rasterline) if column == 14
        trigger_bad_line(rasterline) if column.between?(12, 54)
        check_row_counter if column == 58
      end

      private

      def load_vc(rasterline)
        return unless bad_line_condition?(rasterline)

        @bad_line = true
        @display = true
        @rc = 0
      end

      def trigger_bad_line(rasterline)
        return if @bad_line
        return unless bad_line_condition?(rasterline)

        @bad_line = true
        @display = true
      end

      def bad_line_condition?(rasterline)
        @bad_lines_enabled &&
          rasterline.between?(FIRST_LINE, LAST_LINE) &&
          (rasterline & 0b111) == @registers.yscroll
      end

      def check_row_counter
        return unless @display

        if @rc == 7
          @display = false
          @vc_base = (@vc_base + COLUMNS_PER_ROW) & 0x3ff
        else
          @rc = (@rc + 1) & 0b111
        end
      end
    end
  end
end
