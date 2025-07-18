defmodule NanNoHi.Server do
  @moduledoc """
  A server of NanNoHi.
  """
  use GenServer

  defguard is_date(year) when is_integer(year) and year > 0
  defguard is_date(year, month) when is_date(year) and month in 1..12
  defguard is_date(year, month, day) when is_date(year, month) and day in 1..31

  NimbleCSV.define(CsvParser, [])

  import NanNoHi.Utils, only: [string_to_erl_date: 1]

  @server_option_keys []

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(options) do
    {server_options, gen_server_options} = Keyword.split(options, @server_option_keys)

    GenServer.start_link(__MODULE__, server_options, gen_server_options)
  end

  @spec append(pid(), NanNoHi.year(), NanNoHi.month(), NanNoHi.day(), NanNoHi.event()) ::
          :ok | {:error, term()}
  def append(pid, year, month, day, event) when is_date(year, month, day) do
    GenServer.call(pid, {:append, year, month, day, event})
  end

  @spec import(pid(), NanNoHi.events()) :: :ok | {:error, term()}
  def import(pid, events) do
    GenServer.call(pid, {:import, events})
  end

  @spec lookup(pid(), NanNoHi.year()) :: [{Date.t(), NanNoHi.event()}]
  def lookup(pid, year) when is_date(year) do
    GenServer.call(pid, {:lookup, year})
  end

  @spec lookup(pid(), NanNoHi.year(), NanNoHi.month()) :: [{Date.t(), NanNoHi.event()}]
  def lookup(pid, year, month) when is_date(year, month) do
    GenServer.call(pid, {:lookup, year, month})
  end

  @spec lookup(pid(), NanNoHi.year(), NanNoHi.month(), NanNoHi.day()) :: [
          {Date.t(), NanNoHi.event()}
        ]
  def lookup(pid, year, month, day) when is_date(year, month, day) do
    GenServer.call(pid, {:lookup, year, month, day})
  end

  @impl true
  @spec init(keyword()) :: {:ok, map()}
  def init(_) do
    table = :ets.new(__MODULE__, [:bag])

    {:ok, %{table: table}}
  end

  @impl true
  def handle_call({:append, year, month, day, event}, _from, state) do
    :ets.insert(state.table, {{year, month, day}, event})

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:import, events}, _from, state) when is_list(events) do
    events
    |> import_events(state.table)

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:import, events}, _from, state) when is_binary(events) do
    events
    |> CsvParser.parse_string()
    |> Enum.map(fn [string_date, event] ->
      case string_to_erl_date(string_date) do
        {:ok, date} -> {date, event}
      end
    end)
    |> import_events(state.table)

    {:reply, :ok, state}
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

  defp import_events(events, table) do
    events
    |> Enum.each(fn {date, event} ->
      :ets.insert(table, {date, event})
    end)
  end

  defp lookup_dates(table, year, month, day) do
    :ets.select(table, [{{{year, month, day}, :_}, [], [:"$_"]}])
    |> Enum.sort()
    |> Enum.map(fn {erl_date, event} -> {Date.from_erl!(erl_date), event} end)
  end
end
