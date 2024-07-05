import Config

config :absinthe_field_telemetry,
  redis: [
    config: [
      expiry_ms: 60_000 * 60 * 4,
      cleanup_interval_ms: 60_000 * 10,
      redis_url: "redis://localhost:10020/1",
      pool_size: 4
    ]
  ]
