defmodule AbsintheFieldTelemetry.Web.ControllerTest do
  use ExUnit.Case
  use AbsintheFieldTelemetry.Test.Support.ConnCase
  import Mock

  alias AbsintheFieldTelemetry.Test.Support.Schema
  alias AbsintheFieldTelemetry.Web.Controller

  @schema Schema |> Atom.to_string() |> String.split(".") |> Enum.drop(1) |> Enum.join(".")

  @unrecognised_schema_error "Unrecognised schema"
  @field_hits [
    {["user", "address", "postcode"], 15},
    {["user", "address"], 15},
    {["user", "name"], 30},
    {["user"], 45}
  ]
  @type_hits [
    {{:query, :user}, 45},
    {{:user, :id}, 45}
  ]

  describe "home" do
    test "unrecognised schema", %{conn: conn} do
      assert @unrecognised_schema_error =
               conn
               |> Controller.home(%{"schema" => "UnknownSchema"})
               |> text_response(200)
    end

    test "schema no data", %{conn: conn} do
      with_mock AbsintheFieldTelemetry.Backend, get_all_field_hits: fn Schema -> [] end do
        assert _page =
                 conn
                 |> Controller.home(%{"schema" => @schema})
                 |> html_response(200)

        assert_called(AbsintheFieldTelemetry.Backend.get_all_field_hits(Schema))
      end
    end

    test "schema data", %{conn: conn} do
      with_mock AbsintheFieldTelemetry.Backend, get_all_field_hits: fn Schema -> @type_hits end do
        assert _page =
                 conn
                 |> Controller.home(%{"schema" => @schema})
                 |> html_response(200)

        assert_called(AbsintheFieldTelemetry.Backend.get_all_field_hits(Schema))
      end
    end
  end

  describe "tree" do
    test "unrecognised schema", %{conn: conn} do
      assert @unrecognised_schema_error =
               conn
               |> Controller.tree(%{"schema" => "UnknownSchema"})
               |> text_response(200)
    end

    test "schema no data", %{conn: conn} do
      with_mock AbsintheFieldTelemetry.Backend, get_all_path_hits: fn Schema -> [] end do
        assert page =
                 conn
                 |> Controller.tree(%{"schema" => @schema})
                 |> html_response(200)

        assert page =~ "root"

        assert_called(AbsintheFieldTelemetry.Backend.get_all_path_hits(Schema))
      end
    end

    test "schema data", %{conn: conn} do
      with_mock AbsintheFieldTelemetry.Backend, get_all_path_hits: fn Schema -> @field_hits end do
        assert page =
                 conn
                 |> Controller.tree(%{"schema" => @schema})
                 |> html_response(200)

        assert page =~ "root"
        assert page =~ "user"
        assert page =~ "address"
        assert page =~ "postcode"
        assert page =~ "name"

        assert_called(AbsintheFieldTelemetry.Backend.get_all_path_hits(Schema))
      end
    end
  end

  describe "reset" do
    test "unrecognised schema", %{conn: conn} do
      assert @unrecognised_schema_error =
               conn
               |> Controller.reset(%{"schema" => "UnknownSchema"})
               |> text_response(200)
    end

    test "resets the backend for the schema", %{conn: conn} do
      with_mock AbsintheFieldTelemetry.Backend, reset: fn Schema -> :ok end do
        base_path = "/absinthe_field_telemetry_dashboard/#{@schema}"

        assert ^base_path =
                 %Plug.Conn{conn | request_path: "#{base_path}/reset"}
                 |> Controller.reset(%{"schema" => @schema})
                 |> redirected_to()

        assert_called(AbsintheFieldTelemetry.Backend.reset(Schema))
      end
    end
  end
end
