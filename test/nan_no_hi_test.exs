defmodule NanNoHiTest do
  use ExUnit.Case
  doctest NanNoHi

  defp store_japanese_holidays(%{table: table}) do
    [
      {~D[2024-01-01], "元日"},
      {~D[2024-01-08], "成人の日"},
      {~D[2024-02-11], "建国記念の日"},
      {~D[2024-02-12], "休日"},
      {~D[2024-02-23], "天皇誕生日"},
      {~D[2024-03-20], "春分の日"},
      {~D[2024-04-29], "昭和の日"},
      {~D[2024-05-03], "憲法記念日"},
      {~D[2024-05-04], "みどりの日"},
      {~D[2024-05-05], "こどもの日"},
      {~D[2024-05-06], "休日"},
      {~D[2024-07-15], "海の日"},
      {~D[2024-08-11], "山の日"},
      {~D[2024-08-12], "休日"},
      {~D[2024-09-16], "敬老の日"},
      {~D[2024-09-22], "秋分の日"},
      {~D[2024-09-23], "休日"},
      {~D[2024-10-14], "スポーツの日"},
      {~D[2024-11-03], "文化の日"},
      {~D[2024-11-04], "休日"},
      {~D[2024-11-23], "勤労感謝の日"},
      {~D[2025-01-01], "元日"},
      {~D[2025-01-13], "成人の日"},
      {~D[2025-02-11], "建国記念の日"},
      {~D[2025-02-23], "天皇誕生日"},
      {~D[2025-02-24], "休日"},
      {~D[2025-03-20], "春分の日"},
      {~D[2025-04-29], "昭和の日"},
      {~D[2025-05-03], "憲法記念日"},
      {~D[2025-05-04], "みどりの日"},
      {~D[2025-05-05], "こどもの日"},
      {~D[2025-05-06], "休日"},
      {~D[2025-07-21], "海の日"},
      {~D[2025-08-11], "山の日"},
      {~D[2025-09-15], "敬老の日"},
      {~D[2025-09-23], "秋分の日"},
      {~D[2025-10-13], "スポーツの日"},
      {~D[2025-11-03], "文化の日"},
      {~D[2025-11-23], "勤労感謝の日"},
      {~D[2025-11-24], "休日"}
    ]
    |> Enum.each(fn {date, event} ->
      NanNoHi.append(table, date, event)
    end)
  end

  setup do
    table = NanNoHi.new()

    [table: table]
  end

  describe "lookup/2" do
    setup :store_japanese_holidays

    test "2025", %{table: table} do
      expected_events = [
        {~D[2025-01-01], "元日"},
        {~D[2025-01-13], "成人の日"},
        {~D[2025-02-11], "建国記念の日"},
        {~D[2025-02-23], "天皇誕生日"},
        {~D[2025-02-24], "休日"},
        {~D[2025-03-20], "春分の日"},
        {~D[2025-04-29], "昭和の日"},
        {~D[2025-05-03], "憲法記念日"},
        {~D[2025-05-04], "みどりの日"},
        {~D[2025-05-05], "こどもの日"},
        {~D[2025-05-06], "休日"},
        {~D[2025-07-21], "海の日"},
        {~D[2025-08-11], "山の日"},
        {~D[2025-09-15], "敬老の日"},
        {~D[2025-09-23], "秋分の日"},
        {~D[2025-10-13], "スポーツの日"},
        {~D[2025-11-03], "文化の日"},
        {~D[2025-11-23], "勤労感謝の日"},
        {~D[2025-11-24], "休日"}
      ]

      assert expected_events == NanNoHi.lookup(table, 2025)
    end

    test "~D[2025-05-05]", %{table: table} do
      assert [{~D[2025-05-05], "こどもの日"}] == NanNoHi.lookup(table, ~D[2025-05-05])
    end

    test "invalid year value", %{table: table} do
      assert_raise(FunctionClauseError, fn -> NanNoHi.lookup(table, "2025") end)
    end
  end

  describe "lookup/3" do
    setup :store_japanese_holidays

    test "2025-05", %{table: table} do
      expected_events = [
        {~D[2025-05-03], "憲法記念日"},
        {~D[2025-05-04], "みどりの日"},
        {~D[2025-05-05], "こどもの日"},
        {~D[2025-05-06], "休日"}
      ]

      assert expected_events == NanNoHi.lookup(table, 2025, 5)
    end

    test "2025-06", %{table: table} do
      assert [] == NanNoHi.lookup(table, 2025, 6)
    end

    test "invalid month value", %{table: table} do
      assert_raise(FunctionClauseError, fn -> NanNoHi.lookup(table, 2025, 13) end)
    end
  end

  describe "lookup/4" do
    setup :store_japanese_holidays

    test "2025-05-05", %{table: table} do
      assert [{~D[2025-05-05], "こどもの日"}] == NanNoHi.lookup(table, 2025, 5, 5)
    end

    test "2025-05-07", %{table: table} do
      assert [] == NanNoHi.lookup(table, 2025, 5, 7)
    end

    test "invalid day value", %{table: table} do
      assert_raise(FunctionClauseError, fn -> NanNoHi.lookup(table, 2025, 1, 32) end)
    end
  end

  describe "append/3" do
    test "append a date", %{table: table} do
      assert [] == NanNoHi.lookup(table, 2025, 7, 15)
      assert :ok == NanNoHi.append(table, ~D[2025-07-15], "rainy day")
      assert [{~D[2025-07-15], "rainy day"}] == NanNoHi.lookup(table, 2025, 7, 15)
    end

    test "append two events on a day", %{table: table} do
      expected_events = [
        {~D[2025-07-16], "Wednesday"},
        {~D[2025-07-16], "rainy day"}
      ]

      assert [] == NanNoHi.lookup(table, 2025, 7, 16)
      assert :ok == NanNoHi.append(table, ~D[2025-07-16], "rainy day")
      assert :ok == NanNoHi.append(table, ~D[2025-07-16], "Wednesday")
      assert expected_events == Enum.sort(NanNoHi.lookup(table, 2025, 7, 16))
    end

    test "invalid date value", %{table: table} do
      assert_raise(FunctionClauseError, fn -> NanNoHi.append(table, "2025-01-01", "元日") end)
    end
  end

  describe "append/5" do
    test "append a date", %{table: table} do
      assert [] == NanNoHi.lookup(table, 2025, 7, 15)
      assert :ok == NanNoHi.append(table, 2025, 7, 15, "rainy day")
      assert [{~D[2025-07-15], "rainy day"}] == NanNoHi.lookup(table, 2025, 7, 15)
    end

    test "append two events on a day", %{table: table} do
      expected_events = [
        {~D[2025-07-16], "Wednesday"},
        {~D[2025-07-16], "rainy day"}
      ]

      assert [] == NanNoHi.lookup(table, 2025, 7, 16)
      assert :ok == NanNoHi.append(table, 2025, 7, 16, "rainy day")
      assert :ok == NanNoHi.append(table, 2025, 7, 16, "Wednesday")
      assert expected_events == Enum.sort(NanNoHi.lookup(table, 2025, 7, 16))
    end

    test "invalid year value", %{table: table} do
      assert {:error, :invalid_date} == NanNoHi.append(table, "2025", 1, 1, "invalid")
    end

    test "invalid month value", %{table: table} do
      assert {:error, :invalid_date} == NanNoHi.append(table, 2025, 13, 1, "invalid")
    end

    test "invalid day value", %{table: table} do
      assert {:error, :invalid_date} == NanNoHi.append(table, 2025, 1, 32, "invalid")
    end
  end

  describe "import/2" do
    test "import two events", %{table: table} do
      input_list = [
        {~D[2025-07-16], "Wednesday"},
        {~D[2025-07-17], "rainy day"}
      ]

      expected_events = [
        {~D[2025-07-16], "Wednesday"},
        {~D[2025-07-17], "rainy day"}
      ]

      assert [] == NanNoHi.lookup(table, 2025, 7)
      assert :ok == NanNoHi.import(table, input_list)
      assert expected_events == Enum.sort(NanNoHi.lookup(table, 2025, 7))
    end

    test "import from CSV format string (YYYY-MM-DD)", %{table: table} do
      input_string =
        """
        date,event
        2025-07-16,Wednesday
        2025-07-17,rainy day
        """

      expected_events = [
        {~D[2025-07-16], "Wednesday"},
        {~D[2025-07-17], "rainy day"}
      ]

      assert [] == NanNoHi.lookup(table, 2025, 7)
      assert :ok == NanNoHi.import(table, input_string)
      assert expected_events == Enum.sort(NanNoHi.lookup(table, 2025, 7))
    end

    test "import from CSV format string (YYYY/MM/DD)", %{table: table} do
      input_string = """
      date,event
      2025/7/16,Wednesday
      2025/7/17,rainy day
      """

      expected_events = [
        {~D[2025-07-16], "Wednesday"},
        {~D[2025-07-17], "rainy day"}
      ]

      assert [] == NanNoHi.lookup(table, 2025, 7)
      assert :ok == NanNoHi.import(table, input_string)
      assert expected_events == Enum.sort(NanNoHi.lookup(table, 2025, 7))
    end

    test "import CSV format string including invalid dates", %{table: table} do
      input_string = """
      date,event
      2025-07-01,Tuesday
      7 1st 2025,Tuesday
      2025-07-02,Wednesday
      7 2nd 2025,Wednesday
      """

      assert [] == NanNoHi.lookup(table, 2025, 7)
      assert {:error, ["7 1st 2025", "7 2nd 2025"]} == NanNoHi.import(table, input_string)
      assert [] == NanNoHi.lookup(table, 2025, 7)
    end

    test "import invalid CSV format string", %{table: table} do
      input_string = """
      date,event
      7 1st 2025,Tuesday
      7 2nd 2025,Wednesday
      """

      assert [] == NanNoHi.lookup(table, 2025, 7)
      assert {:error, ["7 1st 2025", "7 2nd 2025"]} == NanNoHi.import(table, input_string)
      assert [] == NanNoHi.lookup(table, 2025, 7)
    end
  end

  describe "NanNoHi.clear/1" do
    test "clear all", %{table: table} do
      input_string = """
      date,event
      2025/7/16,Wednesday
      2025/7/17,rainy day
      """

      expected_events = [
        {~D[2025-07-16], "Wednesday"},
        {~D[2025-07-17], "rainy day"}
      ]

      assert [] == NanNoHi.lookup(table, 2025, 7)
      assert :ok == NanNoHi.import(table, input_string)
      assert expected_events == Enum.sort(NanNoHi.lookup(table, 2025, 7))
      assert :ok == NanNoHi.clear(table)
      assert [] == NanNoHi.lookup(table, 2025, 7)
    end
  end

  describe "lookup_all/1" do
    test "lookup all", %{table: table} do
      input_string = """
      date,event
      2025/7/16,Wednesday
      2025/7/17,rainy day
      """

      expected_events = [
        {~D[2025-07-16], "Wednesday"},
        {~D[2025-07-17], "rainy day"}
      ]

      assert [] == NanNoHi.lookup_all(table)
      assert :ok == NanNoHi.import(table, input_string)
      assert expected_events == Enum.sort(NanNoHi.lookup_all(table))
    end
  end

  describe "append complex events" do
    test "append tuples", %{table: table} do
      assert [] == NanNoHi.lookup(table, 2025, 7, 15)
      assert :ok == NanNoHi.append(table, 2025, 7, 16, {"曜日", "水曜日"})
      assert [{~D[2025-07-16], {"曜日", "水曜日"}}] == NanNoHi.lookup(table, 2025, 7, 16)
    end
  end
end
