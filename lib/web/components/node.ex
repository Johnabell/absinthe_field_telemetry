defmodule AbsintheFieldTelemetry.Web.Components.Node do
  use Phoenix.Component

  attr :field, :map

  def object(assigns) do
    ~H"""
    <ul style="list-style-type: none;">
      <li>└ <%= @field.name %> <%= @field.count %></li>
      <%= if @field.fields != [] do %>
        <%= for child_field <- @field.fields do %>
          <%= object(%{field: child_field}) %>
        <% end %>
      <% end %>
    </ul>
    """
  end
end
