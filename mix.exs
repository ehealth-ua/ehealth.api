defmodule Ehealth.MixProject do
  @moduledoc false

  use Mix.Project

  @version "8.13.2"
  def project do
    [
      apps_path: "apps",
      version: @version,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      docs: [
        filter_prefix: "*.Rpc"
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
      {:distillery, "~> 2.0", runtime: false},
      {:excoveralls, "~> 0.10", only: [:dev, :test]},
      {:ex_doc, "~> 0.19.2", only: :dev, runtime: false},
      {:credo, "~> 1.0", only: [:dev, :test]},
      {:git_ops, git: "https://github.com/AlexKovalevych/git_ops.git", branch: "fix_version_compare", only: [:dev]}
    ]
  end
end
