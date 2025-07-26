defmodule NanNoHi do
  @moduledoc """
  An interface for NanNoHi.
  """

  @type year :: pos_integer()
  @type month :: 1..12
  @type day :: 1..31
  @type event :: {Date.t(), term()}
  @type events :: [event]
  @type options() :: keyword()

  defguardp is_date(year) when is_integer(year) and year > 0
  defguardp is_date(year, month) when is_date(year) and month in 1..12
  defguardp is_date(year, month, day) when is_date(year, month) and day in 1..31

  @doc """
  Starts NanNoHi server.
  """
  @spec new(list()) :: :ets.table()
  def new(opts \\ []) when is_list(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    :ets.new(name, [:bag])
  end

  @doc """
  Appends a new event using a `Date.t()` and description.

  `append(table, ~D[2025-07-15], "Tuesday")` is equivalent to `append(table, 2025, 7, 15, "Tuesday")`.

  See `append/5` for the version that takes year, month, day, and description separately.
  """
  @spec append(:ets.table(), Date.t(), term()) :: :ok
  def append(table, date, description) when is_struct(date, Date) do
    {year, month, day} = Date.to_erl(date)

    append(table, year, month, day, description)
  end

  @doc """
  Appends a new event.
  """
  @spec append(:ets.table(), year(), month(), day(), term()) :: :ok
  def append(table, year, month, day, description) when is_date(year, month, day) do
    :ets.insert(table, {{year, month, day}, description})

    :ok
  end

  @doc """
  Imports multiple events from a list or a CSV string.

  Accepts either a list of events (e.g., `[{~D[2025-01-01], "元日"}]`) or a CSV string.

  ## Examples

  From a list:

  ```elixir
  iex> table = NanNoHi.new()
  iex> NanNoHi.import(table, [
  ...>   {~D[2025-01-01], "元日"},
  ...>   {~D[2025-05-03], "憲法記念日"},
  ...>   {~D[2025-05-05], "こどもの日"}
  ...> ])
  iex> NanNoHi.lookup(table, 2025)
  [{~D[2025-01-01], "元日"}, {~D[2025-05-03], "憲法記念日"}, {~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.lookup(table, 2025, 5)
  [{~D[2025-05-03], "憲法記念日"}, {~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.lookup(table, 2025, 5, 5)
  [{~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.lookup(table, ~D[2025-01-01])
  [{~D[2025-01-01], "元日"}]
  ```

  From CSV string:

  ```elixir
  iex> table = NanNoHi.new()
  iex> NanNoHi.import(table, \"""
  ...> date,event
  ...> 2025/1/1,元日
  ...> 2025/5/3,憲法記念日
  ...> 2025/5/5,こどもの日
  ...> \""")
  iex> NanNoHi.lookup(table, 2025)
  [{~D[2025-01-01], "元日"}, {~D[2025-05-03], "憲法記念日"}, {~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.lookup(table, 2025, 5)
  [{~D[2025-05-03], "憲法記念日"}, {~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.lookup(table, 2025, 5, 5)
  [{~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.lookup(table, ~D[2025-01-01])
  [{~D[2025-01-01], "元日"}]
  ```

  Invalid input:

  ```elixir
  iex> table = NanNoHi.new()
  iex> NanNoHi.import(table, \"""
  ...> date,event
  ...> 2024/1/1,元日
  ...> Jan 1st 2025,元日
  ...> \""")
  {:error, ["Jan 1st 2025"]}
  ```
  """
  @spec import(:ets.table(), events() | String.t()) :: :ok | {:error, term()}
  def import(table, events_or_string) do
    with {:ok, events} <- NanNoHi.Utils.parse_input(events_or_string) do
      import_events(events, table)
      :ok
    else
      error ->
        error
    end
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

  @doc """
  Looks up events for a given year or date.

  See `lookup/4`.
  """
  @spec lookup(:ets.table(), integer() | Date.t()) :: events()
  def lookup(table, year_or_date)

  def lookup(table, %Date{} = date) do
    {year, month, day} = Date.to_erl(date)

    lookup(table, year, month, day)
  end

  def lookup(table, year) when is_date(year) do
    lookup_events(table, year, :_, :_)
  end

  @doc """
  Looks up events for a given year and month.

  See `lookup/4`.
  """
  @spec lookup(:ets.table(), year(), month()) :: events()
  def lookup(table, year, month) when is_date(year, month) do
    lookup_events(table, year, month, :_)
  end

  @doc """
  Looks up events for a specific date.

  ## Examples

  ```elixir
  iex> table = NanNoHi.new()
  iex> NanNoHi.import(table, [
  ...>   {~D[2025-01-01], "元日"},
  ...>   {~D[2025-05-03], "憲法記念日"},
  ...>   {~D[2025-05-05], "こどもの日"}
  ...> ])
  iex> NanNoHi.lookup(table, 2025)
  [{~D[2025-01-01], "元日"}, {~D[2025-05-03], "憲法記念日"}, {~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.lookup(table, 2025, 5)
  [{~D[2025-05-03], "憲法記念日"}, {~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.lookup(table, 2025, 5, 5)
  [{~D[2025-05-05], "こどもの日"}]
  ```
  """
  @spec lookup(:ets.table(), year(), month(), day()) :: events()
  def lookup(table, year, month, day) when is_date(year, month, day) do
    lookup_events(table, year, month, day)
  end

  @doc """
  Looks up all events.

  ## Examples

  ```elixir
  iex> table = NanNoHi.new()
  iex> NanNoHi.append(table, 2023, 1, 1, "元日")
  iex> NanNoHi.append(table, 2024, 1, 1, "元日")
  iex> NanNoHi.append(table, 2025, 1, 1, "元日")
  iex> NanNoHi.lookup_all(table)
  [{~D[2023-01-01], "元日"}, {~D[2024-01-01], "元日"}, {~D[2025-01-01], "元日"}]
  ```
  """
  @spec lookup_all(:ets.table()) :: events()
  def lookup_all(table) do
    lookup_events(table, :_, :_, :_)
  end

  @doc """
  Clears all events.
  """
  @spec clear(:ets.table()) :: :ok
  def clear(table) do
    :ets.delete_all_objects(table)

    :ok
  end

  defp lookup_events(table, year, month, day) do
    :ets.select(table, [{{{year, month, day}, :_}, [], [:"$_"]}])
    |> Enum.sort()
    |> Enum.map(fn {erl_date, description} -> {Date.from_erl!(erl_date), description} end)
  end
end
