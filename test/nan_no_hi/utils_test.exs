defmodule NanNoHi.UtilsTest do
  use ExUnit.Case

  alias NanNoHi.Utils

  doctest Utils

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
end
