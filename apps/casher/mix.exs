defmodule Casher.Mixfile do
  use Mix.Project

  def project do
    [
      app: :casher,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      mod: {Casher, []},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:core, in_umbrella: true},
      {:confex, "~> 3.4"},
      {:ecto_logger_json, git: "https://github.com/edenlabllc/ecto_logger_json.git", branch: "query_params"},
      {:eview, "~> 0.12"},
      {:phoenix, "~> 1.4.0", override: true},
      {:plug_cowboy, "~> 2.0"},
      {:plug_logger_json, "~> 0.5"},
      {:redix, ">= 0.0.0"},
      {:mox, "~> 0.3", only: :test},
      {:ex_machina, "~> 2.0", only: [:dev, :test]}
    ]
  end

  defp aliases do
    [
      "ecto.setup": &ecto_setup/1
    ]
  end

  defp ecto_setup(_) do
    Mix.shell().cmd("cd ../core && mix ecto.setup")
  end
end
