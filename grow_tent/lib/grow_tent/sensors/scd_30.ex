defmodule GrowTent.Sensors.Scd30 do
  require Logger

  alias GrowTent.Utils.Units

  @default_address 0x61
  @cmd_continuous_measurement <<0x00, 0x10>>
  @cmd_set_measurement_interval <<0x46, 0x00>>
  @cmd_get_data_ready <<0x02, 0x02>>
  @cmd_read_measurement <<0x03, 0x00>>
  @cmd_automatic_self_calibration <<0x53, 0x06>>
  @cmd_set_forced_recalibration_factor <<0x52, 0x04>>
  @cmd_set_temperature_offset <<0x54, 0x03>>
  @cmd_set_altitude_compensation <<0x51, 0x02>>
  @cmd_soft_reset <<0xD3, 0x04>>
  @cmd_stop_readings <<0x01, 0x04>>
  @min_pressure 700
  @max_pressure 1400
  # Custom CRC parameters: {bits, polynomial, init_value, final_xor_value, reflected}
  @crc8_def :cerlc.init({8, 0x31, 0xFF, 0x00, false})

  def start_link(bus_name, address \\ @default_address) do
    _ = Logger.info("[SCD30] Starting on bus #{bus_name} at address #{address}")

    I2cServer.start_link(bus_name: bus_name, bus_address: address)
  end

  # TODO how often should the ambient_pressure be reset for this sensor ??
  def init(scd, ambient_pressure \\ 0) do
    _ = Logger.info("[SCD30] Initializing sensor :: #{inspect(scd)}")

    {:ok, data} = data_reset(scd)
    _ = Logger.info("[SCD30] Resetting sensor data :: #{inspect(data)}")

    # set_ambient_pressure(scd, ambient_pressure)
    :ok
  end

  def measure(scd) do
    {:ok, read_measurement} = I2cServer.write_read(scd, @cmd_read_measurement, 19)
    # {:error, :i2c_nak}

    convert_raw_measurements(read_measurement)
  end

  def transform(measurements) do
    %{temp_c: temp_c, rh: rh} = measurements

    measurements
    |> Map.merge(%{
      temp_f: Units.celcius_to_f(temp_c),
      dew_point_f: Units.celcius_to_f(Units.dew_point(temp_c, rh))
    })
  end

  def set_ambient_pressure(scd, ambient_pressure) do
    <<msb, lsb>> = <<ambient_pressure::integer-size(16)>>
    data = @cmd_continuous_measurement <> <<msb, lsb>>
    crc8 = crc8_encode(data)

    I2cServer.write(scd, @cmd_continuous_measurement <> <<msb, lsb>> <> <<crc8>>)
  end

  def set_altitude(scd, altitude_m) do
    <<msb, lsb>> = <<altitude_m::integer-size(16)>>
    data = @cmd_continuous_measurement <> <<msb, lsb>>
    crc8 = crc8_encode(data)

    I2cServer.write(scd, @cmd_set_altitude_compensation <> <<msb, lsb>> <> <<crc8>>)
  end

  def stop_readings(scd) do
    I2cServer.write(scd, @cmd_stop_readings <> <<0x01, 0x07>>)
  end

  def data_reset(scd) do
    # write read command
    :ok = I2cServer.write(scd, @cmd_read_measurement)
    data_available(scd)
  end

  def reset(scd) do
    I2cServer.write(scd, @cmd_soft_reset)
  end

  def data_available(scd) do
    I2cServer.write_read(scd, @cmd_get_data_ready, 3)
  end

  # private
  defp crc8_encode(data) do
    :cerlc.calc_crc(data, @crc8_def)
  end

  defp convert_raw_measurements(read_measurement) do
    <<c02_mmsb, c02_mlsb, _c02_crc0, c02_lmsb, c02_llsb, _c02_crc1, t_mmsb, t_mlsb, _t_crc0,
      t_lmsb, t_llsb, _t_crc1, rh_mmsb, rh_mlsb, _rh_crc0, rh_lmsb, rh_llsb,
      _::bitstring>> = read_measurement

    <<c02::float-size(32)>> = <<c02_mmsb, c02_mlsb, c02_lmsb, c02_llsb>>
    <<temp_c::float-size(32)>> = <<t_mmsb, t_mlsb, t_lmsb, t_llsb>>
    <<rh::float-size(32)>> = <<rh_mmsb, rh_mlsb, rh_lmsb, rh_llsb>>

    vpds = calc_vpd(temp_c, rh)

    Map.merge(%{c02_ppm: c02, temp_c: temp_c, rh: rh}, vpds)
  end

  defp calc_vpd(temp_c, rh) do
    # TODO provide way to configure leaf_offset
    leaf_offset = 2
    asvp = calc_svp(temp_c)
    lsvp = calc_svp(temp_c - leaf_offset)
    avpd = asvp * (1 - rh / 100)
    lvpd = lsvp - asvp * rh / 100

    %{avpd: avpd, lvpd: lvpd}
  end

  defp calc_svp(temp_c) do
    610.78 * Math.exp(temp_c / (temp_c + 238.3) * 17.2694) / 1000
  end

  defp check_ambient_pressure(ambient_pressure) do
    if ambient_pressure != 0 &&
         (ambient_pressure < @min_pressure || ambient_pressure > @max_pressure),
       do: throw("ambient_pressure must be from 700-1400 mBar")

    :ok
  end
end
