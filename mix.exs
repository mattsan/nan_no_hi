defmodule NanNoHi.MixProject do
  use Mix.Project

  def project do
    [
      app: :nan_no_hi,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:nimble_csv, "~> 1.3"},
      {:credo, "~> 1.7", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},
      {:ex_doc, "~> 0.38.2", only: :dev, runtime: false}
    ]
  end

  def docs do
    [
      extras: [
        "README.md"
      ],
      main: "readme",
      groups_for_docs: [
        Guards: &(&1[:guard] == true)
      ]
    ]
  end
end
