defmodule AbsintheFieldTelemetry.Backend.RedisTest do
  use ExUnit.Case
  import AbsintheFieldTelemetry.Backend.TestSuite

  @default_redis_url "redis://localhost:6379/1"

  setup do
    start_link()
    :ok
  end

  test_backend AbsintheFieldTelemetry.Backend.Redis

  test "returns empty list when connection is down" do
    # Disconnect and Set bad connection string
    Backend.stop()

    start_link(redix_config: "redis://doesnotexist:5000")

    # Attempt to record hits
    assert :ok == Backend.record_field_hits(Schema, [{:user, :id}])
    # Query hits should return empty lists
    assert [] = Backend.get_all_field_hits(Schema)

    # Restore connection
    Backend.stop()
    start_link()
  end

  defp start_link(config \\ [redis_url: @default_redis_url]) do
    [expiry_ms: 60_000 * 60 * 4]
    |> Keyword.merge(config)
    |> AbsintheFieldTelemetry.Backend.Redis.start_link()
  end
end
