defmodule Core.MixProject do
  use Mix.Project

  def project do
    [
      app: :core,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.6",
      compilers: Mix.compilers(),
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Core.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:jason, "~> 1.0"},
      {:httpoison, "~> 1.1.0"},
      {:timex, "~> 3.2"},
      {:plug, "~> 1.4"},
      {:confex, "~> 3.2"},
      {:eview, "~> 0.12.2"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:ecto, "~> 2.1"},
      {:scrivener_ecto, "~> 1.2"},
      {:ecto_trail, "0.2.3"},
      {:bamboo, "~> 0.8"},
      {:bamboo_postmark, "~> 0.2.0"},
      {:bamboo_smtp, "~> 1.4.0"},
      {:guardian, "~> 1.0"},
      {:geo, "~> 1.4"},
      {:jvalid, "~> 0.6.0"},
      {:cipher, "~> 1.3"},
      {:translit, "~> 0.1.0"},
      {:csv, "~> 2.0.0"},
      {:ecto_logger_json, git: "https://github.com/edenlabllc/ecto_logger_json.git", branch: "query_params"},
      {:mox, "~> 0.3", only: :test},
      {:ex_machina, "~> 2.0", only: [:dev, :test]}
    ]
  end

  defp aliases do
    [
      "ecto.setup": [
        "ecto.create",
        "ecto.create --repo Core.FraudRepo",
        "ecto.create --repo Core.PRMRepo",
        "ecto.create --repo Core.EventManagerRepo",
        "ecto.migrate",
        "run priv/repo/seeds.exs"
      ],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: [
        "ecto.create --quiet",
        "ecto.create --quiet --repo Core.PRMRepo",
        "ecto.create --quiet --repo Core.EventManagerRepo",
        "ecto.migrate",
        "test"
      ]
    ]
  end
end
