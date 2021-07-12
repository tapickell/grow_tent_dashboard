defmodule GrowTent.Sensors.SoilStick do
  require Logger

  alias GrowTent.Utils.Units

  @default_address 0x36
  @moisture_error 4095
  @cmd_moisture <<0x0F>> <> <<0x10>>
  @cmd_temp <<0x00>> <> <<0x04>>
  @moist_size 2
  @temp_size 4

  def start_link(bus_name, address \\ @default_address) do
    _ = Logger.info("[SOIL_STICK] Starting on bus #{bus_name} at address #{address}")

    I2cServer.start_link(bus_name: bus_name, bus_address: address)
  end

  def init(stick) do
    _ = Logger.info("[SOIL_STICK] Initializing sensor :: #{inspect(stick)}")
    :ok
  end

  def measure(stick) do
    # issue with write/read being too fast and getting previous data from write/read
    {:ok, _moisture_reading} = I2cServer.write_read(stick, @cmd_moisture, @moist_size)
    {:ok, moisture_reading} = I2cServer.write_read(stick, @cmd_moisture, @moist_size)
    {:ok, _temp_reading} = I2cServer.write_read(stick, @cmd_temp, @temp_size)
    {:ok, temp_reading} = I2cServer.write_read(stick, @cmd_temp, @temp_size)

    convert_raw_measurements(moisture_reading, temp_reading)
  end

  def transform(measurements) do
    %{moisture: moisture, temp_c: temp_c} = measurements

    %{
      moisture_soil_stick: moisture,
      temp_f_soil_stick: Units.celcius_to_f(temp_c),
      temp_c_soil_stick: temp_c
    }
  end

  defp convert_raw_measurements(moisture_reading, temp_reading) do
    <<moisture::integer-size(16)>> = moisture_reading
    <<temp_raw::integer-size(32)>> = temp_reading

    if moisture > @moisture_error do
      _ =
        Logger.error(
          "Moisture Reading above Max :: #{inspect(moisture)} realisticly should be between 30 - 800"
        )
    end

    temp_c = Units.raw_to_c(temp_raw)

    %{moisture: moisture, temp_c: temp_c}
  end
end
