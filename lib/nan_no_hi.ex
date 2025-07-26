defmodule NanNoHi do
  @moduledoc """
  An interface for NanNoHi.
  """

  alias NanNoHi.Import

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
  @spec new(list()) :: :ets.table()
  def new(options \\ []) when is_list(options) do
    name = Keyword.get(options, :name, __MODULE__)
    :ets.new(name, [:bag])
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
  @spec append(:ets.table(), Date.t(), term()) :: :ok
  def append(table, date, description) when is_struct(date, Date) do
    {year, month, day} = Date.to_erl(date)

    append(table, year, month, day, description)
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
  @spec append(:ets.table(), year(), month(), day(), term()) :: :ok | {:error, :invalid_date}
  def append(table, year, month, day, description) do
    if is_date(year, month, day) && :calendar.valid_date(year, month, day) do
      :ets.insert(table, {{year, month, day}, description})
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
  @spec import(:ets.table(), events() | String.t()) :: :ok | {:error, term()}
  def import(table, input) when is_list(input) or is_binary(input) do
    cond do
      is_list(input) -> Import.import_list(input)
      is_binary(input) -> Import.import_csv(input)
    end
    |> case do
      {:ok, events} ->
        Enum.each(events, &:ets.insert(table, &1))

        :ok

      error ->
        error
    end
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
