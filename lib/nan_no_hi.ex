defmodule NanNoHi do
  @moduledoc """
  A interface of NanNoHi.
  """

  alias NanNoHi.Server

  @type year :: pos_integer()
  @type month :: 1..12
  @type day :: 1..31
  @type event :: term()
  @type events :: [{:calendar.date(), event()}]
  @type options() :: keyword()

  @doc """
  Starts NanNoHi server.
  """
  @spec start_link(options()) :: GenServer.on_start()
  defdelegate start_link(options \\ []), to: Server

  @doc """
  Looks date events up.

  See `lookup/4`.
  """
  @spec lookup(pid(), integer() | Date.t()) :: [{Date.t(), event()}]
  def lookup(pid, year_or_date)

  def lookup(pid, %Date{} = date) do
    {year, month, day} = Date.to_erl(date)

    lookup(pid, year, month, day)
  end

  defdelegate lookup(pid, year), to: Server

  @doc """
  Looks date events up.

  See `lookup/4`.
  """
  @spec lookup(pid(), year(), month()) :: [{Date.t(), event()}]
  defdelegate lookup(pid, year, month), to: Server

  @doc """
  Looks date events up.

  ### Examples

  From a list:

  ```elixir
  iex> {:ok, pid} = NanNoHi.start_link()
  iex> NanNoHi.import(pid, [
  ...>   {{2025, 1, 1}, "元日"},
  ...>   {{2025, 5, 3}, "憲法記念日"},
  ...>   {{2025, 5, 5}, "こどもの日"}
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
  """
  @spec lookup(pid(), year(), month(), day()) :: [{Date.t(), event()}]
  defdelegate lookup(pid, year, month, day), to: Server

  @doc """
  Appends a new event.

  See `append/5`.
  """
  @spec append(pid(), Date.t(), event()) :: :ok
  def append(pid, date, event) when is_struct(date, Date) do
    {year, month, day} = Date.to_erl(date)

    append(pid, year, month, day, event)
  end

  @doc """
  Appends a new event.
  """
  @spec append(pid(), year(), month(), day(), event()) :: :ok
  defdelegate append(pid, year, month, day, event), to: Server

  @spec import(pid(), events()) :: :ok | {:error, term()}
  defdelegate import(pid, events), to: Server
end
