defmodule GrowTent.Sensors.SoilStick do
  require Logger

  alias GrowTent.Utils.Units

  @default_address 0x36
  @moisture_range 100..1000
  @temp_range 0..40
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
    # {:ok, _moisture_reading} = I2cServer.write_read(stick, @cmd_moisture, @moist_size)
    # {:ok, moisture_reading} = I2cServer.write_read(stick, @cmd_moisture, @moist_size)
    # {:ok, _temp_reading} = I2cServer.write_read(stick, @cmd_temp, @temp_size)
    # {:ok, temp_reading} = I2cServer.write_read(stick, @cmd_temp, @temp_size)
    [:ok, :ok, {:ok, moisture_reading}, :ok, :ok, {:ok, temp_reading}] =
      I2cServer.bulk(stick, [
        {:write, [@cmd_moisture]},
        {:sleep, 1},
        {:read, @moist_size},
        {:write, [@cmd_temp]},
        {:sleep, 1},
        {:read, @temp_size}
      ])

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
    temp_c = Units.raw_to_c(temp_raw)

    if not accurate_moisture_reading?(moisture) do
      _ =
        Logger.error(
          "Moisture Reading inaccurate :: #{inspect(moisture)} should be in range #{
            inspect(@moisture_range)
          }"
        )

      moisture = 0
    end

    if not accurate_temp_reading?(temp_c) do
      _ =
        Logger.error(
          "Temp Reading inaccurate :: #{inspect(moisture)} should be in range #{
            inspect(@temp_range)
          }"
        )

      temp_c = 0
    end

    %{moisture: moisture, temp_c: temp_c}
  end

  defp accurate_moisture_reading?(moisture) do
    moisture in @moisture_range
  end

  defp accurate_temp_reading?(temp) do
    temp in @temp_range
  end
end
