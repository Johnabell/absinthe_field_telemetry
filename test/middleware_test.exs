defmodule AbsintheFieldTelemetry.MiddlewareTest do
  use ExUnit.Case, async: true
  import Mock

  alias AbsintheFieldTelemetry.Test.Support.Schema

  @user_query """
  query User {
    user {
      id
      name
    }
  }
  """
  @user_id_query """
  query User {
    user {
      id
    }
  }
  """

  test "records hits for queried fields" do
    with_mock AbsintheFieldTelemetry.Backend,
      record_field_hits: fn Schema, _fields -> :ok end,
      record_path_hits: fn Schema, _path -> :ok end do
      assert {:ok, _} = Absinthe.run(@user_query, Schema)

      assert_called(AbsintheFieldTelemetry.Backend.record_path_hits(Schema, [["user"]]))
      assert_called(AbsintheFieldTelemetry.Backend.record_path_hits(Schema, [["user", "id"]]))
      assert_called(AbsintheFieldTelemetry.Backend.record_path_hits(Schema, [["user", "name"]]))

      assert_called(AbsintheFieldTelemetry.Backend.record_field_hits(Schema, [{:query, :user}]))
      assert_called(AbsintheFieldTelemetry.Backend.record_field_hits(Schema, [{:user, :id}]))
      assert_called(AbsintheFieldTelemetry.Backend.record_field_hits(Schema, [{:user, :name}]))
    end
  end

  test "does not record hits for no queried fields" do
    with_mock AbsintheFieldTelemetry.Backend,
      record_field_hits: fn Schema, _fields -> :ok end,
      record_path_hits: fn Schema, _path -> :ok end do
      assert {:ok, _} = Absinthe.run(@user_id_query, Schema)

      assert_called(AbsintheFieldTelemetry.Backend.record_path_hits(Schema, [["user"]]))
      assert_called(AbsintheFieldTelemetry.Backend.record_path_hits(Schema, [["user", "id"]]))
      refute called(AbsintheFieldTelemetry.Backend.record_path_hits(Schema, [["user", "name"]]))

      assert_called(AbsintheFieldTelemetry.Backend.record_field_hits(Schema, [{:query, :user}]))
      assert_called(AbsintheFieldTelemetry.Backend.record_field_hits(Schema, [{:user, :id}]))
      refute called(AbsintheFieldTelemetry.Backend.record_field_hits(Schema, [{:user, :name}]))
    end
  end
end
