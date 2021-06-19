defmodule GrowTent.Sensors.Scd30Server do
  use GenServer

  @scd30_default_addr 0x61

  @impl true
  def init(i2c_bus, ambient_pressure = 0, address = @scd30_default_addr) do
    if ambient_pressure != 0 &&
         (ambient_pressure < @min_pressure || ambient_pressure > @max_pressure),
       do: throw("ambient_pressure must be from 700-1400 mBar")

    state = %{
      i2c_bus: i2c_bus,
      ambient_pressure: ambient_pressure,
      address: address,
      temp_c: nil,
      rh: nil,
      co2_ppm: nil
    }

    {:ok, state}
  end
end
