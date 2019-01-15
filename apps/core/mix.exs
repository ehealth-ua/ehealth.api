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
      elixir: "~> 1.7",
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
      {:bamboo, "~> 0.8"},
      {:bamboo_postmark, "~> 0.2.0"},
      {:bamboo_smtp, "~> 1.4.0"},
      {:cipher, "~> 1.3"},
      {:confex, "~> 3.4"},
      {:csv, "~> 2.1"},
      {:ecto, "~> 2.1"},
      {:ecto_trail, "0.2.3"},
      {:eview, "~> 0.15"},
      {:kube_rpc, git: "https://github.com/edenlabllc/kube_rpc.git"},
      {:libcluster, "~> 3.0", git: "https://github.com/AlexKovalevych/libcluster.git", branch: "kube_namespaces"},
      {:ecto_logger_json, git: "https://github.com/edenlabllc/ecto_logger_json.git", branch: "query_params"},
      {:geo, "~> 1.4"},
      {:guardian, "~> 1.1"},
      {:httpoison, "~> 1.4"},
      {:jason, "~> 1.0"},
      {:jvalid, "~> 0.7"},
      {:phoenix_ecto, "~> 3.2"},
      {:plug, "~> 1.4"},
      {:postgrex, ">= 0.0.0"},
      {:scrivener_ecto, "~> 1.3.0"},
      {:timex, "~> 3.2"},
      {:translit, "~> 0.1.0"},
      {:mox, "~> 0.3", only: :test},
      {:kafka_ex, "~> 0.9.0"},
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
        "ecto.migrate"
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
