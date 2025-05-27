defmodule AbsintheFieldTelemetry.Web.Components.Object do
  @moduledoc false

  alias AbsintheFieldTelemetry.Types.Object
  alias AbsintheFieldTelemetry.Types.Field
  alias AbsintheFieldTelemetry.Types.Location

  use Phoenix.Component

  attr :object, Object

  def object(assigns) do
    ~H"""
    <%= unless Object.internal?(@object) do %>
      <details open={Object.color(@object) == :orange}>
        <summary>
          <a id={@object.identifier}>
            <div style="display: inline-flex; justify-content: space-between; width: calc(100% - 1.37em);">
              <span>{@object |> Object.color() |> color()} {@object.name}</span>
              <span>{(Object.percentage_hit(@object) * 100) |> Float.round(0)}%</span>
            </div>
          </a>
          <.file_reference location={@object.location} />
        </summary>
        <ul style="list-style-type: none;">
          <%= for field <- Enum.reject(@object.fields, &Field.internal?/1) do %>
            <li><.field field={field} /></li>
          <% end %>
        </ul>
      </details>
    <% end %>
    """
  end

  attr :field, Field

  def field(assigns) do
    ~H"""
    <a href={"##{@field.type}"}>
      {@field |> Field.color() |> color()} {@field.name} (hit count: {@field.count})
    </a>
    <.file_reference location={@field.location} />
    """
  end

  attr :location, Location

  def file_reference(assigns) do
    ~H"""
    <div style="color: grey; font-size: 0.8rem;">
      {@location.file}:{@location.line}
    </div>
    """
  end

  def color(:red), do: "🔴"
  def color(:orange), do: "🟠"
  def color(:green), do: "🟢"
end
