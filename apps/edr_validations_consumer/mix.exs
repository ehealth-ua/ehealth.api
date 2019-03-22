defmodule EdrValidationsConsumer.MixProject do
  @moduledoc false

  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :edr_validations_consumer,
      description: "Edr validations Kafka consumer.",
      version: @version,
      elixir: "~> 1.8.1",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {EdrValidationsConsumer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jobs, in_umbrella: true},
      {:confex_config_provider, "~> 0.1.0"}
    ]
  end

  defp aliases do
    [
      "ecto.setup": fn _ -> Mix.shell().cmd("cd ../core && mix ecto.setup") end
    ]
  end
end
