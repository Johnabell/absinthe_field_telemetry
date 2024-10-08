defmodule AbsintheFieldTelemetry.Backend.BatchTest do
  use ExUnit.Case
  import AbsintheFieldTelemetry.Backend.TestSuite
  import Mock

  @threshold 1000
  @interval_ms 100

  setup do
    start_link()
    :ok
  end

  test_backend AbsintheFieldTelemetry.Backend.Batch

  describe "field hits" do
    test "does not call backend when called less than batch size" do
      with_mock AbsintheFieldTelemetry.Backend.Ets,
        record_field_hits: fn _, _ -> :ok end,
        get_all_field_hits: fn _ -> [] end do
        Enum.each(2..@threshold, fn _ -> Backend.record_field_hits(Schema, [{:query, :user}]) end)

        assert [{{:query, :user}, 999}] = Backend.get_all_field_hits(Schema)

        refute called(AbsintheFieldTelemetry.Backend.Ets.record_field_hits(Schema, :_))
      end
    end

    test "does calls backend once with batch" do
      with_mock AbsintheFieldTelemetry.Backend.Ets,
        record_field_hits: fn _, _ -> :ok end,
        get_all_field_hits: fn _ -> [{{:query, :user}, 1000}] end do
        Enum.each(0..@threshold, fn _ -> Backend.record_field_hits(Schema, [{:query, :user}]) end)

        assert [{{:query, :user}, 1001}] = Backend.get_all_field_hits(Schema)

        assert_called_exactly(AbsintheFieldTelemetry.Backend.Ets.record_field_hits(Schema, :_), 1)
      end
    end
  end

  describe "interval" do
    test "does not call backend when called less than batch size" do
      with_mock AbsintheFieldTelemetry.Backend.Ets,
        record_field_hits: fn _, _ -> :ok end,
        get_all_field_hits: fn _ -> [] end do
        Enum.each(2..@threshold, fn _ ->
          Backend.record_field_hits(Schema, [{:query, :user}])
        end)

        assert [{{:query, :user}, 999}] = Backend.get_all_field_hits(Schema)

        refute called(AbsintheFieldTelemetry.Backend.Ets.record_field_hits(Schema, :_))

        :timer.sleep(@interval_ms + 10)

        assert_called_exactly(AbsintheFieldTelemetry.Backend.Ets.record_field_hits(Schema, :_), 1)

        :timer.sleep(@interval_ms + 10)

        assert_called_exactly(AbsintheFieldTelemetry.Backend.Ets.record_field_hits(Schema, :_), 1)
      end
    end
  end

  describe "stop" do
    test "records all cached hits on stop" do
      with_mock AbsintheFieldTelemetry.Backend.Ets,
        record_field_hits: fn _, _ -> :ok end,
        stop: fn -> :ok end do
        Enum.each(2..@threshold, fn _ ->
          Backend.record_field_hits(Schema, [{:query, :user}])
        end)

        refute called(AbsintheFieldTelemetry.Backend.Ets.record_field_hits(Schema, :_))

        assert :ok = Backend.stop()

        assert_called_exactly(AbsintheFieldTelemetry.Backend.Ets.record_field_hits(Schema, :_), 1)
      end

      start_link()
    end
  end

  defp start_link() do
    AbsintheFieldTelemetry.Backend.Batch.start_link(
      backend: {AbsintheFieldTelemetry.Backend.Ets, []},
      threshold: @threshold,
      interval_ms: @interval_ms
    )
  end
end
