defmodule AbsintheFieldTelemetry.Web.Components.Home do
  alias AbsintheFieldTelemetry.Web.Components
  use Phoenix.Component

  @styles """
  :root {
    --color-destructive-red: #be261b;
    --color-default-button: #008CBA;
  }
  a, u {
    text-decoration: none;
    color: inherit;
  }
  details {
    padding: 10px;
    background-color: #e4eaef;
    border-radius: 5px;
    margin: 8px;
  }
  details summary {
    cursor: pointer;
    transition: margin 150ms ease-out;
  }

  details[open] summary {
    margin-bottom: 10px;
  }

  details[open] summary ~ * {
    animation: sweep .5s ease-in-out;
  }

  @keyframes sweep {
    0%    {opacity: 0; margin-left: -10px; max-height: 0}
    100%  {opacity: 1; margin-left: 0px; max-height: 100%}
  }

  .button_bar {
    margin: 8px;
    display: inline-flex;
    justify-content: space-between;
    width: calc(100% - 16px);
  }

  .button {
    border-radius: 8px;
    background-color: white;
    color: black;
    border: 2px solid var(--color-default-button);
    padding: 8px 16px;
    text-align: center;
    text-decoration: none;
    display: inline-block;
    font-size: 16px;
    height: fit-content;
    margin: auto 2px;
    transition-duration: 0.4s;
    cursor: pointer;
  }
  .button:hover {
    background-color: var(--color-default-button);
    color: white;
  }
  .button_destructive {
    border: 2px solid var(--color-destructive-red);
  }
  .button_destructive:hover {
    background-color: var(--color-destructive-red);
    color: white;
  }
  body {
    font: normal 16px Arial, sans-serif;
    max-width: 740;
    margin: auto;
  }
  """

  attr :types, :list
  attr :base_url, :string
  attr :styles, :string, default: @styles

  def home(assigns) do
    ~H"""
    <title>Type view</title>
    <style>
      <%= @styles %>
    </style>
    <div class="button_bar">
      <a class="button" href={"#{@base_url}/refresh"}>
        <span style="font-size: 20px">⟲</span> Refresh
      </a>
      <h1>GraphQL usage by type</h1>
      <a class="button button_destructive" href={"#{@base_url}/reset"}>🗑 Reset</a>
    </div>
    <%= for type <- @types do %>
      <Components.Object.object object={type} />
    <% end %>
    """
  end

  attr :root, :map
  attr :styles, :string, default: @styles

  def tree(assigns) do
    ~H"""
    <title>Tree view</title>
    <style>
      <%= @styles %>
    </style>
    <Components.Node.object field={@root} />
    """
  end
end
