defmodule Concaveman.GeoJSONStore do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def store(pid, geojson) do
    GenServer.call(__MODULE__, {:store, pid, geojson})
  end

  def retrieve(pid) do
    GenServer.call(__MODULE__, {:retrieve, pid})
  end

  def handle_call({:store, pid, geojson}, _from, state) do
    new_state = Map.put(state, pid, geojson)
    {:reply, :ok, new_state}
  end

  def handle_call({:retrieve, pid}, _from, state) do
    geojson = Map.get(state, pid)
    {:reply, geojson, state}
  end
end
