defmodule Ehealth.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:distillery, "~> 1.5", runtime: false},
      {:excoveralls, "~> 0.8.1", only: [:dev, :test]},
      {:credo, "~> 0.9.0-rc3", only: [:dev, :test]}
    ]
  end
end
