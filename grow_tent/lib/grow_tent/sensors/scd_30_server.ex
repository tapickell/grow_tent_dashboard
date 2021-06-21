defmodule GrowTent.Sensors.Scd30Server do
  use GenServer

  require Logger

  alias Phoenix.PubSub
  alias Circuits.I2C

  @moduledoc """
  ❯ cat hello_phoenix/firmware/notes.org
    * Temp Reading Steps
    ** Write to get temp Reading
    *** Circuits.I2C.write!(ref, 0x40, <<0x00>>)
    ** Read 32 bit unsigned integer
    *** {:ok, <<data::32>>} = Circuits.I2C.read(ref, 0x40, 4)
    ** Bitshift right
    *** a = Bitwise.>>>(data, 16)
    ** Calculate degrees Celcius
    *** ((a / 65536) * 165) - 40
    *** 27.92755126953125
    ** Round and convert to F if desired
    * Humidity Reading Steps
    ** Write to get temp Reading
    *** Circuits.I2C.write!(ref, 0x40, <<0x00>>)
    ** Read 32 bit unsigned integer
    *** {:ok, <<data::32>>} = Circuits.I2C.read(ref, 0x40, 4)
    ** Bitwise and
    *** a = Bitwise.&&&(data, 0xFFFF)
    ** Calculate RH
    *** (a / 65536) * 100
    *** 16.50390625
    ** Round%

  Testing of sensor readings
  # @cmnd_read_measurement needs to be *2 8 bit
  iex(38)> I2C.write(ref, address, <<0x03,0x00>>)
  :ok

  iex(67)> {:ok, reading} = I2C.read(ref, address, 37)                                                              {:ok,                                                                                                                   <<70, 116, 110, 219, 21, 233, 65, 191, 109, 1, 160, 137, 66, 28, 239, 17, 32,                                            157, 0, 0, 129, 0, 0, 129, 73, 14, 212, 22, 78, 151, 74, 126, 1, 209, 72, 53,

  iex(143)> <<c02::float-size(32)>> = <<68, 68, 237, 229>>
  <<68, 68, 237, 229>>
  iex(144)> c02
  787.7171020507813
  iex(145)> <<temp::float-size(32)>> = <<65, 222, 214, 48>>     
  <<65, 222, 214, 48>>
  iex(146)> temp
  27.854583740234375
  iex(147)> <<rhumidity::float-size(32)>> = <<66, 27, 141, 224>>      
  <<66, 27, 141, 224>>
  iex(148)> rhumidity
  38.8885498046875
  iex(149)> temp * 9/5+ 32
  82.13825073242188
  iex(150)> temp * 1.8 + 32
  82.13825073242188
  iex(151)> <<c02_mmsb, c02_mlsb, c02_lmsb, c02_llsb>>
  <<68, 68, 237, 229>>
  iex(152)> <<c02_reading::float-size(32)>> = <<c02_mmsb, c02_mlsb, c02_lmsb, c02_llsb>>
  <<68, 68, 237, 229>>
  iex(153)> c02_reading
  787.7171020507813

  <<c02_mmsb::8,
    c02_mlsb::8,
    c02_crc0::8,
    c02_lmsb::8,
    c02_llsb::8,
    c02_crc1::8,
    t_mmsb::8,
    t_mlsb::8,
    t_crc0::8,
    t_lmsb::8,
    t_llsb::8,
    t_crc1::8,
    rh_mmsb::8,
    rh_mlsb::8,
    rh_crc0::8,
    rh_lmsb::8,
    rh_llsb::8,
    rh_crc1::8>> = read_measurement
  """

  # Client
  def start_link(_params) do
    GenServer.start_link(__MODULE__, "i2c-1", name: __MODULE__)
  end

  def last_measurements do
    GenServer.call(__MODULE__, :last_measurements)
  end

  # Server 
  @cmd_continuous_measurement <<0x00, 0x10>>
  @cmd_get_data_ready <<0x02, 0x02>>
  @cmd_read_measurement <<0x03, 0x00>>
  @scd30_default_addr 0x61
  @data_update_interval 6_000
  @min_pressure 700
  @max_pressure 1400

  @impl true
  def init(i2c_bus) do
    ambient_pressure = 0
    address = @scd30_default_addr
    :ok = check_ambient_pressure(ambient_pressure)

    {:ok, i2c_ref} = I2C.open(i2c_bus)

    state = %{
      ref: i2c_ref,
      bus: i2c_bus,
      ambient_pressure: ambient_pressure,
      address: address,
      measurements: %{
        temp_c: nil,
        rh: nil,
        co2_ppm: nil
      }
    }

    {:ok, state, {:continue, :sensor_setup}}
  end

  @impl true
  def handle_continue(
        :sensor_setup,
        %{ref: ref, address: address, ambient_pressure: _ambient_pressure} = state
      ) do
    # do any setup for altitude / barometric pressure / temp offset
    # :ok = I2C.write(ref, address, @cmd_continuous_measurement <> <<0x00, 0x00>> <> <<0x81>>)
    Process.send_after(__MODULE__, :fetch_sensor_data, @data_update_interval)

    # TODO need to convert ambient to <<0x00, 0x00>> format
    # TODO need to generate crc-8 in <<0x00>>

    {:noreply, state}
  end

  @impl true
  def handle_info(:fetch_sensor_data, %{ref: ref, address: address} = state) do
    # read measurement
    :ok = I2C.write(ref, address, <<0x03, 0x00>>)
    {:ok, read_measurement} = I2C.read(ref, address, 19)
    <<msb::8, lsb::8, _::bitstring>> = read_measurement
    _ = Logger.warn("#{__MODULE__} :: <<#{msb}, #{lsb}>> measurement from sensor")

    measurements = convert_raw_measurements(read_measurement)
    # send out to pub sub or telemetry
    :telemetry.execute([:grow_tent, :sensors], %{temp_c: measurements.temp_c}, %{})
    :telemetry.execute([:grow_tent, :sensors], %{c02_ppm: measurements.c02_ppm}, %{})
    :telemetry.execute([:grow_tent, :sensors], %{rh: measurements.rh}, %{})
    PubSub.broadcast(GrowTent.PubSub, "sensors:scd30", {:new_data, measurements})
    # send after 60 seconds to fetch fresh data
    Process.send_after(__MODULE__, :fetch_sensor_data, @data_update_interval)

    # {:noreply, %{state | measurements: measurements}}
    {:noreply, Map.put(state, :measurements, measurements)}
  end

  def handle_call(:last_measurements, _from, %{measurements: last_measurements} = state) do
    {:reply, last_measurements, state}
  end

  defp convert_raw_measurements(read_measurement) do
    <<c02_mmsb, c02_mlsb, _c02_crc0, c02_lmsb, c02_llsb, _c02_crc1, t_mmsb, t_mlsb, _t_crc0,
      t_lmsb, t_llsb, _t_crc1, rh_mmsb, rh_mlsb, _rh_crc0, rh_lmsb, rh_llsb,
      _::bitstring>> = read_measurement

    <<c02::float-size(32)>> = <<c02_mmsb, c02_mlsb, c02_lmsb, c02_llsb>>
    <<t::float-size(32)>> = <<t_mmsb, t_mlsb, t_lmsb, t_llsb>>
    <<rh::float-size(32)>> = <<rh_mmsb, rh_mlsb, rh_lmsb, rh_llsb>>

    %{c02_ppm: c02, temp_c: t, rh: rh}
  end

  defp check_ambient_pressure(ambient_pressure) do
    if ambient_pressure != 0 &&
         (ambient_pressure < @min_pressure || ambient_pressure > @max_pressure),
       do: throw("ambient_pressure must be from 700-1400 mBar")

    :ok
  end
end
