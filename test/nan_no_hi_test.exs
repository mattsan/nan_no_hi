defmodule NanNoHiTest do
  use ExUnit.Case
  doctest NanNoHi

  setup do
    {:ok, pid} = start_supervised(NanNoHi.Server)

    [pid: pid]
  end

  describe "lookup/2" do
    test "dummy", %{pid: pid} do
      assert {:ok, [{{2025, :_, :_}, "dummy"}]} == NanNoHi.lookup(pid, 2025)
    end
  end

  describe "lookup/3" do
    test "dummy", %{pid: pid} do
      assert {:ok, [{{2025, 7, :_}, "dummy"}]} == NanNoHi.lookup(pid, 2025, 7)
    end
  end

  describe "lookup/4" do
    test "dummy", %{pid: pid} do
      assert {:ok, [{{2025, 7, 15}, "dummy"}]} == NanNoHi.lookup(pid, 2025, 7, 15)
    end
  end
end
