defmodule AbsintheFieldTelemetry.Application do
  @moduledoc """
  AbsintheFieldTelemetry application, responsible for starting the backend workers.

  Configured with the `:absinthe_field_telemetry` environment key:

  - `:backend`, a tuple of `{module, config}`

  Different backends take different options, see the documentation for the given backend for more details.

  Example backend:

      config :absinthe_field_telemetry,
        backend: {AbsintheFieldTelemetry.Backend.ETS, []}
  """

  use Application

  def start(_type, _args) do
    config =
      Application.get_env(
        :absinthe_field_telemetry,
        :backend,
        {AbsintheFieldTelemetry.Backend.Ets, []}
      )

    AbsintheFieldTelemetry.Supervisor.start_link(config, name: AbsintheFieldTelemetry.Supervisor)
  end
end
