defmodule Diff.Mixfile do
  use Mix.Project

  def project do
    [app: :diff,
     name: "Diff",
     version: "1.1.0",
     elixir: "~> 1.0",
     description: description,
     package: package,
     source_url: "https://github.com/bryanjos/diff",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:earmark, "~> 0.2", only: :dev },
      {:ex_doc, "~> 0.11", only: :dev },
      {:credo, "~> 0.2.0", only: :dev }
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
