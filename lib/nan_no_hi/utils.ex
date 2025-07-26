defmodule NanNoHi.Utils do
  @moduledoc """
  Utility functions for NanNoHi event management.

  This module provides functions for importing events from various formats
  (lists and CSV), parsing date strings, and handling errors during import.
  """

  NimbleCSV.define(CsvParser, moduledoc: false)

  defguardp is_pos_int(n) when is_integer(n) and n > 0

  @doc """
  Imports events from a list of date-description tuples.

  Accepts a list where each element is a tuple containing a date and description.
  Dates can be either Date structs or Erlang date tuples `{year, month, day}`.
  Returns `{:ok, events}` on success or `{:error, invalid_items}` if any items are invalid.

  ## Examples

  ```elixir
  iex> NanNoHi.Utils.import_list([
  ...>   {{2025, 1, 1}, "元日"},
  ...>   {{2025, 5, 5}, "子供の日"}
  ...> ])
  {:ok, [{{2025, 1, 1}, "元日"}, {{2025, 5, 5}, "子供の日"}]}
  ```

  ```elixir
  iex> NanNoHi.Utils.import_list([
  ...>   {~D[2025-01-01], "元日"},
  ...>   {~D[2025-05-05], "子供の日"}
  ...> ])
  {:ok, [{{2025, 1, 1}, "元日"}, {{2025, 5, 5}, "子供の日"}]}
  ```
  """
  @spec import_list(list()) :: {:ok, NanNoHi.events()} | {:error, term()}
  def import_list(input) when is_list(input) do
    input
    |> Enum.map(fn
      {%Date{} = date, description} ->
        {:ok, {Date.to_erl(date), description}}

      {{y, m, d} = date, description} when is_pos_int(y) and is_pos_int(m) and is_pos_int(d) ->
        if :calendar.valid_date(date) do
          {:ok, {date, description}}
        else
          {:error, date}
        end

      {date, _description} ->
        {:error, date}

      another ->
        {:error, another}
    end)
    |> split_errors()
  end

  @doc """
  Imports events from a CSV string.

  Expects a CSV with two columns: date and event description.
  The first row is treated as a header and ignored.
  Supported date formats: YYYY-MM-DD, YYYY/MM/DD, YYYY/M/D, YYYYMMDD.
  Returns `{:ok, events}` on success or `{:error, invalid_dates}` if any dates cannot be parsed.

  ## Examples

  ```elixir
  iex> NanNoHi.Utils.import_csv(\"""
  ...> date,event
  ...> 2025/01/01,元日
  ...> 2025/05/05,子供の日
  ...> \""")
  {:ok, [{{2025, 1, 1}, "元日"}, {{2025, 5, 5}, "子供の日"}]}
  ```
  """
  @spec import_csv(String.t()) :: {:ok, NanNoHi.events()} | {:error, term()}
  def import_csv(input) when is_binary(input) do
    input
    |> CsvParser.parse_string()
    |> Enum.map(fn
      [string_date, description] ->
        case string_to_erl_date(string_date) do
          {:ok, date} -> {:ok, {date, description}}
          {:error, _} = error -> error
        end

      invalid_row ->
        {:error, invalid_row}
    end)
    |> split_errors()
  end

  @doc """
  Processes a list of `{:ok, value}` and `{:error, reason}` tuples.

  If any errors exist, returns `{:error, [reasons]}` with all error reasons.
  If all items are successful, returns `{:ok, [values]}` with all values.
  An empty list returns `{:ok, []}`.

  ## Examples

  ```elixir
  iex> NanNoHi.Utils.split_errors([ok: "A", ok: "B", ok: "C", ok: "D"])
  {:ok, ["A", "B", "C", "D"]}
  ```

  ```elixir
  iex> NanNoHi.Utils.split_errors([ok: "A", error: "B", ok: "C", error: "D"])
  {:error, ["B", "D"]}
  ```

  ```elixir
  iex> NanNoHi.Utils.split_errors([])
  {:ok, []}
  ```
  """
  @spec split_errors([{:ok | :error, term()}]) :: {:ok, [term()]} | {:error, [term()]}
  def split_errors(result) do
    result
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> then(fn
      %{error: errors} ->
        {:error, errors}

      %{ok: events} ->
        {:ok, events}

      _ ->
        {:ok, []}
    end)
  end

  @doc """
  Converts the given string to an Erlang date tuple.

  ## Examples

  ```elixir
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
