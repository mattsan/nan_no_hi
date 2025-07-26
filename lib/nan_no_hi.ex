defmodule NanNoHi do
  @moduledoc """
  An interface for NanNoHi.
  """

  alias NanNoHi.Import
  alias NanNoHi.State

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
  Creates new table.
  """
  @spec new(list()) :: State.t()
  def new(options \\ []) when is_list(options) do
    name = Keyword.get(options, :name, __MODULE__)
    table = :ets.new(name, [:bag])
    State.new(table: table)
  end

  @doc """
  Appends a new event using a `Date.t()` and description.

  `append(table, ~D[2025-07-15], "Tuesday")` is equivalent to `append(table, 2025, 7, 15, "Tuesday")`.

  See `append/5` for the version that takes year, month, day, and description separately.

  ## Examples

  ```elixir
  iex> table = NanNoHi.new()
  iex> NanNoHi.append(table, ~D[2025-01-01], "元日")
  iex> NanNoHi.append(table, ~D[2025-05-05], "こどもの日")
  iex> NanNoHi.lookup(table, 2025)
  [{~D[2025-01-01], "元日"}, {~D[2025-05-05], "こどもの日"}]
  ```
  """
  @spec append(State.t(), Date.t(), term()) :: :ok
  def append(%State{} = state, date, description) when is_struct(date, Date) do
    :ets.insert(state.table, {Date.to_erl(date), description})
    :ok
  end

  @doc """
  Appends a new event.

  ## Examples

  ```elixir
  iex> table = NanNoHi.new()
  iex> NanNoHi.append(table, 2025, 1, 1, "元日")
  :ok
  iex> NanNoHi.append(table, 2025, 5, 5, "こどもの日")
  :ok
  iex> NanNoHi.lookup(table, 2025)
  [{~D[2025-01-01], "元日"}, {~D[2025-05-05], "こどもの日"}]
  ```

  ```elixir
  iex> table = NanNoHi.new()
  iex> NanNoHi.append(table, 2025, 13, 31, "INVALID")
  {:error, :invalid_date}
  iex> NanNoHi.append(table, 2025, 12, 32, "INVALID")
  {:error, :invalid_date}
  iex> NanNoHi.append(table, 2025, 2, 29, "INVALID")
  {:error, :invalid_date}
  ```
  """
  @spec append(State.t(), year(), month(), day(), term()) :: :ok | {:error, :invalid_date}
  def append(%State{} = state, year, month, day, description) do
    if is_date(year, month, day) && :calendar.valid_date(year, month, day) do
      :ets.insert(state.table, {{year, month, day}, description})
      :ok
    else
      {:error, :invalid_date}
    end
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
  @spec import(State.t(), events() | String.t()) :: :ok | {:error, term()}
  def import(%State{} = state, input) when is_list(input) or is_binary(input) do
    cond do
      is_list(input) -> Import.import_list(input)
      is_binary(input) -> Import.import_csv(input)
    end
    |> case do
      {:ok, events} ->
        Enum.each(events, &:ets.insert(state.table, &1))

        :ok

      error ->
        error
    end
  end

  @doc """
  Looks up events for a given year or date.

  See `lookup/4`.
  """
  @spec lookup(State.t(), integer() | Date.t()) :: events()
  def lookup(state, year_or_date)

  def lookup(%State{} = state, %Date{} = date) do
    {year, month, day} = Date.to_erl(date)

    lookup_events(state, year, month, day)
  end

  def lookup(%State{} = state, year) when is_date(year) do
    lookup_events(state, year, :_, :_)
  end

  @doc """
  Looks up events for a given year and month.

  See `lookup/4`.
  """
  @spec lookup(State.t(), year(), month()) :: events()
  def lookup(%State{} = state, year, month) when is_date(year, month) do
    lookup_events(state, year, month, :_)
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
  @spec lookup(State.t(), year(), month(), day()) :: events()
  def lookup(%State{} = state, year, month, day) when is_date(year, month, day) do
    lookup_events(state, year, month, day)
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
  @spec lookup_all(State.t()) :: events()
  def lookup_all(%State{} = state) do
    lookup_events(state, :_, :_, :_)
  end

  @doc """
  Clears all events.

  ## Examples

  ```elixir
  iex> table = NanNoHi.new()
  iex> NanNoHi.append(table, 2025, 1, 1, "元日")
  iex> NanNoHi.append(table, 2025, 5, 5, "こどもの日")
  iex> NanNoHi.lookup_all(table)
  [{~D[2025-01-01], "元日"}, {~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.clear(table)
  :ok
  iex> NanNoHi.lookup_all(table)
  []
  ```
  """
  @spec clear(State.t()) :: :ok
  def clear(%State{} = state) do
    :ets.delete_all_objects(state.table)

    :ok
  end

  defp lookup_events(%State{} = state, year, month, day) do
    :ets.select(state.table, [{{{year, month, day}, :_}, [], [:"$_"]}])
    |> Enum.sort()
    |> Enum.map(fn {erl_date, description} -> {Date.from_erl!(erl_date), description} end)
  end
end
