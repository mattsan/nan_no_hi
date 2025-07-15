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
    {:ok, %{}}
  end

  @impl true
  def handle_call({:lookup, year}, _from, state) do
    result = lookup_dates(year, :_, :_)

    {:reply, {:ok, result}, state}
  end

  @impl true
  def handle_call({:lookup, year, month}, _from, state) do
    result = lookup_dates(year, month, :_)

    {:reply, {:ok, result}, state}
  end

  @impl true
  def handle_call({:lookup, year, month, day}, _from, state) do
    result = lookup_dates(year, month, day)

    {:reply, {:ok, result}, state}
  end

  defp lookup_dates(year, month, day) do
    [{{year, month, day}, "dummy"}]
  end
end
