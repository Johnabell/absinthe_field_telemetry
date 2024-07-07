defmodule AbsintheFieldTelemetry.Backend.BatchTest do
  import AbsintheFieldTelemetry.Backend.TestSuite
  import Mock

  @threshold Application.compile_env(:absinthe_field_telemetry, [:batch, :threshold], 1000)

  test_backend AbsintheFieldTelemetry.Backend.Batch

  describe "path hits" do
    test "does not call backend when called less than batch size" do
      with_mock AbsintheFieldTelemetry.Backend.Ets,
        record_path_hits: fn _, _ -> :ok end,
        get_all_path_hits: fn _ -> [] end do
        Enum.each(2..@threshold, fn _ ->
          Backend.record_path_hits(Schema, [["user"]])
        end)

        assert [{["user"], 999}] = Backend.get_all_path_hits(Schema)

        refute called(AbsintheFieldTelemetry.Backend.Ets.record_path_hits(Schema, :_))
      end
    end

    test "does calls backend once with batch" do
      with_mock AbsintheFieldTelemetry.Backend.Ets,
        record_path_hits: fn _, _ -> :ok end,
        get_all_path_hits: fn _ -> [{["user"], 1000}] end do
        Enum.each(0..@threshold, fn _ ->
          Backend.record_path_hits(Schema, [["user"]])
        end)

        assert [{["user"], 1001}] = Backend.get_all_path_hits(Schema)

        assert_called_exactly(AbsintheFieldTelemetry.Backend.Ets.record_path_hits(Schema, :_), 1)
      end
    end
  end

  describe "field hits" do
    test "does not call backend when called less than batch size" do
      with_mock AbsintheFieldTelemetry.Backend.Ets,
        record_field_hits: fn _, _ -> :ok end,
        get_all_field_hits: fn _ -> [] end do
        Enum.each(2..@threshold, fn _ ->
          Backend.record_field_hits(Schema, [{:query, :user}])
        end)

        assert [{{:query, :user}, 999}] = Backend.get_all_field_hits(Schema)

        refute called(AbsintheFieldTelemetry.Backend.Ets.record_field_hits(Schema, :_))
      end
    end

    test "does calls backend once with batch" do
      with_mock AbsintheFieldTelemetry.Backend.Ets,
        record_field_hits: fn _, _ -> :ok end,
        get_all_field_hits: fn _ -> [{{:query, :user}, 1000}] end do
        Enum.each(0..@threshold, fn _ ->
          Backend.record_field_hits(Schema, [{:query, :user}])
        end)

        assert [{{:query, :user}, 1001}] = Backend.get_all_field_hits(Schema)

        assert_called_exactly(AbsintheFieldTelemetry.Backend.Ets.record_field_hits(Schema, :_), 1)
      end
    end
  end
end
