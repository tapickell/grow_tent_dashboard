defmodule GrowTent.Sensors.Server do
  use GenServer

  require Logger

  alias Phoenix.PubSub
  alias GrowTent.Sensors.{Bmp3, Control, Scd30}

  @moduledoc """
  """

  # Client
  def start_link(_params) do
    GenServer.start_link(__MODULE__, "i2c-1", name: __MODULE__)
  end

  def last_measurements do
    GenServer.call(__MODULE__, :last_measurements)
  end

  # Server 
  @data_update_interval 9_000

  @impl true
  def init(i2c_bus) do
    with device_list when is_list(device_list) <- Circuits.I2C.detect_devices(i2c_bus),
         {:ok, sensor_pids} = Control.start_all(i2c_bus),
         :ok = Control.init_all(sensor_pids) do
      state = %{
        bus: i2c_bus,
        sensor_pids: sensor_pids,
        measurements: Control.empty_measurements()
      }

      {:ok, state, {:continue, :sensor_setup}}
    else
      error_case ->
        _ = Logger.error("Unable to start sensor server :: #{inspect(error_case)}")
        :ignore
    end
  end

  @impl true
  def handle_continue(:sensor_setup, state) do
    Process.send_after(__MODULE__, :fetch_sensor_data, @data_update_interval)

    {:noreply, state}
  end

  @impl true
  def handle_info(:fetch_sensor_data, %{sensor_pids: sensor_pids} = state) do
    measurements = Control.measure_all(sensor_pids)

    # send out to pub sub or telemetry
    :telemetry.execute([:grow_tent, :sensors], measurements, %{})

    PubSub.broadcast(
      GrowTent.PubSub,
      "sensors:scd30",
      {:new_data, Map.put(measurements, :timestamp, DateTime.utc_now())}
    )

    # send after 60 seconds to fetch fresh data
    Process.send_after(__MODULE__, :fetch_sensor_data, @data_update_interval)

    # {:noreply, %{state | measurements: measurements}}
    {:noreply, Map.put(state, :measurements, measurements)}
  end

  @impl true
  def handle_call(:last_measurements, _from, %{measurements: last_measurements} = state) do
    {:reply, last_measurements, state}
  end
end
