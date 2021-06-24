defmodule GrowTent.Store.StoreServer do
  use GenServer

  require Logger

  alias GrowTent.Store.Store

  # Client
  def start_link(params) when is_list(params) do
    config_store_file =
      Application.get_env(:ui, GrowTent.Store)[:config_store_versioned_file_path]

    table =
      case params do
        [h | _] when is_atom(h) -> h
        _ -> :config_store
      end

    GenServer.start_link(__MODULE__, %{file: config_store_file, table: table}, name: __MODULE__)
  end

  def insert(module, config) do
    GenServer.cast(__MODULE__, {:insert, {module, config}})
  end

  def delete(module) do
    GenServer.cast(__MODULE__, {:delete, module})
  end

  def get(module) do
    GenServer.call(__MODULE__, {:get, module})
  end

  def has_key(module) do
    GenServer.call(__MODULE__, {:has_key, module})
  end

  def all do
    GenServer.call(__MODULE__, :all)
  end

  def table_name do
    GenServer.call(__MODULE__, :table_name)
  end

  # Server Callbacks
  @impl true
  def init(state) do
    {:ok, state, {:continue, :create_table}}
  end

  @impl true
  def handle_continue(:create_table, %{file: file, table: table} = state) do
    _ = Logger.debug("Store File: #{inspect(file)}")

    # _ = GrowTent.Record.init_all()

    if File.exists?(file) do
      {:ok, _ref} = Store.load_table_from_file(table, file)
    else
      _ = Logger.warn("No store file: #{inspect(file)}, located by StoreServer")
      {:ok, _ref} = Store.storage_up(table)
      :ok = Store.dump_table_to_file(table, file)
    end

    {:noreply, state}
  end

  # Writes
  @impl true
  def handle_cast({:insert, {module, config}}, %{file: file, table: table} = state) do
    :ok = Store.insert(table, module, config)
    :ok = Store.dump_table_to_file(table, file)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:delete, module}, %{file: file, table: table} = state) do
    :ok = Store.delete(table, module)
    :ok = Store.dump_table_to_file(table, file)

    {:noreply, state}
  end

  # Reads
  @impl true
  def handle_call({:get, module}, _from, %{table: table} = state) do
    {:ok, config} = Store.get(table, module)
    {:reply, config, state}
  end

  @impl true
  def handle_call({:has_key, module}, _from, %{table: table} = state) do
    {:ok, has_key} = Store.has_key(table, module)
    {:reply, has_key, state}
  end

  @impl true
  def handle_call(:all, _from, %{table: table} = state) do
    {:ok, table_data} = Store.all(table)
    {:reply, table_data, state}
  end

  @impl true
  def handle_call(:table_name, _from, %{table: table} = state) do
    {:reply, table, state}
  end
end
