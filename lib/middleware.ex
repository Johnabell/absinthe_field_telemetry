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

  @dedup? Application.compile_env(:absinthe_field_telemetry, [:dedup?], true)

  @impl Absinthe.Middleware
  def call(resolution, _config) do
    resolution
    |> Absinthe.Resolution.path()
    |> record_hit(resolution.schema)

    Backend.record_field_hit(
      resolution.schema,
      resolution.definition.parent_type.identifier,
      resolution.definition.schema_node.identifier
    )

    resolution
  end

  def record_hit(path, schema) do
    if not @dedup? or not duplicate?(path) do
      path = Enum.reject(path, &Kernel.is_number/1)
      Backend.record_field_hit(schema, path)
    end
  end

  def duplicate?(path), do: Enum.any?(path, fn val -> is_number(val) && val > 0 end)
end
