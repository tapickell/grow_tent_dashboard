defmodule GrowTent.MixProject do
  use Mix.Project

  def project do
    [
      app: :grow_tent,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {GrowTent.Application, []},
      extra_applications: [
        :logger,
        :runtime_tools,
        :crypto,
        :os_mon,
        :phoenix_ecto
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5.9"},
      {:phoenix_ecto, "~> 4.1"},
      {:phoenix_live_view, "~> 0.15.1"},
      {:ecto, "~> 3.5.4"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.4"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:prom_ex, "~> 1.2.2"},
      # {:prometheus_ex, "~> 3.0"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:circuits_i2c, "~> 0.3.8"},
      {:bmp3xx, "~> 0.1.2"},
      {:math, "~> 0.6.0"},
      {:cerlc, "~> 0.2.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "cmd npm install --prefix assets"],
      preburn: [
        "cmd npm install --prefix assets --production",
        "cmd npm run deploy --prefix assets",
        "phx.digest"
      ]
    ]
  end
end
