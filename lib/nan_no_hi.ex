defmodule NanNoHi do
  @moduledoc """
  An interface for NanNoHi.
  """

  defstruct [:table]

  @opaque t() :: %__MODULE__{table: :ets.table()}

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
  Creates new object.
  """
  @spec new(list()) :: t()
  def new(options \\ []) when is_list(options) do
    name = Keyword.get(options, :name, __MODULE__)
    table = :ets.new(name, [:bag])
    %__MODULE__{table: table}
  end

  @doc """
  Appends a new event using a `Date.t()` and description.

  `append(nan_no_hi, ~D[2025-07-15], "Tuesday")` is equivalent to `append(nan_no_hi, 2025, 7, 15, "Tuesday")`.

  See `append/5` for the version that takes year, month, day, and description separately.

  ## Examples

  ```elixir
  iex> nan_no_hi = NanNoHi.new()
  iex> NanNoHi.append(nan_no_hi, ~D[2025-01-01], "元日")
  iex> NanNoHi.append(nan_no_hi, ~D[2025-05-05], "こどもの日")
  iex> NanNoHi.lookup(nan_no_hi, 2025)
  [{~D[2025-01-01], "元日"}, {~D[2025-05-05], "こどもの日"}]
  ```
  """
  @spec append(t(), Date.t(), term()) :: :ok
  def append(%__MODULE__{} = nan_no_hi, date, description) when is_struct(date, Date) do
    :ets.insert(nan_no_hi.table, {Date.to_erl(date), description})
    :ok
  end

  @doc """
  Appends a new event.

  ## Examples

  ```elixir
  iex> nan_no_hi = NanNoHi.new()
  iex> NanNoHi.append(nan_no_hi, 2025, 1, 1, "元日")
  :ok
  iex> NanNoHi.append(nan_no_hi, 2025, 5, 5, "こどもの日")
  :ok
  iex> NanNoHi.lookup(nan_no_hi, 2025)
  [{~D[2025-01-01], "元日"}, {~D[2025-05-05], "こどもの日"}]
  ```

  ```elixir
  iex> nan_no_hi = NanNoHi.new()
  iex> NanNoHi.append(nan_no_hi, 2025, 13, 31, "INVALID")
  {:error, :invalid_date}
  iex> NanNoHi.append(nan_no_hi, 2025, 12, 32, "INVALID")
  {:error, :invalid_date}
  iex> NanNoHi.append(nan_no_hi, 2025, 2, 29, "INVALID")
  {:error, :invalid_date}
  ```
  """
  @spec append(t(), year(), month(), day(), term()) :: :ok | {:error, :invalid_date}
  def append(%__MODULE__{} = nan_no_hi, year, month, day, description) do
    if is_date(year, month, day) && :calendar.valid_date(year, month, day) do
      :ets.insert(nan_no_hi.table, {{year, month, day}, description})
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
  iex> nan_no_hi = NanNoHi.new()
  iex> NanNoHi.import(nan_no_hi, [
  ...>   {~D[2025-01-01], "元日"},
  ...>   {~D[2025-05-03], "憲法記念日"},
  ...>   {~D[2025-05-05], "こどもの日"}
  ...> ])
  iex> NanNoHi.lookup(nan_no_hi, 2025)
  [{~D[2025-01-01], "元日"}, {~D[2025-05-03], "憲法記念日"}, {~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.lookup(nan_no_hi, 2025, 5)
  [{~D[2025-05-03], "憲法記念日"}, {~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.lookup(nan_no_hi, 2025, 5, 5)
  [{~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.lookup(nan_no_hi, ~D[2025-01-01])
  [{~D[2025-01-01], "元日"}]
  ```

  From CSV string:

  ```elixir
  iex> nan_no_hi = NanNoHi.new()
  iex> NanNoHi.import(nan_no_hi, \"""
  ...> date,event
  ...> 2025/1/1,元日
  ...> 2025/5/3,憲法記念日
  ...> 2025/5/5,こどもの日
  ...> \""")
  iex> NanNoHi.lookup(nan_no_hi, 2025)
  [{~D[2025-01-01], "元日"}, {~D[2025-05-03], "憲法記念日"}, {~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.lookup(nan_no_hi, 2025, 5)
  [{~D[2025-05-03], "憲法記念日"}, {~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.lookup(nan_no_hi, 2025, 5, 5)
  [{~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.lookup(nan_no_hi, ~D[2025-01-01])
  [{~D[2025-01-01], "元日"}]
  ```

  Invalid input:

  ```elixir
  iex> nan_no_hi = NanNoHi.new()
  iex> NanNoHi.import(nan_no_hi, \"""
  ...> date,event
  ...> 2024/1/1,元日
  ...> Jan 1st 2025,元日
  ...> \""")
  {:error, ["Jan 1st 2025"]}
  ```
  """
  @spec import(t(), events() | String.t()) :: :ok | {:error, term()}
  def import(%__MODULE__{} = nan_no_hi, input) when is_list(input) or is_binary(input) do
    cond do
      is_list(input) -> Import.import_list(input)
      is_binary(input) -> Import.import_csv(input)
    end
    |> case do
      {:ok, events} ->
        Enum.each(events, &:ets.insert(nan_no_hi.table, &1))

        :ok

      error ->
        error
    end
  end

  @doc """
  Looks up events for a given year or date.

  See `lookup/4`.
  """
  @spec lookup(t(), integer() | Date.t()) :: events()
  def lookup(nan_no_hi, year_or_date)

  def lookup(%__MODULE__{} = nan_no_hi, %Date{} = date) do
    {year, month, day} = Date.to_erl(date)

    lookup_events(nan_no_hi, year, month, day)
  end

  def lookup(%__MODULE__{} = nan_no_hi, year) when is_date(year) do
    lookup_events(nan_no_hi, year, :_, :_)
  end

  @doc """
  Looks up events for a given year and month.

  See `lookup/4`.
  """
  @spec lookup(t(), year(), month()) :: events()
  def lookup(%__MODULE__{} = nan_no_hi, year, month) when is_date(year, month) do
    lookup_events(nan_no_hi, year, month, :_)
  end

  @doc """
  Looks up events for a specific date.

  ## Examples

  ```elixir
  iex> nan_no_hi = NanNoHi.new()
  iex> NanNoHi.import(nan_no_hi, [
  ...>   {~D[2025-01-01], "元日"},
  ...>   {~D[2025-05-03], "憲法記念日"},
  ...>   {~D[2025-05-05], "こどもの日"}
  ...> ])
  iex> NanNoHi.lookup(nan_no_hi, 2025)
  [{~D[2025-01-01], "元日"}, {~D[2025-05-03], "憲法記念日"}, {~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.lookup(nan_no_hi, 2025, 5)
  [{~D[2025-05-03], "憲法記念日"}, {~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.lookup(nan_no_hi, 2025, 5, 5)
  [{~D[2025-05-05], "こどもの日"}]
  ```
  """
  @spec lookup(t(), year(), month(), day()) :: events()
  def lookup(%__MODULE__{} = nan_no_hi, year, month, day) when is_date(year, month, day) do
    lookup_events(nan_no_hi, year, month, day)
  end

  @doc """
  Looks up all events.

  ## Examples

  ```elixir
  iex> nan_no_hi = NanNoHi.new()
  iex> NanNoHi.append(nan_no_hi, 2023, 1, 1, "元日")
  iex> NanNoHi.append(nan_no_hi, 2024, 1, 1, "元日")
  iex> NanNoHi.append(nan_no_hi, 2025, 1, 1, "元日")
  iex> NanNoHi.lookup_all(nan_no_hi)
  [{~D[2023-01-01], "元日"}, {~D[2024-01-01], "元日"}, {~D[2025-01-01], "元日"}]
  ```
  """
  @spec lookup_all(t()) :: events()
  def lookup_all(%__MODULE__{} = nan_no_hi) do
    lookup_events(nan_no_hi, :_, :_, :_)
  end

  @doc """
  Clears all events.

  ## Examples

  ```elixir
  iex> nan_no_hi = NanNoHi.new()
  iex> NanNoHi.append(nan_no_hi, 2025, 1, 1, "元日")
  iex> NanNoHi.append(nan_no_hi, 2025, 5, 5, "こどもの日")
  iex> NanNoHi.lookup_all(nan_no_hi)
  [{~D[2025-01-01], "元日"}, {~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.clear(nan_no_hi)
  :ok
  iex> NanNoHi.lookup_all(nan_no_hi)
  []
  ```
  """
  @spec clear(t()) :: :ok
  def clear(%__MODULE__{} = nan_no_hi) do
    :ets.delete_all_objects(nan_no_hi.table)

    :ok
  end

  defp lookup_events(%__MODULE__{} = nan_no_hi, year, month, day) do
    :ets.select(nan_no_hi.table, [{{{year, month, day}, :_}, [], [:"$_"]}])
    |> Enum.sort()
    |> Enum.map(fn {erl_date, description} -> {Date.from_erl!(erl_date), description} end)
  end
end
