defmodule Apix.Mixfile do
  use Mix.Project

  @version "0.2.1"
  @github "https://github.com/liveforeverx/apix"

  def project do
    [
      app: :apix,
      elixir: "~> 1.7",
      version: @version,
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      name: "Apix",
      source_url: @github,
      description: description(),
      package: package(),
      deps: deps()
    ]
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
    [
      maintainers: ["Dmitry Russ(Aleksandrov)"],
      links: %{"Github" => @github},
      licenses: ["Apache 2.0"]
    ]
  end

  defp deps do
    [{:ex_doc, ">= 0.0.0", only: :dev, runtime: false}]
  end
end
