# Japanese Holidays
#
# This is an Elixir script to display Japanese holidays.
#
# Usage:
#   # Show all holidays in 2025
#   $ elixir examples/japanese_holidays.exs 2025
#
#   # Show all holidays in January 2025
#   $ elixir examples/japanese_holidays.exs 2025 1
#
#   # Show the holiday on January 1st, 2025
#   $ elixir examples/japanese_holidays.exs 2025 1 1
#
# See also:
# - [「国民の祝日」について - 内閣府](https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html) (About "National Holidays" - Cabinet Office) (Japanese)
# - [CSV data](https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv) (from 1955 to the next year)

# Install packages
# - req: HTTP client library for downloading CSV data
# - iconv: Character encoding conversion (Shift_JIS to UTF-8)
# - nan_no_hi: Date event management library (local path)
Mix.install([
  {:req, "~> 0.5"},
  {:iconv, "~> 1.0"},
  {:nan_no_hi, path: "."}
])

# GenServer-based module to manage Japanese holidays data
defmodule JapaneseHolidays do
  use GenServer

  # URL of the official Japanese national holidays CSV file from the Cabinet Office
  # This file is updated annually and contains holiday data from 1955 onwards
  @csv_url "https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv"

  # Start the GenServer with fetched CSV data
  def start_link(_ \\ []) do
    csv = fetch_csv()

    GenServer.start_link(__MODULE__, csv, name: __MODULE__)
  end

  # Public API functions for looking up holidays
  def lookup(year), do: GenServer.call(__MODULE__, {:lookup, {year}})
  def lookup(year, month), do: GenServer.call(__MODULE__, {:lookup, {year, month}})
  def lookup(year, month, day), do: GenServer.call(__MODULE__, {:lookup, {year, month, day}})

  # Initialize GenServer state with holidays data
  def init(csv) do
    nan_no_hi = NanNoHi.new(name: __MODULE__)

    # Import CSV data
    NanNoHi.import(nan_no_hi, csv)

    {:ok, nan_no_hi}
  end

  # Handle lookup requests based on date granularity
  def handle_call({:lookup, date}, _from, nan_no_hi) do
    result =
      case date do
        {year} -> NanNoHi.lookup(nan_no_hi, year)
        {year, month} -> NanNoHi.lookup(nan_no_hi, year, month)
        {year, month, day} -> NanNoHi.lookup(nan_no_hi, year, month, day)
      end

    {:reply, result, nan_no_hi}
  end

  # Fetch Japanese holidays CSV data from Cabinet Office website
  defp fetch_csv do
    {:ok, uri} = URI.new(@csv_url)
    filename = Path.basename(uri.path)

    # Use cached file if it exists, otherwise download
    if File.exists?(filename) do
      File.read!(filename)
    else
      # Download CSV (raw mode to handle binary data)
      # Convert from Shift_JIS (cp932) to UTF-8 encoding
      csv = uri |> Req.get!(raw: true) |> Map.get(:body) |> shift_jis_to_utf8()

      # Cache the file locally
      File.write!(filename, csv)

      csv
    end
  end

  # Convert text from Shift_JIS (CP932) encoding to UTF-8
  # Japanese government websites often use Shift_JIS encoding for CSV files
  # CP932 is Microsoft's implementation of Shift_JIS with additional characters
  defp shift_jis_to_utf8(string) do
    :iconv.convert("cp932", "utf-8", string)
  end
end

# Command-line argument parser module
defmodule ArgumentParser do
  # Parse command-line arguments and validate them as integers
  def parse(args) do
    case Enum.map(args, &Integer.parse/1) do
      # Three arguments: year, month, and day
      [{year, ""}, {month, ""}, {day, ""}] ->
        {:ok, JapaneseHolidays.lookup(year, month, day)}

      # Two arguments: year and month
      [{year, ""}, {month, ""}] ->
        {:ok, JapaneseHolidays.lookup(year, month)}

      # One argument: year only
      [{year, ""}] ->
        {:ok, JapaneseHolidays.lookup(year)}

      # Invalid arguments
      _ ->
        {:error, error_message(args)}
    end
  end

  # Generate error message for invalid arguments
  defp error_message(args) do
    """
    Invalid arguments #{inspect(args)}

    usage: elixir examples/japanese_holidays.exs <year> [<month> [<day>]]
    """
  end
end

# Start the JapaneseHolidays GenServer
{:ok, _} = JapaneseHolidays.start_link()

# Process command-line arguments and display results
System.argv()
|> ArgumentParser.parse()
|> case do
  # No holidays found for the given date
  {:ok, []} ->
    IO.puts("No holidays found")

  # Display found holidays
  {:ok, holidays} ->
    holidays
    |> Enum.each(fn {date, description} ->
      IO.puts("#{date} #{description}")
    end)

  # Display error message for invalid arguments
  {:error, reason} ->
    IO.puts(reason)
end
