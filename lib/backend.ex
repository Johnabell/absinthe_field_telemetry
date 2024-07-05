defmodule AbsintheFieldTelemetry.Backend do
  @moduledoc """
    The backend of AbsintheFieldTelemetry.

    Contains details of the callbacks required for a backend.
  """

  @type t :: module
  @type path :: [String.t()]
  @type hits :: [{path, integer}]
  @type schema :: Absinthe.Schema.t()
  @type type_identifier :: atom
  @type field_identifier :: atom
  @type type_hits :: [{{type_identifier, field_identifier}, integer}]

  @implementation Application.compile_env(
                    :absinthe_field_telemetry,
                    [:backend],
                    AbsintheFieldTelemetry.Backend.Ets
                  )

  @callback setup() :: :ok
  @callback record_field_hit(schema, path) :: :ok
  @callback record_field_hit(schema, type_identifier, field_identifier) :: :ok
  @callback get_all_hits(schema) :: hits
  @callback get_all_type_hits(schema) :: type_hits
  @callback reset(schema) :: :ok

  defdelegate setup, to: @implementation
  defdelegate record_field_hit(schema, path), to: @implementation
  defdelegate record_field_hit(schema, type_identifier, field_identifier), to: @implementation
  defdelegate get_all_hits(schema), to: @implementation
  defdelegate get_all_type_hits(schema), to: @implementation
  defdelegate reset(schema), to: @implementation
end
