defmodule AbsintheFieldTelemetry.MixProject do
  use Mix.Project

  @version "0.1.0"
  @description """
  A library for analysing absinthe GraphQL runtime usage.
  """

  def project do
    [
      app: :absinthe_field_telemetry,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: @description,
      package: package(),
      source_url: "https://github.com/Johnabell/absinthe_field_telemetry"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test]},
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.28", only: :dev},
      {:mock, "~> 0.3.7", only: :test},
      {:phoenix, "~> 1.7.11"},
      {:phoenix_live_view, "~> 0.20"},
      {:floki, ">= 0.30.0", only: :test},
      {:redix, "~> 1.1"},
      {:absinthe, "~> 1.5"},
      {:typed_struct, "~> 0.3.0"}
    ]
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/Johnabell/absinthe_field_telemetry"}
    ]
  end
end
