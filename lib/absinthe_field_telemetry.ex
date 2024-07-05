defmodule AbsintheFieldTelemetry do
  alias AbsintheFieldTelemetry.Backend
  alias AbsintheFieldTelemetry.Types

  def setup(), do: Backend.setup()

  def get_all(schema) do
    schema
    |> Backend.get_all_hits()
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.reduce(Types.Node.root(), &Types.Node.add_field(&2, &1))
  end

  def get_type_hits(schema) do
    hits =
      schema
      |> Backend.get_all_type_hits()
      |> Enum.group_by(&elem(elem(&1, 0), 0), fn {{_, field}, count} -> {field, count} end)

    schema
    |> Absinthe.Schema.types()
    |> Enum.filter(&is_struct(&1, Absinthe.Type.Object))
    |> Enum.map(&Types.Object.from_absinthe_type_and_hits(&1, Map.get(hits, &1.identifier, [])))
    |> Enum.sort_by(& &1.name)
  end
end
