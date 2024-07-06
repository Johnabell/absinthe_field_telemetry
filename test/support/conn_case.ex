defmodule AbsintheFieldTelemetry.Test.Support.ConnCase do
  @moduledoc """
    Support for testing the controller
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
    end
  end

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
