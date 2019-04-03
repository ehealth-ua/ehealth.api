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
      elixir: "~> 1.8.1",
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
      {:deep_merge, "~> 0.1.1"},
      {:ecto, "~> 2.1"},
      {:ecto_trail, "0.2.3"},
      {:eview, "~> 0.15"},
      {:kube_rpc, "~> 0.1.0"},
      {:libcluster, "~> 3.0", git: "https://github.com/AlexKovalevych/libcluster.git", branch: "kube_namespaces"},
      {:geo, "~> 1.4"},
      {:guardian, "~> 1.2.1"},
      {:httpoison, "~> 1.4"},
      {:jason, "~> 1.0"},
      {:jvalid, "~> 0.7"},
      {:nex_json_schema, git: "https://github.com/Nebo15/nex_json_schema.git", override: true},
      {:ehealth_logger, git: "https://github.com/edenlabllc/ehealth_logger.git"},
      {:phoenix_ecto, "~> 3.2"},
      {:plug, "~> 1.4"},
      {:postgrex, ">= 0.0.0"},
      {:scrivener_ecto, "~> 1.3.0"},
      {:timex, "~> 3.5"},
      {:translit, "~> 0.1.0"},
      {:mox, "~> 0.3", only: :test},
      {:kaffe, "~> 1.11"},
      {:ex_machina, "~> 2.0", only: [:dev, :test]}
    ]
  end

  defp aliases do
    [
      "ecto.setup": [
        "ecto.create",
        "ecto.create --repo Core.FraudRepo",
        "ecto.create --repo Core.PRMRepo",
        "ecto.migrate"
      ],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: [
        "ecto.create --quiet",
        "ecto.create --quiet --repo Core.PRMRepo",
        "ecto.migrate",
        "test"
      ]
    ]
  end
end
