# AbsintheFieldTelemetry

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `absinthe_field_telemetry` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:absinthe_field_telemetry, "~> 0.1.0"}
  ]
end
```

Add a call to the setup function in your application setup

```elixir
AbsintheFieldTelemetry.setup()
```

Add `AbsintheFieldTelemetry.Middleware` to all the fields on the schema. The
easiest way to acheive this is using the [`middleware/3` callback](https://hexdocs.pm/absinthe/Absinthe.Middleware.html#module-the-middleware-3-callback):

```elixir
def middleware(middleware, _field, _object), do: [AbsintheFieldTelemetry.Middleware | middleware]
```

Add the dashboard to your router.

```elixir
import AbsintheFieldTelemetry.Web.Router
absinthe_field_telemetry_dashboard "/absinthe_field_telemetry_dashboard"
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/absinthe_field_telemetry>.

