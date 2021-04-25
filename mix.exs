defmodule Diff.Mixfile do
  use Mix.Project

  def project do
    [
      app: :diff,
      name: "Diff",
      version: "1.1.0",
      elixir: "~> 1.10",
      description: description(),
      package: package(),
      source_url: "https://github.com/bryanjos/diff",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.24", only: :dev},
      {:credo, "~> 1.0", only: :dev},
      {:stream_data, "~> 0.5", only: :test},
      {:benchee, "~> 1.0", only: :dev}
    ]
  end

  defp description do
    """
    A simple diff library
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*", "CHANGELOG*"],
      maintainers: ["Bryan Joseph"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/bryanjos/diff"
      }
    ]
  end
end
