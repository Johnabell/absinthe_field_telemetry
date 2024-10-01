defmodule AbsintheFieldTelemetry do
  @moduledoc """
    A library for analysing absinthe GraphQL runtime usage.

    ## Installation

    The package can be installed by adding `absinthe_field_telemetry` to your list
    of dependencies in `mix.exs`:

    ```elixir
    def deps do
    [
      {:absinthe_field_telemetry, "~> 0.2.5"}
    ]
    end
    ```

    Add a call to the setup function in your application setup

    ```elixir
    AbsintheFieldTelemetry.setup()
    ```

    Add `AbsintheFieldTelemetry.Middleware` to all the fields on the schema. The
    easiest way to achieve this is using the [`middleware/3` callback](https://hexdocs.pm/absinthe/Absinthe.Middleware.html#module-the-middleware-3-callback):

    ```elixir
    def middleware(middleware, _field, _object), do: [AbsintheFieldTelemetry.Middleware | middleware]
    ```

    Add the dashboard to your router.

    ```elixir
    import AbsintheFieldTelemetry.Web.Router
    absinthe_field_telemetry_dashboard "/absinthe_field_telemetry_dashboard"
    ```
  """

  alias AbsintheFieldTelemetry.Backend
  alias AbsintheFieldTelemetry.Types

  def get_field_hits(schema) do
    hits =
      schema
      |> Backend.get_all_field_hits()
      |> Enum.group_by(&elem(elem(&1, 0), 0), fn {{_, field}, count} -> {field, count} end)

    schema
    |> Absinthe.Schema.types()
    |> Enum.filter(&is_struct(&1, Absinthe.Type.Object))
    |> Enum.map(&Types.Object.from_absinthe_type_and_hits(&1, Map.get(hits, &1.identifier, [])))
    |> Enum.sort_by(& &1.name)
  end
end
