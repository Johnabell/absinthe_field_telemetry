[![Elixir CI](https://github.com/Johnabell/absinthe_field_telemetry/actions/workflows/elixir.yml/badge.svg)](https://github.com/Johnabell/absinthe_field_telemetry/actions/workflows/elixir.yml)
[![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/absinthe_field_telemetry)
[![Hex.pm](https://img.shields.io/hexpm/v/absinthe_field_telemetry.svg)](https://hex.pm/packages/absinthe_field_telemetry)
[![License](https://img.shields.io/hexpm/l/absinthe_field_telemetry.svg)](https://github.com/Johnabell/absinthe_field_telemetry/blob/master/LICENSE)

# AbsintheFieldTelemetry

A library for analysing absinthe GraphQL runtime usage.

## Installation

The package can be installed by adding `absinthe_field_telemetry` to your list
of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:absinthe_field_telemetry, "~> 0.3.1"}
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
