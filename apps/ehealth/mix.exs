defmodule EHealth.Mixfile do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :ehealth,
      description: "Integration Layer for projects that related to Ukrainian Health Services government institution.",
      package: package(),
      version: "0.1.0",
      elixir: "~> 1.6",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: [coveralls: :test],
      test_coverage: [tool: ExCoveralls],
      docs: [source_ref: "v#\{@version\}", main: "readme", extras: ["README.md"]],
      aliases: aliases()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {EHealth, []},
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:core, in_umbrella: true},
      {:confex, "~> 3.2"},
      {:poison, "~> 3.1"},
      {:httpoison, "~> 1.1.0"},
      {:phoenix, "~> 1.4.0-rc.3", override: true},
      {:phoenix_ecto, "~> 3.2"},
      {:plug_cowboy, "~> 2.0"},
      {:ecto, "~> 2.1"},
      {:ecto_trail, "0.2.3"},
      {:eview, "~> 0.12.2"},
      {:jvalid, "~> 0.6.0"},
      {:quantum, "~> 2.2"},
      {:plug_logger_json, "~> 0.5"},
      {:jason, "~> 1.1"},
      {:nex_json_schema, ">= 0.7.2"},
      {:mox, "~> 0.3", only: :test},
      {:ex_doc, ">= 0.15.0", only: [:dev, :test]}
    ]
  end

  # Settings for publishing in Hex package manager:
  defp package do
    [
      contributors: ["edenlabllc"],
      maintainers: ["edenlabllc"],
      licenses: ["LISENSE.md"],
      links: %{github: "https://github.com/edenlabllc/ehealth.api"},
      files: ~w(lib LICENSE.md mix.exs README.md)
    ]
  end

  defp aliases do
    [
      "ecto.setup": &ecto_setup/1
    ]
  end

  defp ecto_setup(_) do
    Mix.shell().cmd("cd ../core && mix ecto.setup && cd ../ehealth")
  end
end
