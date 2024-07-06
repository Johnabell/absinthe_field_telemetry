defmodule AbsintheFieldTelemetry.Backend.TestSuite do
  @moduledoc """
    This module provides a test suite to ensure a backend has been implemented properly.

    To run the suite against a backend simply import the `test_backend` macro and call it
    passing the backend module:

    ```elixir
    import AbsintheFieldTelemetry.Backend.TestSuite

    test_backend AbsintheFieldTelemetry.Backend.Ets
    ```
  """
  defmacro test_backend(implementation) do
    quote do
      use ExUnit.Case

      alias unquote(implementation), as: Backend
      alias AbsintheFieldTelemetry.Test.Support.Schema

      setup do
        Backend.setup()
        Backend.reset(Schema)
      end

      test "record_field_hit/2" do
        assert :ok == Backend.record_field_hit(Schema, ["user"])
        assert :ok == Backend.record_field_hit(Schema, ["user", "id"])
        assert :ok == Backend.record_field_hit(Schema, ["user", "name"])
        assert :ok == Backend.record_field_hit(Schema, ["user"])
        assert :ok == Backend.record_field_hit(Schema, ["user", "id"])

        assert [
                 {["user"], 2},
                 {["user", "id"], 2},
                 {["user", "name"], 1}
               ] == Schema |> Backend.get_all_hits() |> Enum.sort()

        assert :ok == Backend.reset(Schema)
        assert [] == Backend.get_all_hits(Schema)
      end

      test "record_field_hit/3" do
        assert :ok == Backend.record_field_hit(Schema, :user, :id)
        assert :ok == Backend.record_field_hit(Schema, :query, :user)
        assert :ok == Backend.record_field_hit(Schema, :user, :name)
        assert :ok == Backend.record_field_hit(Schema, :query, :user)
        assert :ok == Backend.record_field_hit(Schema, :user, :id)

        assert [
                 {{:query, :user}, 2},
                 {{:user, :id}, 2},
                 {{:user, :name}, 1}
               ] == Schema |> Backend.get_all_type_hits() |> Enum.sort()

        assert :ok == Backend.reset(Schema)
        assert [] == Backend.get_all_type_hits(Schema)
      end
    end
  end
end
