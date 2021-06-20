defmodule GrowTent.Sensors.Scd30 do
  alias Circuits.I2C

  @cmd_continuous_measurement 0x0010
  @cmd_set_measurement_interval 0x4600
  @cmd_get_data_ready <<0x02, 0x02>>
  @cmd_read_measurement <<0x03, 0x00>>
  @cmd_automatic_self_calibration 0x5306
  @cmd_set_forced_recalibration_factor 0x5204
  @cmd_set_temperature_offset 0x5403
  @cmd_set_altitude_compensation 0x5102
  @cmd_soft_reset 0xD304

  def read(i2c_bus, address, read_count \\ 11) do
    with {:ok, ref} <- I2C.open(i2c_bus),
         {:ok, bin} <- I2C.read(ref, address, read_count),
         :ok <- I2C.close(i2c_bus) do
      {bin, read_count}
    end
  end

  def write(i2c_bus, address, data) do
    with {:ok, ref} <- I2C.open(i2c_bus),
         :ok <- I2C.write(ref, address, data),
         :ok <- I2C.close(i2c_bus) do
      :ok
    end
  end
end
