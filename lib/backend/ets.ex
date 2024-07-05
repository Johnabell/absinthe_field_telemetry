defmodule AbsintheFieldTelemetry.Backend.Ets do
  @moduledoc """
    A AbsintheFieldTelemetry.Backend implementation using ets.
  """
  @behaviour AbsintheFieldTelemetry.Backend

  @impl AbsintheFieldTelemetry.Backend
  def setup() do
    :ets.new(__MODULE__, [:set, :public, :named_table])
    :ets.new(__MODULE__.TypeHits, [:set, :public, :named_table])
    :ok
  end

  @impl AbsintheFieldTelemetry.Backend
  def record_field_hit(schema, path) do
    key = {schema, path}
    :ets.update_counter(__MODULE__, key, {2, 1}, {key, 0})
    :ok
  end

  @impl AbsintheFieldTelemetry.Backend
  def record_field_hit(schema, type, field) do
    key = {schema, type, field}
    :ets.update_counter(__MODULE__.TypeHits, key, {2, 1}, {key, 0})
    :ok
  end

  @impl AbsintheFieldTelemetry.Backend
  def get_all_hits(schema) do
    __MODULE__
    |> :ets.match_object({{schema, :_}, :_})
    |> Enum.map(fn {{_schema, path}, count} -> {path, count} end)
  end

  @impl AbsintheFieldTelemetry.Backend
  def get_all_type_hits(schema) do
    __MODULE__.TypeHits
    |> :ets.match_object({{schema, :_, :_}, :_})
    |> Enum.map(fn {{_schema, type, field}, count} -> {{type, field}, count} end)
  end

  @impl AbsintheFieldTelemetry.Backend
  def reset(schema) do
    :ets.match_delete(__MODULE__.TypeHits, {{schema, :_, :_}, :_})
    :ets.match_delete(__MODULE__, {{schema, :_}, :_})
    :ok
  end
end
