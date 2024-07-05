defmodule AbsintheFieldTelemetry.Web.Router do
  @moduledoc """
    The absinthe_field_telemetry_dashboard macro can be used to add the
    dashboard to your router, as follows:

    ```elixir
    import AbsintheFieldTelemetry.Web.Router
    absinthe_field_telemetry_dashboard "/absinthe_field_telemetry_dashboard"
    ```
  """

  defmacro absinthe_field_telemetry_dashboard(path, opts \\ []) do
    quote bind_quoted: binding() do
      scope path, alias: false, as: false do
        get "/:schema", AbsintheFieldTelemetry.Web.Controller, :home
        get "/:schema/tree", AbsintheFieldTelemetry.Web.Controller, :tree
        get "/:schema/reset", AbsintheFieldTelemetry.Web.Controller, :reset
        get "/:schema/refresh", AbsintheFieldTelemetry.Web.Controller, :refresh
      end
    end
  end
end
