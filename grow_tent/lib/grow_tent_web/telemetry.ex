defmodule GrowTentWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller will execute the given period measurements
      # every 10_000ms. Learn more here: https://hexdocs.pm/telemetry_metrics
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
      # Add reporters as children of your supervision tree.
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io"),
      summary("grow_#{device_name()}.sensors.temp_c"),
      summary("grow_#{device_name()}.sensors.temp_c_bmp"),
      summary("grow_#{device_name()}.sensors.temp_f"),
      summary("grow_#{device_name()}.sensors.dew_point_f"),
      summary("grow_#{device_name()}.sensors.c02_ppm"),
      summary("grow_#{device_name()}.sensors.rh"),
      summary("grow_#{device_name()}.sensors.avpd"),
      summary("grow_#{device_name()}.sensors.lvpd"),
      summary("grow_#{device_name()}.sensors.pressure_inhg"),
      summary("grow_#{device_name()}.sensors.pressure_pa")
    ]
  end

  def prometheus_metrics do
    [
      last_value("grow_#{device_name()}.sensors.temp_c"),
      last_value("grow_#{device_name()}.sensors.temp_c_bmp"),
      last_value("grow_#{device_name()}.sensors.temp_c_soil_stick"),
      last_value("grow_#{device_name()}.sensors.temp_f"),
      last_value("grow_#{device_name()}.sensors.temp_f_soil_stick"),
      last_value("grow_#{device_name()}.sensors.moisture_soil_stick"),
      last_value("grow_#{device_name()}.sensors.dew_point_f"),
      last_value("grow_#{device_name()}.sensors.c02_ppm"),
      last_value("grow_#{device_name()}.sensors.rh"),
      last_value("grow_#{device_name()}.sensors.avpd"),
      last_value("grow_#{device_name()}.sensors.lvpd"),
      last_value("grow_#{device_name()}.sensors.pressure_inhg"),
      last_value("grow_#{device_name()}.sensors.pressure_pa")
    ]
  end

  def device_name do
    Application.get_env(:grow_tent, GrowTentWeb.Telemetry)[:device_name]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      # {GrowTentWeb, :count_users, []}
    ]
  end
end
