defmodule NanNoHi.Utils do
  @moduledoc """
  Utilities.
  """

  @doc """
  Converts the given string to an Erlang date tuple.

  ### Examples

  ```
  iex> NanNoHi.Utils.string_to_erl_date("2025-01-01")
  {:ok, {2025, 1, 1}}

  iex> NanNoHi.Utils.string_to_erl_date("2025/01/01")
  {:ok, {2025, 1, 1}}

  iex> NanNoHi.Utils.string_to_erl_date("2025/1/1")
  {:ok, {2025, 1, 1}}

  iex> NanNoHi.Utils.string_to_erl_date("20250101")
  {:ok, {2025, 1, 1}}

  iex> NanNoHi.Utils.string_to_erl_date("20250229") # invalid date
  {:error, "20250229"}

  iex> NanNoHi.Utils.string_to_erl_date("Jan 1st, 2025") # invalid format
  {:error, "Jan 1st, 2025"}
  ```
  """
  @spec string_to_erl_date(String.t()) :: {:ok, :calendar.date()} | {:error, String.t()}
  def string_to_erl_date(string) do
    with [year_s, month_s, day_s] <- parse_date_string(string),
         {year, ""} <- Integer.parse(year_s),
         {month, ""} <- Integer.parse(month_s),
         {day, ""} <- Integer.parse(day_s),
         true <- year > 0,
         true <- :calendar.valid_date(year, month, day) do
      {:ok, {year, month, day}}
    else
      _ ->
        {:error, string}
    end
  end

  defp parse_date_string(string) do
    Regex.run(
      ~r/\A(?<year>\d{1,4})(?<sep>[-\/]?)(?<month>\d{1,2})(\k<sep>)(?<day>\d{1,2})\z/,
      string,
      capture: ~w(year month day)
    )
  end
end
