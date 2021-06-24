defmodule GrowTent.Store.Supervisor do
  # Automatically defines child_spec/1
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {GrowTent.Store.StoreServer, [:config_store]}
      # {GrowTent.Record.StoreServer, [:record_store]}
      # {GrowTent.Store.SummaryServer, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
