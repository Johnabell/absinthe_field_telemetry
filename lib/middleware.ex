defmodule AbsintheFieldTelemetry.Middleware do
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

  def wrap(middleware), do: [__MODULE__ | middleware]
end
