defmodule AbsintheFieldTelemetry.Backend.Batch do
  @moduledoc """
    This implementation of the backend is provided to be a wrapper around
    another backend.

    The idea related to this backend is that it will cache field hits
    in memory and then report them in batches of size `threshold` the other
    backend.
    
    This is designed to improve performance and throughput when a backend
    requires a network call.

    The backend process is started by calling `start_link`:

        AbsintheFieldTelemetry.Backend.Batch.start_link(
          threshold: 10_000,
          interval_ms: 60_000 * 10,
          backend: {AbsintheFieldTelemetry.Backend.Ets, []}
        )

    Options are:

    - `interval_ms`: If set, this backend will report all unreported cached hits
      every `interval_ms`.
    - `threshold`: The number of hits to cash before reporting the backend (required)
    - `backend`: The persistence backend (required)
  """
  import TypedStruct

  alias AbsintheFieldTelemetry.Backend

  typedstruct enforce: true do
    field :field_cache, %{required(atom) => list()}, default: %{}
    field :threshold, integer()
    field :backend, AbsintheFieldTelemetry.Backend.t()
  end

  @behaviour Backend

  use GenServer

  @spec start :: :ignore | {:error, any} | {:ok, pid}
  @spec start(keyword()) :: :ignore | {:error, any} | {:ok, pid}
  def start(args \\ []), do: GenServer.start(__MODULE__, args, name: __MODULE__)

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  @spec start_link(keyword()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(args \\ []), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)

  @spec stop :: any
  def stop, do: GenServer.call(__MODULE__, :stop)

  @impl AbsintheFieldTelemetry.Backend
  def record_field_hits(schema, fields),
    do: GenServer.cast(__MODULE__, {:incr_fields, {schema, fields}})

  @impl AbsintheFieldTelemetry.Backend
  def get_all_field_hits(schema), do: GenServer.call(__MODULE__, {:field_hits, schema})

  @impl AbsintheFieldTelemetry.Backend
  def reset(schema), do: GenServer.cast(__MODULE__, {:reset, schema})

  @impl GenServer
  def init(args) do
    threshold = get_config!(args, :threshold)

    args
    |> Keyword.get(:interval_ms)
    |> schedule_interval()

    {backend, args} = get_config!(args, :backend)
    backend.start_link(args)

    {:ok, %__MODULE__{threshold: threshold, backend: backend}}
  end

  defp schedule_interval(nil), do: :ok
  defp schedule_interval(interval), do: :timer.send_interval(interval, :send_all)

  def get_config!(args, key) do
    case Keyword.get(args, key) do
      nil -> raise "Missing configuration #{key} must be provided as part of the config"
      value -> value
    end
  end

  @impl GenServer
  def handle_cast({:incr_fields, {schema, fields}}, state),
    do: do_incr(state, :field_cache, schema, fields)

  def handle_cast({:reset, schema}, state) do
    state.backend.reset(schema)

    state
    |> reset(:field_cache, schema)
    |> noreply()
  end

  @impl GenServer
  def handle_info(:send_all, state) do
    state
    |> send_all()
    |> noreply()
  end

  @impl GenServer
  def handle_call({:field_hits, schema}, _, state), do: do_get_hits(state, :field_cache, schema)

  def handle_call(:stop, _from, state) do
    state = send_all(state)
    state.backend.stop()
    {:stop, :normal, :ok, state}
  end

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
  end

  defp maybe_send_batch(%__MODULE__{threshold: threshold} = state, cache, schema, batch)
       when length(batch) >= threshold do
    send_batch(state, cache, schema, batch)
    reset(state, cache, schema)
  end

  defp maybe_send_batch(%__MODULE__{} = state, _, _, _), do: state

  defp send_batch(%__MODULE__{}, _, _, []), do: :ok

  defp send_batch(%__MODULE__{} = state, cache, schema, batch),
    do: Kernel.apply(state.backend, record_hit_function(cache), [schema, batch])

  defp send_all(%__MODULE__{} = state) do
    Enum.each([:field_cache], &send_all(state, &1))
    %__MODULE__{state | field_cache: %{}}
  end

  defp send_all(%__MODULE__{} = state, cache) do
    state
    |> Map.get(cache)
    |> Enum.each(fn {schema, batch} -> send_batch(state, cache, schema, batch) end)
  end

  defp record_hit_function(:field_cache), do: :record_field_hits

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
