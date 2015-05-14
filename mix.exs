defmodule Apix.Mixfile do
  use Mix.Project

  @version "0.1.0"
  @github "https://github.com/liveforeverx/apix"

  def project do
    [app: :apix,
     version: @version,
     elixir: "~> 1.1-dev",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     name: "Apix",
     source_url: @github,
     description: description,
     package: package,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  defp description do
    "Simple convention and DSL for transformation of elixir functions to a documented and ready for validation API."
  end

  defp package do
    [contributors: ["Dmitry Russ(Aleksandrov)"],
     links: %{"Github" => @github}]
  end

  defp deps do
    []
  end
end

