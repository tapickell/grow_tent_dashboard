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


    LUX SENSOR

    addy = 0x29
    41

    Formula barometric pressure conversion
    pressure_pa * 0.00029529983071445 = inHg

    iex(3)> {:ok, lux} = I2cServer.start_link(bus_name: "i2c-1", bus_address: addy)
    {:ok, #PID<0.4763.0>}

    Get Device ID, common check to see if device is online
    iex(43)> {:ok, <<dev_id::integer>>} = I2cServer.write_read(lux, 0xA0 ||| 0x12, 1)
    {:ok, "P"}
    iex(44)> dev_id
    80
    iex(45)> 0x50
    80

    iex(50)> {:ok, <<chan_zero::integer>>} = I2cServer.write_read(lux, 0xA0 ||| 0x14, 1)
  {:ok, <<25>>}
  iex(51)> {:ok, <<chan_one::integer>>} = I2cServer.write_read(lux, 0xA0 ||| 0x16, 1) 
  {:ok, <<5>>}
  iex(52)> zhan_zero
  ** (CompileError) iex:52: undefined function zhan_zero/0

  iex(52)> chan_zero
  25
  iex(53)> chan_one
  5
  iex(54)> chan_one <<< 8                                                             
  1280
  iex(55)> chan_one <<< 8 ||| chan_zero
  1305
  iex(56)> chan_one <<< 16 ||| chan_zero
  327705
  iex(57)> full - chan_one <<< 16 ||| chan_zero
  ** (CompileError) iex:57: undefined function full/0
    (stdlib 3.14.1) lists.erl:1358: :lists.mapfoldl/3
    (stdlib 3.14.1) lists.erl:1358: :lists.mapfoldl/3
    (stdlib 3.14.1) lists.erl:1358: :lists.mapfoldl/3
  iex(57)> full = chan_one <<< 16 ||| chan_zero
  327705
  iex(58)> full - chan_one
  327700

  iex(70)> {:ok, <<enable::bitstring>>} = I2cServer.write_read(lux, 0xA0 ||| 0x00, 1) 
  {:ok, <<147>>}
  iex(71)> Integer.to_string(147, 2)
  "10010011"

  iex(89)> {:ok, <<chan_zero_low::integer, chan_zero_high::integer, chan_one_low::integer, chan_one_high::integer>>} = I2cServer.write_read(lux, 0xA0 ||| 0x14, 4)
  {:ok, <<28, 0, 5, 0>>}

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
  @bmp388_default_addr 0x77
  @tsl2591_default_addr 0x29
  @data_update_interval 6_000
  @min_pressure 700
  @max_pressure 1400

  @impl true
  def init(i2c_bus) do
    address = @scd30_default_addr

    {:ok, i2c_ref} = I2C.open(i2c_bus)
    {:ok, bmp} = BMP3XX.start_link(bus_name: i2c_bus, bus_address: @bmp388_default_addr)

    {:ok,
     %BMP3XX.Measurement{
       altitude_m: altitude,
       pressure_pa: ambient_pressure
     }} = BMP3XX.measure(bmp)

    state = %{
      ref: i2c_ref,
      bus: i2c_bus,
      bmp: bmp,
      altitude_m: altitude,
      ambient_pressure: ambient_pressure,
      address: address,
      measurements: %{
        temp_c: nil,
        rh: nil,
        co2_ppm: nil,
        avpd: nil,
        lvpd: nil,
        pressure_pa: nil
      }
    }

    {:ok, state, {:continue, :sensor_setup}}
  end

  @impl true
  def handle_continue(
        :sensor_setup,
        %{ref: ref, address: address, bmp: bmp} = state
      ) do
    {:ok,
     %BMP3XX.Measurement{
       altitude_m: altitude,
       pressure_pa: ambient_pressure
     }} = BMP3XX.measure(bmp)

    # do any setup for altitude / barometric pressure / temp offset
    # :ok = I2C.write(ref, address, @cmd_continuous_measurement <> <<0x00, 0x00>> <> <<0x81>>)
    Process.send_after(__MODULE__, :fetch_sensor_data, @data_update_interval)

    # TODO need to convert ambient to <<0x00, 0x00>> format
    # TODO is it better to use pressure or altitude ??
    # TODO need to generate crc-8 in <<0x00>>

    {:noreply, state}
  end

  @impl true
  def handle_info(:fetch_sensor_data, %{ref: ref, address: address, bmp: bmp} = state) do
    {:ok,
     %BMP3XX.Measurement{
       pressure_pa: ambient_pressure
     }} = BMP3XX.measure(bmp)

    # read measurement
    :ok = I2C.write(ref, address, <<0x03, 0x00>>)
    {:ok, read_measurement} = I2C.read(ref, address, 19)
    <<msb::8, lsb::8, _::bitstring>> = read_measurement
    _ = Logger.warn("#{__MODULE__} :: <<#{msb}, #{lsb}>> measurement from sensor")

    measurements =
      convert_raw_measurements(read_measurement)
      |> Map.merge(%{pressure_pa: ambient_pressure})

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

  def handle_call(:last_measurements, _from, %{measurements: last_measurements} = state) do
    {:reply, last_measurements, state}
  end

  defp convert_raw_measurements(read_measurement) do
    <<c02_mmsb, c02_mlsb, _c02_crc0, c02_lmsb, c02_llsb, _c02_crc1, t_mmsb, t_mlsb, _t_crc0,
      t_lmsb, t_llsb, _t_crc1, rh_mmsb, rh_mlsb, _rh_crc0, rh_lmsb, rh_llsb,
      _::bitstring>> = read_measurement

    <<c02::float-size(32)>> = <<c02_mmsb, c02_mlsb, c02_lmsb, c02_llsb>>
    <<temp_c::float-size(32)>> = <<t_mmsb, t_mlsb, t_lmsb, t_llsb>>
    <<rh::float-size(32)>> = <<rh_mmsb, rh_mlsb, rh_lmsb, rh_llsb>>

    vpds = calc_vpd(temp_c, rh)

    Map.merge(%{c02_ppm: c02, temp_c: temp_c, rh: rh}, vpds)
  end

  defp calc_vpd(temp_c, rh) do
    # TODO provide way to configure leaf_offset
    leaf_offset = 2
    asvp = calc_svp(temp_c)
    lsvp = calc_svp(temp_c - leaf_offset)
    avpd = asvp * (1 - rh / 100)
    lvpd = lsvp - asvp * rh / 100

    %{avpd: avpd, lvpd: lvpd}
  end

  defp calc_svp(temp_c) do
    610.78 * Math.exp(temp_c / (temp_c + 238.3) * 17.2694) / 1000
  end

  defp check_ambient_pressure(ambient_pressure) do
    if ambient_pressure != 0 &&
         (ambient_pressure < @min_pressure || ambient_pressure > @max_pressure),
       do: throw("ambient_pressure must be from 700-1400 mBar")

    :ok
  end
end
