defmodule NanNoHi.State do
  @moduledoc """
  A state of NanNoHi.
  """

  defstruct [:table]

  @opaque t() :: %__MODULE__{table: :ets.table()}

  @doc """
  Creates a new state struct.
  """
  @spec new(keyword()) :: t()
  def new(options) do
    table = Keyword.get(options, :table)
    %__MODULE__{table: table}
  end
end
