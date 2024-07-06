defmodule AbsintheFieldTelemetry.Backend.RedisTest do
  import AbsintheFieldTelemetry.Backend.TestSuite

  test_backend AbsintheFieldTelemetry.Backend.Redis

  test "returns empty list when connection is down" do
    # Disconnect and Set bad connection string
    Backend.stop()

    Backend.start(
      expiry_ms: 60_000 * 60 * 4,
      redix_config: "redis://doesnotexist:5000"
    )

    # Attempt to record hits
    assert :ok == Backend.record_field_hit(Schema, ["user"])
    assert :ok == Backend.record_field_hit(Schema, :user, :id)
    # Query hits should return empty lists
    assert [] = Backend.get_all_hits(Schema)
    assert [] = Backend.get_all_type_hits(Schema)

    # Restore connection
    Backend.stop()
    Backend.setup()
  end
end
