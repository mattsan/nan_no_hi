defmodule NanNoHi.Server do
  @moduledoc """
  Server module for NanNoHi.

  ## Examples

  Start the NanNoHi server as part of your application supervision tree:

  ```elixir
  defmodule MyApp.Application do
    @moduledoc false

    use Application

    @impl true
    def start(_type, _args) do
      children = [
        {NanNoHi.Server, name: JapaneseHoliday}
      ]

      opts = [strategy: :one_for_one, name: MyApp.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end
  ```

  Looks up.

  ```elixir
  NanNoHi.lookup(JapaneseHoliday, 2025)
  #=> [{~D[2025-01-01], "元日"}, ...]
  ```
  """
  use GenServer

  defguard is_date(year) when is_integer(year) and year > 0
  defguard is_date(year, month) when is_date(year) and month in 1..12
  defguard is_date(year, month, day) when is_date(year, month) and day in 1..31

  import NanNoHi.Utils, only: [parse_input: 1]

  @server_option_keys []

  @spec start_link(NanNoHi.options()) :: GenServer.on_start()
  def start_link(options) do
    {server_options, gen_server_options} = Keyword.split(options, @server_option_keys)

    GenServer.start_link(__MODULE__, server_options, gen_server_options)
  end

  @spec append(pid(), NanNoHi.year(), NanNoHi.month(), NanNoHi.day(), term()) ::
          :ok | {:error, term()}
  def append(pid, year, month, day, description) when is_date(year, month, day) do
    GenServer.call(pid, {:append, year, month, day, description})
  end

  @spec import(pid(), NanNoHi.events() | String.t()) :: :ok | {:error, term()}
  def import(pid, events_or_string) do
    GenServer.call(pid, {:import, events_or_string})
  end

  @spec lookup(pid(), NanNoHi.year()) :: NanNoHi.events()
  def lookup(pid, year) when is_date(year) do
    GenServer.call(pid, {:lookup, year})
  end

  @spec lookup(pid(), NanNoHi.year(), NanNoHi.month()) :: NanNoHi.events()
  def lookup(pid, year, month) when is_date(year, month) do
    GenServer.call(pid, {:lookup, year, month})
  end

  @spec lookup(pid(), NanNoHi.year(), NanNoHi.month(), NanNoHi.day()) :: NanNoHi.events()
  def lookup(pid, year, month, day) when is_date(year, month, day) do
    GenServer.call(pid, {:lookup, year, month, day})
  end

  @spec lookup_all(pid()) :: NanNoHi.events()
  def lookup_all(pid) do
    GenServer.call(pid, :lookup_all)
  end

  @spec clear(pid()) :: :ok
  def clear(pid) do
    GenServer.call(pid, :clear)
  end

  @impl true
  @spec init(keyword()) :: {:ok, map()}
  def init(_) do
    table = :ets.new(__MODULE__, [:bag])

    {:ok, %{table: table}}
  end

  @impl true
  def handle_call({:append, year, month, day, description}, _from, state) do
    :ets.insert(state.table, {{year, month, day}, description})

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:import, input}, _from, state) do
    with {:ok, events} <- parse_input(input) do
      import_events(events, state.table)
      {:reply, :ok, state}
    else
      error ->
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call({:lookup, year}, _from, state) do
    result = lookup_events(state.table, year, :_, :_)

    {:reply, result, state}
  end

  @impl true
  def handle_call({:lookup, year, month}, _from, state) do
    result = lookup_events(state.table, year, month, :_)

    {:reply, result, state}
  end

  @impl true
  def handle_call({:lookup, year, month, day}, _from, state) do
    result = lookup_events(state.table, year, month, day)

    {:reply, result, state}
  end

  @impl true
  def handle_call(:clear, _from, state) do
    :ets.delete_all_objects(state.table)

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:lookup_all, _from, state) do
    events = lookup_events(state.table, :_, :_, :_)

    {:reply, events, state}
  end

  defp import_events(events, table) do
    events
    |> Enum.each(fn event ->
      case event do
        {%Date{} = date, description} -> {{date.year, date.month, date.day}, description}
        {{_, _, _}, _} = event -> event
      end
      |> then(&:ets.insert(table, &1))
    end)
  end

  defp lookup_events(table, year, month, day) do
    :ets.select(table, [{{{year, month, day}, :_}, [], [:"$_"]}])
    |> Enum.sort()
    |> Enum.map(fn {erl_date, description} -> {Date.from_erl!(erl_date), description} end)
  end
end
