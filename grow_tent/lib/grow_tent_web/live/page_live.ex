defmodule GrowTentWeb.PageLive do
  use GrowTentWeb, :live_view
  alias GrowTentWeb.Endpoint

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Endpoint.subscribe("sensors:scd30")
    end

    initial_sensor_data = %{
      c02_ppm: 0,
      temp_c: 0,
      rh: 0
    }

    {:ok, assign(socket, sensor_data: initial_sensor_data)}
  end

  @impl true
  def handle_info({:new_data, measurements}, socket) do
    # TODO convert measurements to sensor data
    {:noreply, assign(socket, sensor_data: measurements)}
  end
end
