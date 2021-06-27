defmodule GrowTent.Sensors.Tsl2951 do
  use Bitwise

  require Logger

  @device_id 0x50
  @default_address 0x29
  @command_bit 0xA0
  @registerenable 0x00
  @registerdeviceid 0x12
  @registerchanzerolow 0x14
  @enablepoweron 0x01
  @enableaen 0x02
  @enableaien 0x10
  @enablenpien 0x80
  @integration_time 100
  @max_counts 36863
  @lux_df 408.0
  @lux_coefb 1.64
  @lux_coefc 0.59
  @lux_coefd 0.86

  def start_link(bus_name, address \\ @default_address) do
    I2cServer.start_link(bus_name: bus_name, bus_address: address)
  end

  def online?(lux) do
    {:ok, <<dev_id::integer>>} = I2cServer.write_read(lux, @command_bit ||| @registerdeviceid, 1)
    dev_id == @device_id
  end

  def enable(lux) do
    I2cServer.write(
      lux,
      @command_bit ||| @registerenable,
      @enablepoweron ||| @enableaen ||| @enableaien ||| @enablenpien
    )
  end

  def raw_luminosity(lux) do
    {:ok,
     <<chan_zero_low::integer, chan_zero_high::integer, chan_one_low::integer,
       chan_one_high::integer>>} =
      I2cServer.write_read(lux, @command_bit ||| @registerchanzerolow, 4)

    <<chan_zero::integer-size(16)>> = <<chan_zero_low, chan_zero_high>>
    <<chan_one::integer-size(16)>> = <<chan_one_low, chan_one_high>>

    {chan_zero, chan_one}
  end

  # TODO currently we are assuming system is using 100ms integration time
  # if this changes these figures will be off.
  # When adding ability to set gain will need to add fucntion to get atime numbers
  def lux(lux) do
    {chan_zero, chan_one} = raw_luminosity(lux)
    atime = 100.0 * @integration_time + 100.0

    if is_integer(chan_zero) and is_integer(chan_one) do
      if chan_zero >= @max_counts or chan_one >= @max_counts do
        _ = Logger.warn("Overflow reading light channels!, Try to reduce the gain of the sensor")
        chan_zero = chan_zero * 0.1
        chan_one = chan_one * 0.1
      end

      # Calculate lux using same equation as Arduino library:
      # https://github.com/adafruit/Adafruit_TSL2591_Library/blob/master/Adafruit_TSL2591.cpp
      again = 1.0
      cpl = atime * again / @lux_df
      # OLD CALCULATION
      # lux1 = (chan_zero - @lux_coefb * chan_one) / cpl
      # lux2 = (@lux_coefc * chan_zero - @lux_coefd * chan_one) / cpl

      # https://github.com/adafruit/Adafruit_TSL2591_Library/blob/master/Adafruit_TSL2591.cpp
      # new calculation
      # lux = (((float)ch0 - (float)ch1)) * (1.0F - ((float)ch1 / (float)ch0)) / cpl;
      (chan_zero - chan_one) * (again - chan_one / chan_zero) / cpl
    else
      0
    end
  end
end
