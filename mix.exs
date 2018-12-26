defmodule Ehealth.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      docs: [
        filter_prefix: "Casher.Rpc"
      ]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:distillery, "~> 1.5.3", runtime: false},
      {:excoveralls, "~> 0.10", only: [:dev, :test]},
      {:ex_doc, "~> 0.19.2", only: :dev, runtime: false},
      {:credo, "~> 1.0", only: [:dev, :test]}
    ]
  end
end
