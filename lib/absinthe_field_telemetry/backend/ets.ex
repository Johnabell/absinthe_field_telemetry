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
    :ets.new(__MODULE__.FieldHits, [:set, :public, :named_table])

    {:ok, %{}}
  end

  @impl GenServer
  def handle_call(:stop, _from, state), do: {:stop, :normal, :ok, state}

  @impl AbsintheFieldTelemetry.Backend
  def record_path_hits(schema, paths) do
    Enum.each(paths, fn path ->
      key = {schema, path}
      :ets.update_counter(__MODULE__, key, {2, 1}, {key, 0})
    end)

    :ok
  end

  @impl AbsintheFieldTelemetry.Backend
  def record_field_hits(schema, fields) do
    Enum.each(fields, fn {type, field} ->
      key = {schema, type, field}
      :ets.update_counter(__MODULE__.FieldHits, key, {2, 1}, {key, 0})
    end)

    :ok
  end

  @impl AbsintheFieldTelemetry.Backend
  def get_all_path_hits(schema) do
    __MODULE__
    |> :ets.match_object({{schema, :_}, :_})
    |> Enum.map(fn {{_schema, path}, count} -> {path, count} end)
  end

  @impl AbsintheFieldTelemetry.Backend
  def get_all_field_hits(schema) do
    __MODULE__.FieldHits
    |> :ets.match_object({{schema, :_, :_}, :_})
    |> Enum.map(fn {{_schema, type, field}, count} -> {{type, field}, count} end)
  end

  @impl AbsintheFieldTelemetry.Backend
  def reset(schema) do
    :ets.match_delete(__MODULE__.FieldHits, {{schema, :_, :_}, :_})
    :ets.match_delete(__MODULE__, {{schema, :_}, :_})
    :ok
  end
end
