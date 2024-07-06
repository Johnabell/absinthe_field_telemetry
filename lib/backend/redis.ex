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

  ## Public API

  @spec start :: :ignore | {:error, any} | {:ok, pid}
  def start, do: start([])

  @spec start(keyword()) :: :ignore | {:error, any} | {:ok, pid}
  def start(args), do: GenServer.start(__MODULE__, args, name: __MODULE__)

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  def start_link, do: start_link([])

  @spec start_link(keyword()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(args), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)

  @spec stop :: any
  def stop, do: GenServer.call(__MODULE__, :stop)

  @config Application.compile_env(:absinthe_field_telemetry, [:redis, :config],
            expiry_ms: 60_000 * 60 * 4,
            redis_url: "redis://localhost:6379/1"
          )

  @impl AbsintheFieldTelemetry.Backend
  def setup() do
    start_link(@config)
    :ok
  end

  @impl AbsintheFieldTelemetry.Backend
  def record_field_hit(schema, path),
    do: GenServer.cast(__MODULE__, {:incr_field, {schema, Enum.join(path, ":")}})

  @impl AbsintheFieldTelemetry.Backend
  def record_field_hit(schema, type, field),
    do: GenServer.cast(__MODULE__, {:incr_type, {schema, "#{type}:#{field}"}})

  @impl AbsintheFieldTelemetry.Backend
  def get_all_hits(schema), do: GenServer.call(__MODULE__, {:field_hits, schema})

  @impl AbsintheFieldTelemetry.Backend
  def get_all_type_hits(schema), do: GenServer.call(__MODULE__, {:type_hits, schema})

  @impl AbsintheFieldTelemetry.Backend
  def reset(schema), do: GenServer.cast(__MODULE__, {:delete, schema})

  ## GenServer Callbacks

  @impl GenServer
  def init(args) do
    expiry_ms = Keyword.get(args, :expiry_ms)

    if !expiry_ms do
      raise RuntimeError, "Missing required config: expiry_ms"
    end

    key_prefix = Keyword.get(args, :key_prefix, "AbsintheFieldTelemetry:Redis:")

    redix_config =
      Keyword.get(
        args,
        :redix_config,
        Keyword.get(args, :redis_config, [])
      )

    redis_url = Keyword.get(args, :redis_url, nil)

    {:ok, redix} =
      if is_binary(redis_url) && byte_size(redis_url) > 0 do
        Redix.start_link(redis_url, redix_config)
      else
        Redix.start_link(redix_config)
      end

    {:ok, %__MODULE__{redix: redix, expiry_ms: expiry_ms, key_prefix: key_prefix}}
  end

  @impl GenServer
  def handle_call(:stop, _from, state), do: {:stop, :normal, :ok, state}

  def handle_call({:field_hits, schema}, _from, state),
    do: {:reply, do_get_field_hits(state, schema), state}

  def handle_call({:type_hits, schema}, _from, state),
    do: {:reply, do_get_type_hits(state, schema), state}

  @impl GenServer
  def handle_cast({:incr_field, {schema, field}}, state) do
    Redix.noreply_command(state.redix, ["HINCRBY", redis_field_key(state, schema), field, 1])

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:incr_type, {schema, field}}, state) do
    Redix.command(state.redix, ["HINCRBY", redis_type_key(state, schema), field, 1])

    {:noreply, state}
  end

  def handle_cast({:delete, schema}, state) do
    Redix.noreply_command(state.redix, ["DEL", redis_type_key(state, schema)])
    Redix.noreply_command(state.redix, ["DEL", redis_field_key(state, schema)])

    {:noreply, state}
  end

  def do_get_type_hits(%__MODULE__{redix: redix} = state, schema) do
    case Redix.command(redix, ["HGETALL", redis_type_key(state, schema)]) do
      {:ok, result} ->
        result
        |> Enum.chunk_every(2)
        |> Enum.map(fn [key, count] ->
          [type, field] =
            key
            |> String.split(":", parts: 2)
            |> Enum.map(&String.to_atom/1)

          {{type, field}, String.to_integer(count)}
        end)

      _ ->
        []
    end
  end

  def do_get_field_hits(%__MODULE__{redix: redix} = state, schema) do
    case Redix.command(redix, ["HGETALL", redis_field_key(state, schema)]) do
      {:ok, result} ->
        result
        |> Enum.chunk_every(2)
        |> Enum.map(fn [key, count] ->
          {String.split(key, ":"), String.to_integer(count)}
        end)

      _ ->
        []
    end
  end

  defp redis_field_key(%__MODULE__{key_prefix: prefix}, schema), do: "#{prefix}:#{schema}:field"
  defp redis_type_key(%__MODULE__{key_prefix: prefix}, schema), do: "#{prefix}:#{schema}:type"
end
