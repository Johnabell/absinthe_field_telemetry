defmodule AbsintheFieldTelemetry.Types.Object do
  @moduledoc false

  use TypedStruct

  alias AbsintheFieldTelemetry.Types.Location
  alias AbsintheFieldTelemetry.Types.Field

  typedstruct do
    field :name, String.t()
    field :count, integer()
    field :identifier, atom()
    field :location, Location.t()
    field :fields, [Field.t()]
  end

  def from_absinthe_type_and_hits(%Absinthe.Type.Object{} = object, hits) do
    count =
      hits
      |> Keyword.put(:__default, 0)
      |> Keyword.values()
      |> Enum.max()

    %__MODULE__{
      name: object.name,
      identifier: object.identifier,
      count: count,
      fields: Field.from_fields_map_and_hits(object.fields, hits),
      location: Location.from_map(object.__reference__.location)
    }
  end

  def percentage_hit(%__MODULE__{fields: fields}, opts \\ [reject_internal: true]) do
    fields =
      if Keyword.get(opts, :reject_internal) do
        Enum.reject(fields, &Field.internal?/1)
      else
        fields
      end

    hits = Enum.count(fields, &Field.hit?/1)
    total = Enum.count(fields)

    hits / total
  end

  def color(%__MODULE__{} = object) do
    case percentage_hit(object) do
      0.0 -> :red
      1.0 -> :green
      _ -> :orange
    end
  end

  def internal?(%__MODULE__{name: "__" <> _}), do: true
  def internal?(_), do: false
end
