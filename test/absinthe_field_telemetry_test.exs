defmodule AbsintheFieldTelemetryTest do
  use ExUnit.Case
  doctest AbsintheFieldTelemetry

  setup do
    AbsintheFieldTelemetry.Backend.setup()
  end

  test "when there is not data returns empty root node" do
    assert AbsintheFieldTelemetry.get_all(Test.Schema) == AbsintheFieldTelemetry.Types.Node.root()
  end
end
