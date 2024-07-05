defmodule AbsintheFieldTelemetry.Web.Router do
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
