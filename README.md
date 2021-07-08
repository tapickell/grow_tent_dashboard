# Nerves Based Grow Tent Firmware and UI 
this is a poncho application with the Phoenix application in `/grow_tent`
and the Nerves application in `/grow_tent_firmware`
the software is built and deployed from the firmware directory

# Getting Started
If you have not built anything with Nerves there is some initial setup to get things working
Follow the steps here that define all the things you need for each OS to be able to 
get to the end goal of installing `nerves_bootstrap`
[Nerves Installation](https://hexdocs.pm/nerves/installation.html#content)

## Env Vars
In order to make this firmware work on multiple configurations for different devices
currently it takes some vars during the build burn stage to tell the system 
what hostname to use and what sensors are on the board and should be enabled 
and communicated with.

`DEVICE_NAME` is used for the hostname `device_name.local`
and also used for the metrics `grow_device_name.sensors.temp_c` reporting
via the Prometheus `device_name.local:9568/metrics` endpoint.

`SENSORS` is used to define what sensors should be active and communicated with
on the device. This is passed in as a csv string `SENSORS=scd30,bmp3,tsl2951,soil_stick`
Not all devices need to have the same sensors.
ie. If you have 2 tents in the same room, only one of those tents 
may have a c02 sensor (scd30), while the other could have a simpler and cheaper
temp/rh sensor. Also something with  soil_stick does not need calculate VPD with temp and rh if it
is in a tent that has other devices that can.
The curent list of supported sensors are
* `scd30` Scd30 Temp/Rh/C02 [SCD30](https://learn.adafruit.com/adafruit-scd30/python-circuitpython)
* `bmp3` Bmp3XX Altitude/Ambient Pressure/Temp [BMP3XX](https://www.adafruit.com/product/3966)
* `soil_stick` Soil Stick Soil Moisture/Temp (In Development) [Soil Stick Stemma](https://learn.adafruit.com/adafruit-stemma-soil-sensor-i2c-capacitive-moisture-sensor/python-circuitpython-test)
* `tsl2951` Tsl2951 Lux/Raw Luminosity (This sensor is currently not 100% and can crash when lights go out) [TSL2951](https://www.adafruit.com/product/1980)


## Building and Burning Firmware
The first burn to get the firmware onto your device via sd card
```
# 1) prep ui application
cd grow_tent
mix deps.get # if not done yet
npm install --prefix assets --production
npm run deploy --prefix assets
mix phx.digest

# 2) build / burn firmware
cd ../grow_tent_firmware
export MIX_TARGET=rpi3 # or whatever device your using
# If you're using WiFi:
# export NERVES_NETWORK_SSID=your_wifi_name
# export NERVES_NETWORK_PSK=your_wifi_password
DEVICE_NAME=tent1 SENSORS=scd30,bmp3 mix firmware.burn -d /dev/yoursdcard
# once burn is finished pop sd card into device and boot
# wait like 3 minutes or if bored ping tent1.local til it comes online
ssh tent1.local  # this gives you an iex session into the device
```

After the initial burn an run update using the upload script
```
# 1) prep ui application
cd grow_tent
mix deps.get # if not done yet
npm install --prefix assets --production
npm run deploy --prefix assets
mix phx.digest

# 2) build / burn firmware
cd ../grow_tent_firmware
export MIX_TARGET=rpi3 # or whatever device your using
# If you're using WiFi:
# export NERVES_NETWORK_SSID=your_wifi_name
# export NERVES_NETWORK_PSK=your_wifi_password
DEVICE_NAME=tent1 SENSORS=scd30,bmp3 mix firmware
./upload.sh tent1.local _build/rpi3_dev/nerves/images/grow_tent_firmware.fw
# wait like 3 minutes or if bored ping tent1.local til it comes online
ssh tent1.local  # this gives you an iex session into the device
```


# A Note About Sensors
After testing this for a while in a couple of tents I realized that alot of these sensors
are optional for what one really needs to dial in an indoor grow environment.
Having C02 readings is nice but the sensor/breakout is almost $60 usd.
Unless you plan on pumping up the C02 levels, it is optional.
If you do plan on pumping the C02 levels you should get a controller
anyways since C02 in too high of a concentration in an indoor space is not fun.
The Altitude / Pressure sensor is not really needed. I wanted to test differences 
in the C02 readings by starting the sensor with pressure readings.
The Tsl2951 Lux is extra but would be nice if your trying to dial in lighting
for maximum yeild. The sensor is unstable and needs more error handling in the code.

Really, just a simple Temp/Rh sensor over I2C is fine.
Something like this for $7 [SHTC3](https://www.adafruit.com/product/4636)
With this you can calculate the VPD and dew point to some accuracy.
The Temp, Rh and VPD are the things that matter the most.

This may not be the long term solution but is working for now.
I think it may be better to have differnt configuration files in the future
that one could define for each deployment setup.


# Dashboard
If you have gotten this far and burned this to a device and are wondering,
"Hey Pickle, where the hell is the Dashboard part of this Grow Tent Dashboard?"
I am glad you asked. 
So this Nerves applicaiton with Phoenix and LiveView (prbbly not needed now)
just serves up a prometheus style `/metrics` endpoint.
All the telemetry metrics selected will be available to scrape from there.
Personally I run InfluxDB as my dashboard and it runs in Docker on another machine
on my local network. I choose InfluxDB b/c it was dead simple to get going and 
I was able to get a dasboard built out in under an hour without having to pay for a service.
Other things like this may be better but it is up to the end user what actual dasboard
to use.
```
sudo docker run -d --name influxdb -p 8086:8086 -v  /tmp/testdata/influx:/root/.influxdbv2 --network influxdb-telegraf-net quay.io/influxdb/influxdb:v2.0.3
```

# Standard Nerves Phx Starter Docs

This example demonstrates a basic poncho project for deploying a [Phoenix
Framework]-based application to a Nerves device. A "poncho project" is similar
to an umbrella project except that it's actually multiple separate-but-related
Elixir apps that use `path` dependencies instead of `in_umbrella` dependencies.
You can read more about the motivations behind this concept on the
embedded-elixir blog post about [Poncho Projects].

## Hardware

This example serves a Phoenix-based web page over the network. The steps below
assume you are using a Raspberry Pi Zero, which allows you to connect a single
USB cable to the port marked "USB" to get both network and serial console
access to the device. By default, this example will use the virtual Ethernet
interface provided by the USB cable, assign an IP address automatically, and
make it discoverable using mDNS (Bonjour). For more information about how to
configure the network settings for your environment, including WiFi settings,
see the [`vintage_net` documentation](https://hexdocs.pm/vintage_net/).

## How to Use this Repository

1. Connect your target hardware to your host computer or network as described
   above
2. Prepare your Phoenix project to build JavaScript and CSS assets:

    ```bash
    # These steps only need to be done once.
    cd ui
    mix deps.get
    npm install --prefix assets
    ```

3. Build your assets and prepare them for deployment to the firmware:

    ```bash
    # Still in ui directory from the prior step.
    # These steps need to be repeated when you change JS or CSS files.
    npm install --prefix assets --production
    npm run deploy --prefix assets
    mix phx.digest
    ```

4. Change to the `firmware` app directory

    ```bash
    cd ../firmware
    ```

5. Specify your target and other environment variables as needed:

    ```bash
    export MIX_TARGET=rpi0
    # If you're using WiFi:
    # export NERVES_NETWORK_SSID=your_wifi_name
    # export NERVES_NETWORK_PSK=your_wifi_password
    ```

6. Get dependencies, build firmware, and burn it to an SD card:

    ```bash
    mix deps.get
    mix firmware
    mix firmware.burn
    ```

7. Insert the SD card into your target board and connect the USB cable or otherwise power it on
8. Wait for it to finish booting (5-10 seconds)
9. Open a browser window on your host computer to `http://nerves.local/`
10. You should see a "Welcome to Phoenix!" page

[Phoenix Framework]: http://www.phoenixframework.org/
[Poncho Projects]: http://embedded-elixir.com/post/2017-05-19-poncho-projects/

## Learn More

* Official docs: https://hexdocs.pm/nerves/getting-started.html
* Official website: https://nerves-project.org/
* Discussion Slack elixir-lang #nerves ([Invite](https://elixir-slackin.herokuapp.com/))
* Source: https://github.com/nerves-project/nerves
