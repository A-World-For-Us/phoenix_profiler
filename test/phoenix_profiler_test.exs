defmodule PhoenixProfilerTest do
  use ExUnit.Case, async: true

  doctest PhoenixProfiler

  test "init/1 returns the given options" do
    assert PhoenixProfiler.init(foo: :bar) == [foo: :bar]
  end
end
