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
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:jason, "~> 1.0"},
      {:httpoison, "~> 1.1.0"},
      {:plug, "~> 1.4"},
      {:confex, "~> 3.2"},
      {:mox, "~> 0.3", only: :test}
    ]
  end

  defp aliases do
    [
      test: [
        &ecto_setup/1,
        "test"
      ]
    ]
  end

  defp ecto_setup(_) do
    commands = [
      "cd ../ehealth && mix do ecto.create",
      "ecto.create --repo EHealth.PRMRepo",
      "ecto.create --repo EHealth.EventManagerRepo",
      "ecto.migrate"
    ]

    Mix.shell().cmd(Enum.join(commands, ", "))
  end
end
