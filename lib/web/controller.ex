defmodule AbsintheFieldTelemetry.Web.Controller do
  @moduledoc false

  use Phoenix.Controller
  @error "Unrecognised schema"

  def home(conn, params) do
    %{
      types: AbsintheFieldTelemetry.get_type_hits(get_schema!(params)),
      base_url: conn.request_path
    }
    |> AbsintheFieldTelemetry.Web.Components.Home.home()
    |> Phoenix.HTML.Safe.to_iodata()
    |> then(&html(conn, &1))
  rescue
    _ -> text(conn, @error)
  end

  def tree(conn, params) do
    %{root: AbsintheFieldTelemetry.get_all(get_schema!(params))}
    |> AbsintheFieldTelemetry.Web.Components.Home.tree()
    |> Phoenix.HTML.Safe.to_iodata()
    |> then(&html(conn, &1))
  rescue
    _ -> text(conn, @error)
  end

  def reset(conn, params) do
    params
    |> get_schema!()
    |> AbsintheFieldTelemetry.Backend.reset()

    refresh(conn, params)
  rescue
    _ -> text(conn, @error)
  end

  defp get_schema!(%{"schema" => schema}), do: get_schema!(schema)
  defp get_schema!("Elixir." <> _ = schema), do: String.to_existing_atom(schema)
  defp get_schema!(schema) when is_binary(schema), do: get_schema!("Elixir." <> schema)

  def refresh(conn, _params) do
    redirect(conn, to: Path.dirname(conn.request_path))
  end

  def schema, do: Stonehenge.Public.Graphql.Schema
end
