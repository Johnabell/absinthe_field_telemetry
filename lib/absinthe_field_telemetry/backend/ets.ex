defmodule AbsintheFieldTelemetry.Backend.Ets do
  @moduledoc """
    A AbsintheFieldTelemetry.Backend implementation using ets.
  """
  @behaviour AbsintheFieldTelemetry.Backend

  use GenServer

  @spec start :: :ignore | {:error, any} | {:ok, pid}
  @spec start(keyword()) :: :ignore | {:error, any} | {:ok, pid}
  def start(args \\ []), do: GenServer.start(__MODULE__, args, name: __MODULE__)

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  @spec start_link(keyword()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(args \\ []), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)

  @spec stop :: any
  def stop, do: GenServer.call(__MODULE__, :stop)

  @impl GenServer
  def init(_args) do
    :ets.new(__MODULE__, [:set, :public, :named_table])

    {:ok, %{}}
  end

  @impl GenServer
  def handle_call(:stop, _from, state), do: {:stop, :normal, :ok, state}

  @impl AbsintheFieldTelemetry.Backend
  def record_field_hits(schema, fields), do: do_record_hits(schema, fields, :field)

  @impl AbsintheFieldTelemetry.Backend
  def get_all_field_hits(schema), do: do_get_hits(schema, :field)

  @impl AbsintheFieldTelemetry.Backend
  def reset(schema) do
    :ets.match_delete(__MODULE__, {{schema, :_, :_}, :_})
    :ok
  end

  defp do_record_hits(schema, values, cache) do
    Enum.each(values, fn value ->
      key = {schema, cache, value}
      :ets.update_counter(__MODULE__, key, {2, 1}, {key, 0})
    end)
  end

  defp do_get_hits(schema, cache) do
    __MODULE__
    |> :ets.match_object({{schema, cache, :_}, :_})
    |> Enum.map(fn {{_schema, ^cache, value}, count} -> {value, count} end)
  end
end
