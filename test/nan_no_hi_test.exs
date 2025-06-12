defmodule NanNoHiTest do
  use ExUnit.Case
  doctest NanNoHi

  test "greets the world" do
    assert NanNoHi.hello() == :world
  end
end
