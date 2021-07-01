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
      temp_c_bmp: 0,
      temp_f: 0,
      dew_point_f: 0,
      rh: 0,
      avpd: 0,
      lvpd: 0,
      altitude_m: 0,
      pressure_pa: 0
    }

    {:ok, assign(socket, sensor_data: initial_sensor_data)}
  end

  @impl true
  def handle_info({:new_data, measurements}, socket) do
    # TODO convert measurements to sensor data
    {:noreply, assign(socket, sensor_data: measurements)}
  end
end
