defmodule NanNoHi do
  @moduledoc """
  A interface of NanNoHi.
  """

  alias NanNoHi.Server

  @type year :: integer()
  @type month :: 1..12
  @type day :: 1..31
  @type event :: term()

  @doc """
  Starts NanNoHi server.
  """
  @spec start_link(Keyword.t()) :: GenServer.on_start()
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
end
