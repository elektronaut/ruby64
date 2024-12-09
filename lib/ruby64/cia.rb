# frozen_string_literal: true

module Ruby64
  # CIA (Complex Interface Adapter) chip
  class CIA < Memory
    INTERRUPT_CONTROL = %i[timer_a timer_b tod serial flag_line].freeze
    INTERRUPT_STATUS = INTERRUPT_CONTROL + [0, 0, :interrupt].freeze
    CONTROL_FLAGS = %i[start output output_mode run_mode force_load].freeze
    CONTROL_A_FLAGS = CONTROL_FLAGS + %i[input_mode serial_mode clock_frequency]
    CONTROL_B_FLAGS = CONTROL_FLAGS + %i[count_a input_mode alarm]

    attr_accessor :timer_a, :timer_b, :timer_a_latch, :timer_b_latch
    attr_reader :start, :control_a, :control_b,
                :interrupt_status, :interrupt_control

    def initialize(start: 0)
      super(start: start, length: 2**8)

      @data_dir_a = 0xff
      @data_dir_b = 0x0
      @timer_a = @timer_b = 0x0
      @timer_a_latch = @timer_b_latch = 0x0
      @serial_data = 0x0
      @clock_start = Time.now
      @interrupt_control = Status.new(INTERRUPT_CONTROL + [0, 0, 0])
      @interrupt_status = Status.new(INTERRUPT_STATUS)
      @control_a = Status.new(CONTROL_A_FLAGS)
      @control_b = Status.new(CONTROL_B_FLAGS)
    end

    def interrupt!
      @interrupted = true
      interrupt_status.interrupt = true
    end

    def interrupted?
      @interrupted
    end

    def cycle!
      @interrupted = false
      update_timers
      # TODO: Check alarm
    end

    def peek(addr)
      case index(addr) & 0x0f
      when 0x00, 0x01
        # TODO: Data Port A, B
        0
      when 0x02 then @data_dir_a
      when 0x03 then @data_dir_b
      when 0x04 then low_byte(timer_a)
      when 0x05 then high_byte(timer_a)
      when 0x06 then low_byte(timer_b)
      when 0x07 then high_byte(timer_b)
      when 0x08 then tod_tenths
      when 0x09 then tod_seconds
      when 0x0a then tod_minutes
      when 0x0b then tod_hours(latch: true)
      when 0x0c then @serial_data
      when 0x0d
        value = interrupt_status.value
        interrupt_status.value = 0x0 # Burn after reading
        value
      when 0x0e then control_a.value
      when 0x0f then control_b.value
      end
    end
    alias [] peek

    def poke(addr, value)
      case index(addr) & 0x0f
      when 0x00, 0x01
        # TODO: Data Port A, B
      when 0x02 then @data_dir_a = value
      when 0x03 then @data_dir_b = value
      when 0x04
        @timer_a_latch = uint16(value, high_byte(@timer_a_latch))
      when 0x05
        @timer_a_latch = uint16(low_byte(@timer_a_latch), value)
      when 0x06
        @timer_b_latch = uint16(value, high_byte(@timer_b_latch))
      when 0x07
        @timer_b_latch = uint16(low_byte(@timer_b_latch), value)
      when 0x08 then write_tod_or_alarm({ tenths: bcd_to_i(value) })
      when 0x09 then write_tod_or_alarm({ seconds: bcd_to_i(value) })
      when 0x0a then write_tod_or_alarm({ minutes: bcd_to_i(value) })
      when 0x0b
        write_tod_or_alarm({ hours: parse_hours(value) }, latch: true)
      when 0x0c
        # TODO: Serial
      when 0x0d then write_interrupt_control(value)
      when 0x0e then control_a.value = value
      when 0x0f then control_b.value = value
      end
    end
    alias []= poke

    def tod_tenths
      @latched_time = nil
      (current_time * 10).to_i % 10
    end

    def tod_seconds
      bcd(current_time.to_i % 60)
    end

    def tod_minutes
      bcd((current_time / 60).to_i % 60)
    end

    def tod_hours(latch: false)
      # Pause the clock to prevent rollover while reading multiple
      # time registers.
      @latched_time ||= Time.now if latch
      hours = (current_time / 3600).to_i % 24
      bcd(hours % 12) | (hours >= 12 ? 0x80 : 0)
    end

    private

    def current_time
      (@latched_time || Time.now) - @clock_start
    end

    def parse_hours(value)
      # 12 hour clock BCD + bit 7 AM/PM to 24 hour binary
      bcd_to_i(value & 0b01111111) + (value.nobits?(0b10000000) ? 0 : 12)
    end

    def update_timers
      @timer_a_reached_zero = false
      update_timer_a
      update_timer_b
    end

    def update_timer_a
      return unless control_a.start?

      @timer_a -= 1
      return if timer_a.positive?

      @timer_a_reached_zero = true
      interrupt_status.timer_a = true
      interrupt! if interrupt_control.timer_a?

      # Stop timer if one-short mode
      control_a.start = false if control_a.run_mode?

      @timer_a = timer_a_latch
    end

    def update_timer_b
      return unless control_b.start?

      if control_b.count_a?
        @timer_b -= i if @timer_a_reached_zero
      else
        @timer_b -= 1 # Count CPU cycles
      end
      return if timer_b.positive?

      interrupt_status.timer_b = true
      interrupt! if interrupt_control.timer_b?

      # Stop timer if one-short mode
      control_b.start = false if control_b.run_mode?

      @timer_b = timer_b_latch
    end

    def write_interrupt_control(value)
      if value.nobits?(0x80)
        # Clear interrupts based on bits 0-4
        interrupt_control.value &= ~(value & 0x1f)
      else
        # Set interrupts based on bits 0-4
        interrupt_control.value |= (value & 0x1f)
      end
    end

    def write_tod_or_alarm(adjustment = {}, latch: false)
      return if control_b.alarm? # TODO: Set alarm

      @latched_time ||= Time.now if latch

      t = { hours: (current_time / 3600).to_i % 24,
            minutes: (current_time / 60).to_i % 60,
            seconds: current_time.to_i % 60,
            tenths: (current_time * 10).to_i % 10 }.merge(adjustment)

      offset = (t[:hours] * 3600) + (t[:minutes] * 60) +
               t[:seconds] + (t[:tenths] * 0.1)

      @clock_start = (@latched_time || Time.now) - offset
    end
  end
end
