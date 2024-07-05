defmodule AbsintheFieldTelemetry.Types.Node do
  use TypedStruct

  typedstruct do
    field :name, String.t()
    field :count, integer(), default: 0
    field :fields, [t()], default: []
  end

  def root() do
    %__MODULE__{name: "root"}
  end

  def add_field(%__MODULE__{} = object, {[name], count}) do
    %__MODULE__{
      object
      | fields: [
          %__MODULE__{name: name, count: count} | object.fields
        ]
    }
  end

  def add_field(%__MODULE__{} = object, {[initial | rest], count}) do
    update_in(
      object,
      [Access.key(:fields), Access.filter(fn object -> object.name == initial end)],
      &add_field(&1, {rest, count})
    )
  end
end
