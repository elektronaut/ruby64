# frozen_string_literal: true

module Ruby64
  # CIA (Complex Interface Adapter) chip
  class CIA
    include Addressable

    attr_accessor :timer_a, :timer_b, :timer_a_latch, :timer_b_latch
    attr_reader :start, :control_a, :control_b,
                :interrupt_status, :interrupt_control, :peripheral

    def initialize(start: 0, peripheral: nil)
      addressable_at(start, length: 2**8)

      @peripheral = peripheral
      @data_port_a = 0xff
      @data_port_b = 0xff
      @data_dir_a = 0xff
      @data_dir_b = 0x0
      @timer_a = @timer_b = 0x0
      @timer_a_latch = @timer_b_latch = 0x0
      @timer_a_reached_zero = @timer_b_reached_zero = false
      @pb6_toggle = @pb7_toggle = true
      @serial_data = 0x0
      @tod = TimeOfDay.new
      @interrupt_control = Status.new([:timer_a, :timer_b, :alarm, :serial,
                                       :flag, 0, 0, 0])
      @interrupt_status = Status.new([:timer_a, :timer_b, :alarm, :serial,
                                      :flag, 0, 0, :interrupt])
      @control_a = Status.new(%i[start output out_mode run_mode load
                                 in_mode serial_mode clock_frequency])
      @control_b = Status.new(%i[start output out_mode run_mode load
                                 count_a in_mode alarm])
    end

    def interrupt!
      interrupt_status.interrupt = true
    end

    def interrupted?
      interrupt_status.interrupt?
    end

    def cycle!
      update_timers
      @tod.cycle! { trigger_alarm }
    end

    def read_port_a
      pulldown = peripheral ? peripheral.read_a(@data_port_a, @data_port_b) : 0xff
      driven_lines(@data_port_a, @data_dir_a) & pulldown
    end

    def read_port_b
      pulldown = peripheral ? peripheral.read_b(@data_port_a, @data_port_b) : 0xff
      value = driven_lines(@data_port_b, @data_dir_b) & pulldown
      apply_timer_output(value)
    end

    def peek(addr)
      case index(addr) & 0x0f
      when 0x00 then read_port_a
      when 0x01 then read_port_b
      when 0x02 then @data_dir_a
      when 0x03 then @data_dir_b
      when 0x04 then low_byte(timer_a)
      when 0x05 then high_byte(timer_a)
      when 0x06 then low_byte(timer_b)
      when 0x07 then high_byte(timer_b)
      when 0x08 then @tod.tenths
      when 0x09 then @tod.seconds
      when 0x0a then @tod.minutes
      when 0x0b then @tod.hours
      when 0x0c then @serial_data
      when 0x0d
        value = interrupt_status.value
        interrupt_status.value = 0x0 # Burn after reading
        value
      when 0x0e then control_a.value
      when 0x0f then control_b.value
      end
    end

    def poke(addr, value)
      case index(addr) & 0x0f
      when 0x00 then @data_port_a = value
      when 0x01 then @data_port_b = value
      when 0x02 then @data_dir_a = value
      when 0x03 then @data_dir_b = value
      when 0x04 then @timer_a_latch = uint16(value, high_byte(@timer_a_latch))
      when 0x05 then write_timer_a_high(value)
      when 0x06 then @timer_b_latch = uint16(value, high_byte(@timer_b_latch))
      when 0x07 then write_timer_b_high(value)
      when 0x08 then @tod.write(:tenths, value, alarm: control_b.alarm?)
      when 0x09 then @tod.write(:seconds, value, alarm: control_b.alarm?)
      when 0x0a then @tod.write(:minutes, value, alarm: control_b.alarm?)
      when 0x0b then @tod.write_hours(value, alarm: control_b.alarm?)
      when 0x0c
        # TODO: Serial
      when 0x0d then write_interrupt_control(value)
      when 0x0e then write_control_a(value)
      when 0x0f then write_control_b(value)
      end
    end

    private

    def driven_lines(register, direction)
      # Output bits are driven from the data register; input bits float high.
      # External peripherals can still pull any line low (wired-AND).
      (register & direction) | (~direction & 0xff)
    end

    def apply_timer_output(value)
      value = with_bit(value, 6, timer_a_output?) if control_a.output?
      value = with_bit(value, 7, timer_b_output?) if control_b.output?
      value
    end

    def timer_a_output?
      control_a.out_mode? ? @pb6_toggle : @timer_a_reached_zero
    end

    def timer_b_output?
      control_b.out_mode? ? @pb7_toggle : @timer_b_reached_zero
    end

    def with_bit(value, bit, set)
      set ? value | (1 << bit) : value & ~(1 << bit)
    end

    def trigger_alarm
      interrupt_status.alarm = true
      interrupt! if interrupt_control.alarm?
    end

    def update_timers
      @timer_a_reached_zero = false
      @timer_b_reached_zero = false
      update_timer_a
      update_timer_b
    end

    def update_timer_a
      return unless control_a.start?

      @timer_a -= 1
      return if timer_a.positive?

      @timer_a_reached_zero = true
      @pb6_toggle = !@pb6_toggle
      interrupt_status.timer_a = true
      interrupt! if interrupt_control.timer_a?

      # Stop timer if one-short mode
      control_a.start = false if control_a.run_mode?

      @timer_a = timer_a_latch
    end

    def update_timer_b
      return unless control_b.start?

      if control_b.count_a?
        @timer_b -= 1 if @timer_a_reached_zero
      else
        @timer_b -= 1 # Count CPU cycles
      end
      return if timer_b.positive?

      @timer_b_reached_zero = true
      @pb7_toggle = !@pb7_toggle
      interrupt_status.timer_b = true
      interrupt! if interrupt_control.timer_b?

      # Stop timer if one-short mode
      control_b.start = false if control_b.run_mode?

      @timer_b = timer_b_latch
    end

    def write_timer_a_high(value)
      @timer_a_latch = uint16(low_byte(@timer_a_latch), value)
      @timer_a = @timer_a_latch unless control_a.start?
    end

    def write_timer_b_high(value)
      @timer_b_latch = uint16(low_byte(@timer_b_latch), value)
      @timer_b = @timer_b_latch unless control_b.start?
    end

    def write_control_a(value)
      # Starting the timer sets the toggle output high.
      @pb6_toggle = true if value.anybits?(0x01)
      control_a.value = value & ~0x10
      @timer_a = timer_a_latch if value.anybits?(0x10)
    end

    def write_control_b(value)
      @pb7_toggle = true if value.anybits?(0x01)
      control_b.value = value & ~0x10
      @timer_b = timer_b_latch if value.anybits?(0x10)
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
  end
end
