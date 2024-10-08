defmodule AbsintheFieldTelemetry.Backend do
  @moduledoc """
    The backend of AbsintheFieldTelemetry.

    Contains details of the callbacks required for a backend.
  """

  @type t :: module
  @type schema :: Absinthe.Schema.t()
  @type type_identifier :: atom
  @type field_identifier :: atom
  @type field :: {type_identifier, field_identifier}
  @type field_hits :: [{field, integer}]

  @callback record_field_hits(schema, [field]) :: :ok
  @callback get_all_field_hits(schema) :: field_hits
  @callback reset(schema) :: :ok

  def record_field_hits(schema, fields), do: backend().record_field_hits(schema, fields)
  def get_all_field_hits(schema), do: backend().get_all_field_hits(schema)
  def reset(schema), do: backend().reset(schema)

  @spec backend() :: t()
  defp backend() do
    :absinthe_field_telemetry
    |> Application.get_env(:backend, {AbsintheFieldTelemetry.Backend.Ets, []})
    |> elem(0)
  end
end
