defmodule EHealth.Mixfile do
  use Mix.Project

  @version "6.37.0"

  def project do
    [app: :ehealth,
     description: "Integration Layer for projects that related to Ukrainian Health Services government institution.",
     package: package(),
     version: @version,
     elixir: "~> 1.5",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps(),
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: [coveralls: :test],
     docs: [source_ref: "v#\{@version\}", main: "readme", extras: ["README.md"]]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [extra_applications: [:logger, :runtime_tools],
     mod: {EHealth, []}]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:myapp, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:distillery, "~> 1.4.1"},
     {:confex, "~> 3.2"},
     {:timex, ">= 3.1.15"},
     {:poison, "~> 3.1"},
     {:plug, "~> 1.4"},
     {:cowboy, "~> 1.1"},
     {:httpoison, "~> 0.12"},
     {:hackney, "== 1.8.0", override: true}, # fix for https://github.com/edgurgel/httpoison/issues/264
     {:postgrex, ">= 0.0.0"},
     {:ecto, "~> 2.1"},
     {:scrivener_ecto, "~> 1.2"},
     {:ecto_trail, "~> 0.2.3"},
     {:phoenix, "~> 1.3.0"},
     {:phoenix_ecto, "~> 3.2"},
     {:eview, "~> 0.12.2"},
     {:jvalid, "~> 0.6.0"},
     {:bamboo, "~> 0.8"},
     {:bamboo_postmark, "~> 0.2.0"},
     {:geo, "~> 1.4"},
     {:quantum, ">= 2.1.0"},
     {:plug_logger_json, "~> 0.5"},
     {:excoveralls, ">= 0.5.0", only: [:dev, :test]},
     {:ex_machina, "~> 2.0", only: [:dev, :test]},
     {:dogma, ">= 0.1.12", only: [:dev, :test]},
     {:credo, ">= 0.5.1", only: [:dev, :test]}]
  end

  # Settings for publishing in Hex package manager:
  defp package do
    [contributors: ["edenlabllc"],
     maintainers: ["edenlabllc"],
     licenses: ["LISENSE.md"],
     links: %{github: "https://github.com/edenlabllc/ehealth.api"},
     files: ~w(lib LICENSE.md mix.exs README.md)]
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
        "ecto.migrate",
        "run priv/repo/seeds.exs"
      ],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "test": [
        "ecto.create --quiet",
        "ecto.create --quiet --repo EHealth.PRMRepo",
        "ecto.migrate",
        "test"
      ]
    ]
  end
end
