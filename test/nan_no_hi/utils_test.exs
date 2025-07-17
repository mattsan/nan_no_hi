defmodule NanNoHi.UtilsTest do
  use ExUnit.Case

  alias NanNoHi.Utils

  doctest Utils

  describe "valid date" do
    test "2025-01-01", do: assert({:ok, {2025, 1, 1}} == Utils.string_to_erl_date("2025-01-01"))
    test "2025/01/01", do: assert({:ok, {2025, 1, 1}} == Utils.string_to_erl_date("2025/01/01"))
    test "2025-1-1", do: assert({:ok, {2025, 1, 1}} == Utils.string_to_erl_date("2025-1-1"))
    test "2025/1/1", do: assert({:ok, {2025, 1, 1}} == Utils.string_to_erl_date("2025/1/1"))
    test "20250101", do: assert({:ok, {2025, 1, 1}} == Utils.string_to_erl_date("20250101"))
    test "2025-12-31", do: assert({:ok, {2025, 12, 31}} == Utils.string_to_erl_date("2025-12-31"))
    test "2025/12/31", do: assert({:ok, {2025, 12, 31}} == Utils.string_to_erl_date("2025/12/31"))
    test "20251231", do: assert({:ok, {2025, 12, 31}} == Utils.string_to_erl_date("20251231"))
  end
end
