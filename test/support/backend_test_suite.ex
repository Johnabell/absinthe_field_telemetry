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
        Backend.reset(Schema)
      end

      @type_hits [
        {:user, :id},
        {:query, :user},
        {:user, :name},
        {:query, :user},
        {:user, :id}
      ]

      describe "record_field_hits/2" do
        test "no field field" do
          assert :ok == Backend.record_field_hits(Schema, [])
          assert [] == Backend.get_all_field_hits(Schema)
        end

        test "record_field_hit/3" do
          assert :ok == Backend.record_field_hits(Schema, @type_hits)

          assert [
                   {{:query, :user}, 2},
                   {{:user, :id}, 2},
                   {{:user, :name}, 1}
                 ] == Schema |> Backend.get_all_field_hits() |> Enum.sort()

          assert :ok == Backend.reset(Schema)
          assert [] == Backend.get_all_field_hits(Schema)
        end
      end
    end
  end
end
