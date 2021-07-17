defmodule GrowTent.Sensors.SoilStick do
  require Logger

  alias GrowTent.Utils.Units

  @default_address 0x36
  @moisture_range 100..1000
  @moisture_error 4095
  @cmd_moisture <<0x0F>> <> <<0x10>>
  @moist_size 2
  @wait_period 5

  def start_link(bus_name, address \\ @default_address) do
    _ = Logger.info("[SOIL_STICK] Starting on bus #{bus_name} at address #{address}")

    I2cServer.start_link(bus_name: bus_name, bus_address: address)
  end

  def init(stick) do
    _ = Logger.info("[SOIL_STICK] Initializing sensor :: #{inspect(stick)}")
    :ok
  end

  def measure(stick) do
    [:ok, :ok, {:ok, moisture_reading}] =
      I2cServer.bulk(stick, [
        {:write, [@cmd_moisture]},
        {:sleep, @wait_period},
        {:read, @moist_size}
      ])

    convert_raw_measurements(moisture_reading)
  end

  def transform(measurements) do
    %{moisture: moisture} = measurements

    %{
      moisture_soil_stick: moisture
    }
  end

  defp convert_raw_measurements(moisture_reading) do
    <<moisture::integer-size(16)>> = moisture_reading

    if not accurate_moisture_reading?(moisture) do
      _ =
        Logger.error(
          "Moisture Reading inaccurate :: #{inspect(moisture)} should be in range #{
            inspect(@moisture_range)
          }"
        )

      %{moisture: 0}
    else
      %{moisture: moisture}
    end
  end

  defp accurate_moisture_reading?(moisture) do
    moisture in @moisture_range
  end
end
