defmodule AbsintheFieldTelemetry.Supervisor do
  @moduledoc """
    Top-level Supervisor for the AbsintheFieldTelemetry application.

    Starts and supervises the backend
  """

  use Supervisor

  def start_link(config, opts), do: Supervisor.start_link(__MODULE__, config, opts)

  def init(config), do: Supervisor.init([config], strategy: :one_for_one)
end
