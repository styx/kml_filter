defmodule KmlFilter.Mixfile do
  use Mix.Project

  def project do
    [
      app: :kml_filter,
      version: "0.1.0",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      escript: escript,
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :sweet_xml]]
  end

  defp escript do
    [main_module: KmlFilter]
  end

  defp deps do
    [
      {:sweet_xml, "~> 0.6"}
    ]
  end
end
