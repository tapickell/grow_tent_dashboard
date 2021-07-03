defmodule GrowTent.Sensors.Control do
  alias GrowTent.Sensors.{Bmp3, Scd30, SoilStick, Tsl2951}

  @known_sensors = ["scd30", "tsl2951", "bmp3", "soil_stick"]

  @sensors =
    Application.compile_env!(:grow_tent, GrowTent.Sensors)[:sensors]
    |> String.split(",")
    |> Enum.filter(&(&1 in @known_sensors))

  @sensor_modules = %{
    "bmo3" => Bmp3,
    "scd30" => Scd30,
    "soil_stick" => SoilStick,
    "tsl2951" => Tsl2951
  }

  def start_all(bus_name) do
    mods =
      @sensor_modules
      |> Enum.filter(fn {k, _v} -> k in @sensors end)
      |> Enum.map(fn {k, mod} ->
        {:ok, pid} = mod.start_link(bus_name)
        {mod, pid}
      end)

    {:ok, mods}
  end

  def init_all(sensor_pids) do
    initialized? =
      sensor_pids
      |> Enum.map(fn {mod, pid} -> mod.init(pid) end)
      |> Enum.all?(&(&1 == :ok))

    if initialized?, do: :ok, else: {:error, "Failed to init all sensors"}
  end

  def measure_all(sensor_pids) do
    sensor_pids
    |> Enum.reduce(%{}, fn {mod, pid}, acc ->
      measurements =
        pid
        |> mod.measure()
        |> mod.transform()

      Map.merge(acc, measurements)
    end)
  end

  def empty_measurements do
    %{
      temp_c_bmp: nil,
      dew_point_f: nil,
      temp_c: nil,
      temp_f: nil,
      rh: nil,
      co2_ppm: nil,
      avpd: nil,
      lvpd: nil,
      altitude_m: nil,
      pressure_pa: nil
    }
  end
end
