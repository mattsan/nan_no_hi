defmodule NanNoHi.UtilsTest do
  use ExUnit.Case

  alias NanNoHi.Utils

  doctest Utils

  describe "import_list/1 with valid list" do
    import Utils, only: [import_list: 1]

    test "empty list" do
      assert {:ok, []} == import_list([])
    end

    test "Erlang date tuple" do
      input = [
        {{2024, 1, 1}, "元日"},
        {{2024, 5, 5}, "子供の日"},
        {{2025, 1, 1}, "元日"},
        {{2025, 5, 5}, "子供の日"}
      ]

      expected = [
        {{2024, 1, 1}, "元日"},
        {{2024, 5, 5}, "子供の日"},
        {{2025, 1, 1}, "元日"},
        {{2025, 5, 5}, "子供の日"}
      ]

      assert {:ok, expected} == import_list(input)
    end

    test "Date struct" do
      input = [
        {~D[2024-01-01], "元日"},
        {~D[2024-05-05], "子供の日"},
        {~D[2025-01-01], "元日"},
        {~D[2025-05-05], "子供の日"}
      ]

      expected = [
        {{2024, 1, 1}, "元日"},
        {{2024, 5, 5}, "子供の日"},
        {{2025, 1, 1}, "元日"},
        {{2025, 5, 5}, "子供の日"}
      ]

      assert {:ok, expected} == import_list(input)
    end
  end

  describe "import_list/1 with invalid list" do
    import Utils, only: [import_list: 1]

    test "includes invalid date format" do
      input = [
        {{2021, 1, 1}, "元日"},
        {"Jan 1st 2022", "元日"},
        {{2023, 1, 1}, "元日"},
        {"Jan 1st 2024", "元日"},
        {{2025, 1, 1}, "元日"}
      ]

      assert {:error, ["Jan 1st 2022", "Jan 1st 2024"]} == import_list(input)
    end

    test "includes invalid tuples" do
      input = [
        {{2021, 1, 1}, "元日"},
        {{2022, 1, 1}},
        {{2023, 1, 1}, "元日"},
        {{2024, 1, 1}, "元日", :leap_year},
        {{2025, 1, 1}, "元日"}
      ]

      assert {:error, [{{2022, 1, 1}}, {{2024, 1, 1}, "元日", :leap_year}]} == import_list(input)
    end
  end

  describe "import_csv/1 with valid string" do
    import Utils, only: [import_csv: 1]

    test "empty string" do
      assert {:ok, []} == import_csv("")
    end

    test "only header row" do
      assert {:ok, []} == import_csv("date,event")
    end

    test "one day" do
      input = """
      date,event
      2024/1/1,元日
      2024/5/5,子供の日
      2025/1/1,元日
      2025/5/5,子供の日
      """

      expected = [
        {{2024, 1, 1}, "元日"},
        {{2024, 5, 5}, "子供の日"},
        {{2025, 1, 1}, "元日"},
        {{2025, 5, 5}, "子供の日"}
      ]

      assert {:ok, expected} == import_csv(input)
    end
  end

  describe "import_csv/1 with invalid string" do
    import Utils, only: [import_csv: 1]

    test "includes invalid date format" do
      input = """
      date,event
      2021/1/1,元日
      Jan 1st 2022,元日
      2023/1/1,元日
      Jan 1st 2024,元日
      2025/1/1,元日
      """

      assert {:error, ["Jan 1st 2022", "Jan 1st 2024"]} == import_csv(input)
    end

    test "includes invalid rows" do
      input = """
      date,event
      2021/1/1,元日
      2022/1/1
      2023/1/1,元日
      2024/1/1,元日,leap_year
      2025/1/1,元日
      """

      assert {:error, [["2022/1/1"], ["2024/1/1", "元日", "leap_year"]]} == import_csv(input)
    end
  end

  describe "string_to_erl_date/1 with valid patterns" do
    import Utils, only: [string_to_erl_date: 1]

    test "2025-01-01", do: assert({:ok, {2025, 1, 1}} == string_to_erl_date("2025-01-01"))
    test "2025/01/01", do: assert({:ok, {2025, 1, 1}} == string_to_erl_date("2025/01/01"))
    test "2025-1-1", do: assert({:ok, {2025, 1, 1}} == string_to_erl_date("2025-1-1"))
    test "2025/1/1", do: assert({:ok, {2025, 1, 1}} == string_to_erl_date("2025/1/1"))
    test "20250101", do: assert({:ok, {2025, 1, 1}} == string_to_erl_date("20250101"))
    test "2025-12-31", do: assert({:ok, {2025, 12, 31}} == string_to_erl_date("2025-12-31"))
    test "2025/12/31", do: assert({:ok, {2025, 12, 31}} == string_to_erl_date("2025/12/31"))
    test "20251231", do: assert({:ok, {2025, 12, 31}} == string_to_erl_date("20251231"))
    test "0001-01-01", do: assert({:ok, {1, 1, 1}} == string_to_erl_date("0001-01-01"))
    test "9999/12/31", do: assert({:ok, {9999, 12, 31}} == string_to_erl_date("9999/12/31"))
    test "2025", do: assert({:ok, {20, 2, 5}} == string_to_erl_date("2025"))
  end

  describe "string_to_erl_date/1 with invalid patterns" do
    import Utils, only: [string_to_erl_date: 1]

    test "2025-02-29", do: assert({:error, "2025-02-29"} == string_to_erl_date("2025-02-29"))
    test "2025-00-01", do: assert({:error, "2025-00-01"} == string_to_erl_date("2025-00-01"))
    test "2025-01-00", do: assert({:error, "2025-01-00"} == string_to_erl_date("2025-01-00"))
    test "2025-13-01", do: assert({:error, "2025-13-01"} == string_to_erl_date("2025-13-01"))
    test "2025-01-32", do: assert({:error, "2025-01-32"} == string_to_erl_date("2025-01-32"))
    test "2025--01-01", do: assert({:error, "2025--01-01"} == string_to_erl_date("2025--01-01"))
    test "2025/01-01", do: assert({:error, "2025/01-01"} == string_to_erl_date("2025/01-01"))
    test "2025-01/01", do: assert({:error, "2025-01/01"} == string_to_erl_date("2025-01/01"))
    test "2025/0101", do: assert({:error, "2025/0101"} == string_to_erl_date("2025/0101"))
    test "202501-01", do: assert({:error, "202501-01"} == string_to_erl_date("202501-01"))
    test "2025-0101", do: assert({:error, "2025-0101"} == string_to_erl_date("2025-0101"))
    test "2025/1-1", do: assert({:error, "2025/1-1"} == string_to_erl_date("2025/1-1"))
    test "-123-4-5", do: assert({:error, "-123-4-5"} == string_to_erl_date("-123-4-5"))
    test "00000101", do: assert({:error, "00000101"} == string_to_erl_date("00000101"))
    test "", do: assert({:error, ""} == string_to_erl_date(""))
    test "2025-01", do: assert({:error, "2025-01"} == string_to_erl_date("2025-01"))
    test "abc", do: assert({:error, "abc"} == string_to_erl_date("abc"))
  end

  describe "collect_results/1" do
    import Utils, only: [collect_results: 1]

    test "all success" do
      input = [{:ok, "A"}, {:ok, "B"}, {:ok, "C"}, {:ok, "D"}]

      assert {:ok, ["A", "B", "C", "D"]} == collect_results(input)
    end

    test "all errors" do
      input = [{:error, "E1"}, {:error, "E2"}, {:error, "E3"}]

      assert {:error, ["E1", "E2", "E3"]} == collect_results(input)
    end

    test "mixed success and errors" do
      input = [{:ok, "A"}, {:error, "E1"}, {:ok, "B"}, {:error, "E2"}]

      assert {:error, ["E1", "E2"]} == collect_results(input)
    end

    test "empty list" do
      assert {:ok, []} == collect_results([])
    end

    test "single success" do
      assert {:ok, ["value"]} == collect_results([{:ok, "value"}])
    end

    test "single error" do
      assert {:error, ["reason"]} == collect_results([{:error, "reason"}])
    end

    test "preserves order of values when all success" do
      input = [{:ok, 1}, {:ok, 2}, {:ok, 3}, {:ok, 4}, {:ok, 5}]

      assert {:ok, [1, 2, 3, 4, 5]} == collect_results(input)
    end

    test "preserves order of errors when mixed" do
      input = [{:ok, 1}, {:error, :e1}, {:ok, 2}, {:error, :e2}, {:error, :e3}]

      assert {:error, [:e1, :e2, :e3]} == collect_results(input)
    end

    test "works with various data types" do
      input = [
        {:ok, %{key: "value"}},
        {:ok, [1, 2, 3]},
        {:ok, :atom},
        {:ok, "string"},
        {:ok, 42}
      ]

      expected = [%{key: "value"}, [1, 2, 3], :atom, "string", 42]

      assert {:ok, expected} == collect_results(input)
    end

    test "works with keyword list syntax" do
      input = [ok: "A", ok: "B", error: "E1", ok: "C", error: "E2"]

      assert {:error, ["E1", "E2"]} == collect_results(input)
    end
  end
end
