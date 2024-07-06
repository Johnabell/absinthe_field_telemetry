defmodule AbsintheFieldTelemetry.Backend do
  @moduledoc """
    The backend of AbsintheFieldTelemetry.

    Contains details of the callbacks required for a backend.
  """

  @type t :: module
  @type path :: [String.t()]
  @type path_hits :: [{path, integer}]
  @type schema :: Absinthe.Schema.t()
  @type type_identifier :: atom
  @type field_identifier :: atom
  @type field :: {type_identifier, field_identifier}
  @type field_hits :: [{field, integer}]

  @implementation Application.compile_env(
                    :absinthe_field_telemetry,
                    [:backend],
                    AbsintheFieldTelemetry.Backend.Ets
                  )

  @callback setup() :: :ok
  @callback record_path_hits(schema, [path]) :: :ok
  @callback record_field_hits(schema, [field]) :: :ok
  @callback get_all_path_hits(schema) :: path_hits
  @callback get_all_field_hits(schema) :: field_hits
  @callback reset(schema) :: :ok

  defdelegate setup, to: @implementation
  defdelegate record_path_hits(schema, paths), to: @implementation
  defdelegate record_field_hits(schema, fields), to: @implementation
  defdelegate get_all_path_hits(schema), to: @implementation
  defdelegate get_all_field_hits(schema), to: @implementation
  defdelegate reset(schema), to: @implementation
end
