defmodule NanNoHi.Server do
  @moduledoc """
  A server of NanNoHi.
  """
  use GenServer

  @server_option_keys []

  def start_link(options) do
    {server_options, gen_server_options} = Keyword.split(options, @server_option_keys)

    GenServer.start_link(__MODULE__, server_options, gen_server_options)
  end

  def append(pid, year, month, day, date) do
    GenServer.cast(pid, {:append, year, month, day, date})
  end

  def lookup(pid, year) do
    GenServer.call(pid, {:lookup, year})
  end

  def lookup(pid, year, month) do
    GenServer.call(pid, {:lookup, year, month})
  end

  def lookup(pid, year, month, day) do
    GenServer.call(pid, {:lookup, year, month, day})
  end

  @impl true
  def init(_) do
    table = :ets.new(__MODULE__, [:ordered_set])

    {:ok, %{table: table}}
  end

  @impl true
  def handle_cast({:append, year, month, day, date}, state) do
    :ets.insert(state.table, {{year, month, day}, date})

    {:noreply, state}
  end

  @impl true
  def handle_call({:lookup, year}, _from, state) do
    result = lookup_dates(state.table, year, :_, :_)

    {:reply, result, state}
  end

  @impl true
  def handle_call({:lookup, year, month}, _from, state) do
    result = lookup_dates(state.table, year, month, :_)

    {:reply, result, state}
  end

  @impl true
  def handle_call({:lookup, year, month, day}, _from, state) do
    result = lookup_dates(state.table, year, month, day)

    {:reply, result, state}
  end

  defp lookup_dates(table, year, month, day) do
    :ets.select(table, [{{{year, month, day}, :_}, [], [:"$_"]}])
    |> Enum.map(fn {erl_date, date} -> {Date.from_erl!(erl_date), date} end)
  end
end
