# NanNoHi

NanNoHi ( 何の日？ *What day is it?* ) is a dictionary of dates that allows you to search for holidays, anniversaries and other notable days.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `nan_no_hi` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:nan_no_hi, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/nan_no_hi>.

## Examples

```elixir
# make new table
table = NanNoHi.new()

# import CSV
NanNoHi.import(table, """
date,event
2025/1/1,元日
2025/5/3,憲法記念日
2025/5/5,こどもの日
""")

# look up year
NanNoHi.lookup(table, 2025)
[{~D[2025-01-01], "元日"}, {~D[2025-05-03], "憲法記念日"}, {~D[2025-05-05], "こどもの日"}]

# look up year and month
NanNoHi.lookup(table, 2025, 5)
[{~D[2025-05-03], "憲法記念日"}, {~D[2025-05-05], "こどもの日"}]

# look up the date
NanNoHi.lookup(table, 2025, 5, 5)
[{~D[2025-05-05], "こどもの日"}]

NanNoHi.lookup(table, ~D[2025-01-01])
[{~D[2025-01-01], "元日"}]
```

### National Holidays in Japan

An example of retrieving national holidays in Japan is available at `examples/japanese_holidays.exs` or on [the GitHub repository](https://github.com/mattsan/nan_no_hi/blob/main/examples/japanese_holidays.exs).
