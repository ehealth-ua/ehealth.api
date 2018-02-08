defmodule EHealth.Mixfile do
  @moduledoc false

  use Mix.Project

  @version "7.29.1"

  def project do
    [
      app: :ehealth,
      description: "Integration Layer for projects that related to Ukrainian Health Services government institution.",
      package: package(),
      version: @version,
      elixir: "~> 1.5",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      preferred_cli_env: [coveralls: :test],
      test_coverage: [tool: ExCoveralls],
      docs: [source_ref: "v#\{@version\}", main: "readme", extras: ["README.md"]]
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
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_), do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:confex, "~> 3.2"},
      {:timex, ">= 3.1.15"},
      {:poison, "~> 3.1"},
      {:plug, "~> 1.4"},
      {:cowboy, "~> 1.1"},
      {:httpoison, "~> 0.12"},
      {:csv, "~> 2.0.0"},
      # fix for https://github.com/edgurgel/httpoison/issues/264
      {:hackney, "== 1.8.0", override: true},
      {:postgrex, ">= 0.0.0"},
      {:ecto, "~> 2.1"},
      {:scrivener_ecto, "~> 1.2"},
      {:ecto_trail, "0.2.3"},
      {:phoenix, "~> 1.3.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:eview, "~> 0.12.2"},
      {:jvalid, "~> 0.6.0"},
      {:bamboo, "~> 0.8"},
      {:bamboo_postmark, "~> 0.2.0"},
      {:bamboo_smtp, "~> 1.4.0"},
      {:geo, "~> 1.4"},
      {:quantum, ">= 2.1.0"},
      {:plug_logger_json, "~> 0.5"},
      {:cipher, "~> 1.3"},
      {:ex_doc, ">= 0.15.0", only: [:dev, :test]},
      {:ex_machina, "~> 2.0", only: [:dev, :test]}
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

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": [
        "ecto.create",
        "ecto.create --repo EHealth.FraudRepo",
        "ecto.create --repo EHealth.PRMRepo",
        "ecto.create --repo EHealth.EventManagerRepo",
        "ecto.migrate",
        "run priv/repo/seeds.exs"
      ],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: [
        "ecto.create --quiet",
        "ecto.create --quiet --repo EHealth.PRMRepo",
        "ecto.create --quiet --repo EHealth.EventManagerRepo",
        "ecto.migrate",
        "test"
      ]
    ]
  end
end
