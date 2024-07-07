defmodule AbsintheFieldTelemetry.Backend.EtsTest do
  import AbsintheFieldTelemetry.Backend.TestSuite

  test_backend AbsintheFieldTelemetry.Backend.Ets

  test "can be stopped and restarted normally" do
    assert :ok == Backend.stop()
    Backend.start()
  end
end
