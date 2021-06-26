defmodule GrowTent.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  require Logger

  use Application

  def start(_type, _args) do
    children =
      [
        GrowTentWeb.Telemetry,
        # GrowTent.PromEx,
        {TelemetryMetricsPrometheus, [metrics: GrowTentWeb.Telemetry.prometheus_metrics()]},
        {Phoenix.PubSub, name: GrowTent.PubSub},
        # GrowTent.Store.Supervisor,
        GrowTentWeb.Endpoint
        # Start a worker by calling: GrowTent.Worker.start_link(arg)
        # {GrowTent.Worker, arg}
      ]
      |> live_sensors()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GrowTent.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    GrowTentWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp live_sensors(list) do
    case System.get_env("LIVE_SENSORS") do
      "off" ->
        _ = Logger.warn("Live Sensors OFF")
        list

      _ ->
        _ = Logger.info("Live Sensors ON")
        list ++ [GrowTent.Sensors.Scd30Server]
    end
  end
end
