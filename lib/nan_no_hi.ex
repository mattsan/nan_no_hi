defmodule NanNoHi do
  @moduledoc """
  An interface for NanNoHi.
  """

  alias NanNoHi.Server

  @type year :: pos_integer()
  @type month :: 1..12
  @type day :: 1..31
  @type event :: {Date.t(), term()}
  @type events :: [event]
  @type options() :: keyword()

  @doc """
  Starts NanNoHi server.
  """
  @spec start_link(options()) :: GenServer.on_start()
  defdelegate start_link(options \\ []), to: Server

  @doc """
  Appends a new event using a `Date.t()` and description.

  `append(pid, ~D[2025-07-15], "Tuesday")` is equivalent to `append(pid, 2025, 7, 15, "Tuesday")`.

  See `append/5` for the version that takes year, month, day, and description separately.
  """
  @spec append(pid(), Date.t(), term()) :: :ok
  def append(pid, date, description) when is_struct(date, Date) do
    {year, month, day} = Date.to_erl(date)

    append(pid, year, month, day, description)
  end

  @doc """
  Appends a new event.
  """
  @spec append(pid(), year(), month(), day(), term()) :: :ok
  defdelegate append(pid, year, month, day, description), to: Server

  @doc """
  Imports multiple events from a list or a CSV string.

  Accepts either a list of events (e.g., `[{~D[2025-01-01], "元日"}]`) or a CSV string.

  ## Examples

  From a list:

  ```elixir
  iex> {:ok, pid} = NanNoHi.start_link()
  iex> NanNoHi.import(pid, [
  ...>   {~D[2025-01-01], "元日"},
  ...>   {~D[2025-05-03], "憲法記念日"},
  ...>   {~D[2025-05-05], "こどもの日"}
  ...> ])
  iex> NanNoHi.lookup(pid, 2025)
  [{~D[2025-01-01], "元日"}, {~D[2025-05-03], "憲法記念日"}, {~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.lookup(pid, 2025, 5)
  [{~D[2025-05-03], "憲法記念日"}, {~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.lookup(pid, 2025, 5, 5)
  [{~D[2025-05-05], "こどもの日"}]
  ```

  From CSV string:

  ```elixir
  iex> {:ok, pid} = NanNoHi.start_link()
  iex> NanNoHi.import(pid, \"""
  ...> date,event
  ...> 2025/1/1,元日
  ...> 2025/5/3,憲法記念日
  ...> 2025/5/5,こどもの日
  ...> \""")
  iex> NanNoHi.lookup(pid, 2025)
  [{~D[2025-01-01], "元日"}, {~D[2025-05-03], "憲法記念日"}, {~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.lookup(pid, 2025, 5)
  [{~D[2025-05-03], "憲法記念日"}, {~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.lookup(pid, 2025, 5, 5)
  [{~D[2025-05-05], "こどもの日"}]
  ```

  Invalid input:

  ```elixir
  iex> {:ok, pid} = NanNoHi.start_link()
  iex> NanNoHi.import(pid, \"""
  ...> date,event
  ...> 2024/1/1,元日
  ...> Jan 1st 2025,元日
  ...> \""")
  {:error, ["Jan 1st 2025"]}
  ```
  """
  @spec import(pid(), events() | String.t()) :: :ok | {:error, term()}
  defdelegate import(pid, events_or_string), to: Server

  @doc """
  Looks up events for a given year or date.

  See `lookup/4`.
  """
  @spec lookup(pid(), integer() | Date.t()) :: events()
  def lookup(pid, year_or_date)

  def lookup(pid, %Date{} = date) do
    {year, month, day} = Date.to_erl(date)

    lookup(pid, year, month, day)
  end

  defdelegate lookup(pid, year), to: Server

  @doc """
  Looks up events for a given year and month.

  See `lookup/4`.
  """
  @spec lookup(pid(), year(), month()) :: events()
  defdelegate lookup(pid, year, month), to: Server

  @doc """
  Looks up events for a specific date.

  ## Examples

  ```elixir
  iex> {:ok, pid} = NanNoHi.start_link()
  iex> NanNoHi.import(pid, [
  ...>   {~D[2025-01-01], "元日"},
  ...>   {~D[2025-05-03], "憲法記念日"},
  ...>   {~D[2025-05-05], "こどもの日"}
  ...> ])
  iex> NanNoHi.lookup(pid, 2025)
  [{~D[2025-01-01], "元日"}, {~D[2025-05-03], "憲法記念日"}, {~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.lookup(pid, 2025, 5)
  [{~D[2025-05-03], "憲法記念日"}, {~D[2025-05-05], "こどもの日"}]
  iex> NanNoHi.lookup(pid, 2025, 5, 5)
  [{~D[2025-05-05], "こどもの日"}]
  ```
  """
  @spec lookup(pid(), year(), month(), day()) :: events()
  defdelegate lookup(pid, year, month, day), to: Server

  @doc """
  Looks up all events.

  ## Examples

  ```elixir
  iex> {:ok, pid} = NanNoHi.start_link()
  iex> NanNoHi.append(pid, 2023, 1, 1, "元日")
  iex> NanNoHi.append(pid, 2024, 1, 1, "元日")
  iex> NanNoHi.append(pid, 2025, 1, 1, "元日")
  iex> NanNoHi.lookup_all(pid)
  [{~D[2023-01-01], "元日"}, {~D[2024-01-01], "元日"}, {~D[2025-01-01], "元日"}]
  ```
  """
  @spec lookup_all(pid()) :: events()
  defdelegate lookup_all(pid), to: Server

  @doc """
  Clears all events.
  """
  @spec clear(pid()) :: :ok
  defdelegate clear(pid), to: Server
end
