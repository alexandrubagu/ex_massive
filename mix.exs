defmodule ExMassive.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_massive,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Elixir SDK for Massive.com financial data API",
      package: package()
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/yourusername/ex_massive"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExMassive.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.11"},
      {:jason, "~> 1.4"},
      {:hackney, "~> 1.20"},
      {:websockex, "~> 0.4.3"}
    ]
  end
end
