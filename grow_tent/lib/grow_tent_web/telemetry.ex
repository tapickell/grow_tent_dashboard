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
      summary("grow_tent.sensors.temp_c"),
      summary("grow_tent.sensors.pressure_pa"),
      summary("grow_tent.sensors.c02_ppm"),
      summary("grow_tent.sensors.rh"),
      summary("grow_tent.sensors.avpd"),
      summary("grow_tent.sensors.lvpd"),
      summary("grow_tent.sensors.infrared_light"),
      summary("grow_tent.sensors.lux_reading"),
      summary("grow_tent.sensors.pressure_inhg"),
      summary("grow_tent.sensors.pressure_pa"),
      summary("grow_tent.sensors.visible_light")
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      # {GrowTentWeb, :count_users, []}
    ]
  end
end
