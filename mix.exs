defmodule Stopsel.MixProject do
  use Mix.Project

  def project do
    [
      app: :stopsel,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      description: description(),
      source_url: "https://github.com/Awlexus/stopsel",
      docs: [
        main: "Stopsel",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Stopsel.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:router, "~> 1.0"},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ~w"lib test/support"
  defp elixirc_paths(_), do: ~w"lib"

  defp description() do
    "A platform independent text message router"
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/Awlexus/stopsel"}
    ]
  end
end
