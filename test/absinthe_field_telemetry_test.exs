defmodule AbsintheFieldTelemetryTest do
  use ExUnit.Case
  import Mock
  doctest AbsintheFieldTelemetry

  alias AbsintheFieldTelemetry.Test.Support.Schema

  test "when there is no data all types with zero count" do
    with_mock AbsintheFieldTelemetry.Backend, get_all_field_hits: fn Schema -> [] end do
      Schema
      |> AbsintheFieldTelemetry.get_field_hits()
      |> Enum.each(fn type ->
        assert type.count == 0
        assert Enum.all?(type.fields, &(&1.count == 0))
      end)

      assert_called(AbsintheFieldTelemetry.Backend.get_all_field_hits(Schema))
    end
  end
end
