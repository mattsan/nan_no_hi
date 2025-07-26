# Japanese Holidays
#
# - [「国民の祝日」について - 内閣府](https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html) (About "National Holidays" - Cabinet Office) (Japanese)
# - [CSV data](https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv) (from 1955 to the next year)

# Install packages
Mix.install([
  {:req, "~> 0.5"},
  {:iconv, "~> 1.0"},
  {:nan_no_hi, path: "."}
])

defmodule JapaneseHolidays do
  use GenServer

  def start_link(_ \\ []) do
    csv = fetch_csv()

    GenServer.start_link(__MODULE__, csv, name: __MODULE__)
  end

  def lookup(year), do: GenServer.call(__MODULE__, {:lookup, {year}})
  def lookup(year, month), do: GenServer.call(__MODULE__, {:lookup, {year, month}})
  def lookup(year, month, day), do: GenServer.call(__MODULE__, {:lookup, {year, month, day}})

  def init(csv) do
    # Make a new table
    table = NanNoHi.new(name: __MODULE__)

    NanNoHi.import(table, csv)

    {:ok, %{table: table}}
  end

  def handle_call({:lookup, date}, _from, state) do
    result =
      case date do
        {year} -> NanNoHi.lookup(state.table, year)
        {year, month} -> NanNoHi.lookup(state.table, year, month)
        {year, month, day} -> NanNoHi.lookup(state.table, year, month, day)
      end

    {:reply, result, state}
  end

  defp fetch_csv do
    {:ok, uri} = URI.new("https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv")
    filename = Path.basename(uri.path)

    # Download CSV file if it's not been downloaded
    if File.exists?(filename) do
      File.read!(filename)
    else
      csv = uri |> Req.get!(raw: true) |> then(&:iconv.convert("cp932", "utf-8", &1.body))

      File.write!(filename, csv)

      csv
    end
  end
end

defmodule ArgParser do
  def parse(argv) do
    case Enum.map(argv, &Integer.parse/1) do
      [{year, ""}, {month, ""}, {day, ""}] ->
        {:ok, JapaneseHolidays.lookup(year, month, day)}

      [{year, ""}, {month, ""}] ->
        {:ok, JapaneseHolidays.lookup(year, month)}

      [{year, ""}] ->
        {:ok, JapaneseHolidays.lookup(year)}

      _ ->
        {:error, error_message(argv)}
    end
  end

  defp error_message(argv) do
    """
    Invalid options #{inspect(argv)}

    usage: elixir examples/japanese_holidays.exs <year> [<month> [<day>]]
    """
  end
end

{:ok, _} = JapaneseHolidays.start_link()

System.argv()
|> ArgParser.parse()
|> case do
  {:ok, []} ->
    IO.puts("No events")

  {:ok, events} ->
    events
    |> Enum.each(fn {date, description} ->
      IO.puts("#{date} #{description}")
    end)

  {:error, reason} ->
    IO.puts(reason)
end
