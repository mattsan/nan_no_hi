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

{:ok, uri} = URI.new("https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv")
filename = Path.basename(uri.path)

# Make a new table
table = NanNoHi.new()

# Download CSV file if it's not been downloaded
if !File.exists?(filename) do
  csv =
    uri
    |> Req.get!(raw: true)
    |> then(&:iconv.convert("cp932", "utf-8", &1.body))

  File.write(filename, csv)
end

# Read CSV
{:ok, csv} = File.read(filename)

NanNoHi.import(table, csv)

options = System.argv()

case Enum.map(options, &Integer.parse/1) do
  [{year, ""}, {month, ""}, {day, ""}] ->
    {:ok, NanNoHi.lookup(table, year, month, day)}

  [{year, ""}, {month, ""}] ->
    {:ok, NanNoHi.lookup(table, year, month)}

  [{year, ""}] ->
    {:ok, NanNoHi.lookup(table, year)}

  _ ->
    usage = """
    Invalid options #{inspect(options)}

    usage: elixir examples/japanese_holidays.exs <year> [<month> [<day>]]
    """

    {:error, usage}
end
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
