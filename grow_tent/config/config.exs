# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :grow_tent, GrowTentWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "dxyJ331p94VqxOj7XhqEs792Cc8Xxn017+fV5ALoMjneFLwlcRZ/hCai65yx0bGM",
  render_errors: [view: GrowTentWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: GrowTent.PubSub,
  live_view: [signing_salt: "Qh5bwya6"]

config :grow_tent, GrowTentWeb.Telemetry, device_name: System.get_env("DEVICE_NAME", "tent_1")

config :grow_tent, GrowTent.Sensors, sensors: System.get_env("SENSORS", "")

# config :grow_tent, GrowTent.PromEx,
#  disabled: false,
#  manual_metrics_start_delay: :no_delay,
#  drop_metrics_groups: [],
#  grafana: :disabled,
#  metrics_server: :enabled

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
