defmodule GrowTent.Sensors.Bmp3 do
  require Logger

  alias GrowTent.Utils.Units

  @default_address 0x77

  def start_link(bus_name, address \\ @default_address) do
    _ = Logger.info("[BMP3] Starting on bus #{bus_name} at address #{address}")

    BMP3XX.start_link(bus_name: bus_name, bus_address: address)
  end

  def init(_bmp), do: :ok

  def measure(bmp) do
    {:ok, measurements} = BMP3XX.measure(bmp)
    measurements
  end

  def transform(measurements) do
    %{
      altitude_m: altitude,
      pressure_pa: ambient_pressure,
      temperature_c: temp_c_bmp
    } = measurements

    %{
      pressure_inhg: Units.pascal_to_inhg(ambient_pressure),
      altitude_m: altitude,
      pressure_pa: ambient_pressure,
      temp_c_bmp: temp_c_bmp
    }
  end
end
