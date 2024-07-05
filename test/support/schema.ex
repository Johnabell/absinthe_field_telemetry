defmodule AbsintheFieldTelemetry.Test.Support.Schema do
  @moduledoc """
    A test absinth schema
  """
  use Absinthe.Schema

  object :user do
    field :id, :id
    field :name, :string
  end

  query do
    field :user, :user do
      resolve fn _, _ -> {:ok, %{id: "id", name: "John Smith"}} end
    end
  end

  def middleware(middleware, _field, _object),
    do: [AbsintheFieldTelemetry.Middleware | middleware]
end
