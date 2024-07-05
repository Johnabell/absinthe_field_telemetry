defmodule AbsintheFieldTelemetry.Types.Field do
  @moduledoc false

  use TypedStruct

  alias AbsintheFieldTelemetry.Types.Location

  typedstruct do
    field :name, String.t()
    field :type, atom()
    field :count, integer()
    field :location, Location.t()
  end

  def from_absinthe_type_and_hits(%Absinthe.Type.Field{} = field, count) do
    %__MODULE__{
      name: field.name,
      type: Absinthe.Type.unwrap(field.type),
      count: count,
      location: Location.from_map(field.__reference__.location)
    }
  end

  def from_fields_map_and_hits(fields, hits) do
    fields
    |> Map.values()
    |> Enum.map(&from_absinthe_type_and_hits(&1, Keyword.get(hits, &1.identifier, 0)))
  end

  def hit?(%__MODULE__{count: 0}), do: false
  def hit?(%__MODULE__{}), do: true

  def color(%__MODULE__{count: 0}), do: :red
  def color(%__MODULE__{}), do: :green

  def internal?(%__MODULE__{name: "__" <> _}), do: true
  def internal?(_), do: false
end
