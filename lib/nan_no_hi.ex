defmodule NanNoHi do
  @moduledoc """
  A interface of NanNoHi.
  """

  alias NanNoHi.Server

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(options \\ []) do
    Server.start_link(options)
  end

  def lookup(pid, year) do
    Server.lookup(pid, year)
  end

  def lookup(pid, year, month) do
    Server.lookup(pid, year, month)
  end

  def lookup(pid, year, month, day) do
    Server.lookup(pid, year, month, day)
  end
end
