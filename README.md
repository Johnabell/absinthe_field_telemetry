# AbsintheFieldTelemetry

A library for analysing absinthe GraphQL runtime usage.

## Installation

The package can be installed by adding `absinthe_field_telemetry` to your list
of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:absinthe_field_telemetry, "~> 0.2.2"}
  ]
end
```

Add `AbsintheFieldTelemetry.Middleware` to all the fields on the schema. The
easiest way to achieve this is using the [`middleware/3` callback](https://hexdocs.pm/absinthe/Absinthe.Middleware.html#module-the-middleware-3-callback):

```elixir
def middleware(middleware, _field, _object), do: [AbsintheFieldTelemetry.Middleware | middleware]
```

Add the dashboard to your router.

```elixir
import AbsintheFieldTelemetry.Web.Router
absinthe_field_telemetry_dashboard "/absinthe_field_telemetry_dashboard"
```

## Test

To run the redis tests you need to have redis running. You can do this via docker compose by running:

```bash
docker compose up -d
```

Then you can run the tests

```
mix test
```
