defmodule AbsintheFieldTelemetry.Backend.Batch do
  @moduledoc """
    This implementation of the backend is provided to be a wrapper around
    another backend.

    The idea related to this backend is that it will cache field and path hits
    in memory and then report them in batches of size `threshold` the other
    backend.
    
    This is disigned to improve performance and throughput when a backend 
    requires a network call.
  """
  import TypedStruct

  alias AbsintheFieldTelemetry.Backend

  typedstruct enforce: true do
    field :field_cache, %{required(atom) => list()}, default: %{}
    field :path_cache, %{required(atom) => list()}, default: %{}
    field :threshold, integer()
    field :backend, AbsintheFieldTelemetry.Backend.t()
  end

  @behaviour Backend
  @behaviour GenServer

  @backend Application.compile_env(
             :absinthe_field_telemetry,
             [:batch, :backend],
             AbsintheFieldTelemetry.Backend.Ets
           )

  @threshold Application.compile_env(:absinthe_field_telemetry, [:batch, :threshold], 1000)

  @impl Backend
  def setup() do
    GenServer.start_link(__MODULE__, [threshold: @threshold, backend: @backend], name: __MODULE__)
    @backend.setup()
  end

  @impl AbsintheFieldTelemetry.Backend
  def record_path_hits(schema, paths),
    do: GenServer.cast(__MODULE__, {:incr_paths, {schema, paths}})

  @impl AbsintheFieldTelemetry.Backend
  def record_field_hits(schema, fields),
    do: GenServer.cast(__MODULE__, {:incr_fields, {schema, fields}})

  @impl AbsintheFieldTelemetry.Backend
  def get_all_path_hits(schema), do: GenServer.call(__MODULE__, {:path_hits, schema})

  @impl AbsintheFieldTelemetry.Backend
  def get_all_field_hits(schema), do: GenServer.call(__MODULE__, {:field_hits, schema})

  @impl AbsintheFieldTelemetry.Backend
  def reset(schema), do: GenServer.cast(__MODULE__, {:reset, schema})

  @impl GenServer
  def init(args) do
    threshold = Keyword.get(args, :threshold)
    backend = Keyword.get(args, :backend)
    {:ok, %__MODULE__{threshold: threshold, backend: backend}}
  end

  @impl GenServer
  def handle_cast({:incr_paths, {schema, paths}}, state),
    do: do_incr(state, :path_cache, schema, paths)

  def handle_cast({:incr_fields, {schema, fields}}, state),
    do: do_incr(state, :field_cache, schema, fields)

  def handle_cast({:reset, schema}, state) do
    @backend.reset(schema)

    state
    |> reset(:path_cache, schema)
    |> reset(:field_cache, schema)
    |> noreply()
  end

  @impl GenServer
  def handle_call({:path_hits, schema}, _, state), do: do_get_hits(state, :path_cache, schema)
  def handle_call({:field_hits, schema}, _, state), do: do_get_hits(state, :field_cache, schema)

  defp do_get_hits(%__MODULE__{} = state, cache, schema) do
    state.backend
    |> Kernel.apply(get_all_hits_function(cache), [schema])
    |> Map.new()
    |> Map.merge(get_cache(state, cache, schema), fn _, v1, v2 -> v1 + v2 end)
    |> Map.to_list()
    |> reply(state)
  end

  defp do_incr(%__MODULE__{} = state, cache, schema, values) do
    state
    |> update(cache, schema, values)
    |> maybe_send_batch(schema)
    |> noreply()
  end

  defp update(%__MODULE__{} = state, cache, schema, values) do
    update_in(state, [Access.key(cache), schema], &Kernel.++(values, &1 || []))
  end

  defp maybe_send_batch(%__MODULE__{} = state, schema) do
    state
    |> maybe_send_batch(:field_cache, schema, state.field_cache[schema])
    |> maybe_send_batch(:path_cache, schema, state.path_cache[schema])
  end

  defp maybe_send_batch(%__MODULE__{threshold: threshold} = state, cache, schema, batch)
       when length(batch) >= threshold do
    Kernel.apply(state.backend, record_hit_function(cache), [schema, batch])
    reset(state, cache, schema)
  end

  defp maybe_send_batch(%__MODULE__{} = state, _, _, _), do: state

  defp record_hit_function(:path_cache), do: :record_path_hits
  defp record_hit_function(:field_cache), do: :record_field_hits

  defp get_all_hits_function(:path_cache), do: :get_all_path_hits
  defp get_all_hits_function(:field_cache), do: :get_all_field_hits

  defp get_cache(%__MODULE__{} = state, cache, schema) do
    state
    |> Map.get(cache)
    |> Map.get(schema, [])
    |> Enum.frequencies()
  end

  defp reset(%__MODULE__{} = state, cache, schema),
    do: put_in(state, [Access.key(cache), schema], [])

  defp noreply(state), do: {:noreply, state}
  defp reply(response, state), do: {:reply, response, state}
end
