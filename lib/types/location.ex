defmodule AbsintheFieldTelemetry.Types.Location do
  use TypedStruct

  typedstruct do
    field :file, String.t()
    field :line, integer()
  end

  def from_map(%{file: file, line: line}), do: %__MODULE__{file: file, line: line}
end
