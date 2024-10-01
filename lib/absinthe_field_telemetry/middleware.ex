defmodule AbsintheFieldTelemetry.Middleware do
  @moduledoc """
    Absinthe middleware for adding telemetry for usage of fields in a GraphQL schema.

    Add `AbsintheFieldTelemetry.Middleware` to all the fields on the schema. The
    easiest way to achieve this is using the [`middleware/3` callback](https://hexdocs.pm/absinthe/Absinthe.Middleware.html#module-the-middleware-3-callback):

  ```elixir
  def middleware(middleware, _field, _object), do: [AbsintheFieldTelemetry.Middleware | middleware]
  ```
  """

  alias AbsintheFieldTelemetry.Backend

  @behaviour Absinthe.Middleware

  @impl Absinthe.Middleware
  def call(resolution, _config) do
    Backend.record_field_hits(resolution.schema, [resolution_to_field(resolution)])

    resolution
  end

  defp resolution_to_field(%Absinthe.Resolution{definition: definition}),
    do: {definition.parent_type.identifier, definition.schema_node.identifier}
end
