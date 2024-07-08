defmodule AbsintheFieldTelemetry.Backend.Redis do
  @moduledoc """
  Documentation for AbsintheFieldTelemetry.Backend.Redis

  This backend uses the [Redix](https://hex.pm/packages/redix) library to connect to Redis.

  The backend process is started by calling `start_link`:

      AbsintheFieldTelemetry.Backend.Redis.start_link(
        expiry_ms: 60_000 * 10,
        redix_config: [host: "example.com", port: 5050]
      )

  Options are:

  - `expiry_ms`: Expiry time of buckets in milliseconds,
    used to set TTL on Redis keys. This configuration is mandatory.
  - `redix_config`: Keyword list of options to the `Redix` redis client,
    also aliased to `redis_config`
  - `key_prefix`: The prefix to use for all the redis keys (defaults to "AbsintheFieldTelemetry:Redis:")
  - `redis_url`: String url of redis server to connect to
    (optional, invokes Redix.start_link/2)
  """
  use TypedStruct

  typedstruct do
    field :redix, pid()
    field :expiry_ms, integer()
    field :key_prefix, String.t()
  end

  @behaviour AbsintheFieldTelemetry.Backend

  use GenServer

  defguardp is_non_empty_string(value) when is_binary(value) and byte_size(value) > 0

  ## Public API

  @spec start :: :ignore | {:error, any} | {:ok, pid}
  @spec start(keyword()) :: :ignore | {:error, any} | {:ok, pid}
  def start(args \\ []), do: GenServer.start(__MODULE__, args, name: __MODULE__)

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  @spec start_link(keyword()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(args \\ []), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)

  @spec stop :: any
  def stop, do: GenServer.call(__MODULE__, :stop)

  @impl AbsintheFieldTelemetry.Backend
  def record_path_hits(_, []), do: :ok

  def record_path_hits(schema, paths),
    do: GenServer.cast(__MODULE__, {:incr_paths, {schema, paths}})

  @impl AbsintheFieldTelemetry.Backend
  def record_field_hits(_, []), do: :ok

  def record_field_hits(schema, fields),
    do: GenServer.cast(__MODULE__, {:incr_fields, {schema, fields}})

  @impl AbsintheFieldTelemetry.Backend
  def get_all_path_hits(schema), do: GenServer.call(__MODULE__, {:path_hits, schema})

  @impl AbsintheFieldTelemetry.Backend
  def get_all_field_hits(schema), do: GenServer.call(__MODULE__, {:field_hits, schema})

  @impl AbsintheFieldTelemetry.Backend
  def reset(schema), do: GenServer.cast(__MODULE__, {:delete, schema})

  ## GenServer Callbacks

  @impl GenServer
  def init(args) do
    expiry_ms = get_config!(args, :expiry_ms)
    key_prefix = Keyword.get(args, :key_prefix, "AbsintheFieldTelemetry:Redis:")
    redix_config = Keyword.get(args, :redix_config, Keyword.get(args, :redis_config, []))
    redis_url = Keyword.get(args, :redis_url, nil)

    {:ok, redix} = start_redix(redis_url, redix_config)

    {:ok, %__MODULE__{redix: redix, expiry_ms: expiry_ms, key_prefix: key_prefix}}
  end

  defp get_config!(args, key) do
    case Keyword.get(args, key) do
      nil -> raise "Missing configuration #{key} must be provided as part of the config"
      value -> value
    end
  end

  defp start_redix(url, config) when is_non_empty_string(url), do: Redix.start_link(url, config)
  defp start_redix(_, config), do: Redix.start_link(config)

  @impl GenServer
  def handle_call(:stop, _from, state), do: {:stop, :normal, :ok, state}

  def handle_call({:path_hits, schema}, _from, state),
    do: {:reply, do_get_hits(state, schema, :path), state}

  def handle_call({:field_hits, schema}, _from, state),
    do: {:reply, do_get_hits(state, schema, :field), state}

  @impl GenServer
  def handle_cast({:incr_paths, {schema, paths}}, state), do: do_incr(state, schema, paths, :path)

  @impl GenServer
  def handle_cast({:incr_fields, {schema, fields}}, state),
    do: do_incr(state, schema, fields, :field)

  def handle_cast({:delete, schema}, state) do
    commands = Enum.map([:field, :path], &delete_command(state, schema, &1))
    Redix.noreply_pipeline(state.redix, commands)

    {:noreply, state}
  end

  defp do_incr(%__MODULE__{} = state, schema, values, type) do
    commands = Enum.map(values, &incr_command(state, schema, &1, type))
    Redix.noreply_pipeline(state.redix, [expire_command(state, schema, type) | commands])
    {:noreply, state}
  end

  defp do_get_hits(%__MODULE__{redix: redix} = state, schema, type) do
    redix
    |> Redix.command(get_all_command(state, schema, type))
    |> redis_result_to_hits(type)
  end

  defp redis_result_to_hits({:ok, result}, type) do
    result
    |> Enum.chunk_every(2)
    |> Enum.map(fn [key, count] -> {hit_from_key(key, type), String.to_integer(count)} end)
  end

  defp redis_result_to_hits(_, _), do: []

  defp hit_from_key(key, :path), do: String.split(key, ":")

  defp hit_from_key(key, :field) do
    key
    |> String.split(":", parts: 2)
    |> Enum.map(&String.to_atom/1)
    |> List.to_tuple()
  end

  defp incr_command(%__MODULE__{} = state, schema, value, type),
    do: ["HINCRBY", redis_key(state, schema, type), field_key(value), 1]

  defp expire_command(%__MODULE__{} = state, schema, type),
    do: ["EXPIRE", redis_key(state, schema, type), get_expiry(state)]

  defp delete_command(%__MODULE__{} = state, schema, type),
    do: ["DEL", redis_key(state, schema, type)]

  defp get_all_command(%__MODULE__{} = state, schema, type),
    do: ["HGETALL", redis_key(state, schema, type)]

  defp field_key(value) when is_tuple(value), do: value |> Tuple.to_list() |> field_key()
  defp field_key(path), do: Enum.join(path, ":")

  defp redis_key(%__MODULE__{key_prefix: prefix}, schema, type), do: "#{prefix}:#{schema}:#{type}"

  defp get_expiry(%__MODULE__{expiry_ms: expiry_ms}), do: round(expiry_ms / 1000 + 1)
end
