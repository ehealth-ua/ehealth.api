defmodule EHealth.ReleaseTasks do
  @moduledoc """
  Nice way to apply migrations inside a released application.

  Example:

      ehealth/bin/ehealth command ehealth_tasks migrate!
  """
  alias Core.Dictionaries.Dictionary

  def migrate do
    fraud_migrations_dir = Application.app_dir(:core, "priv/fraud_repo/migrations")
    prm_migrations_dir = Application.app_dir(:core, "priv/prm_repo/migrations")
    migrations_dir = Application.app_dir(:core, "priv/repo/migrations")

    load_app()

    prm_repo = Core.PRMRepo
    prm_repo.start_link()

    Ecto.Migrator.run(prm_repo, prm_migrations_dir, :up, all: true)

    fraud_repo = Core.FraudRepo
    fraud_repo.start_link()

    Ecto.Migrator.run(fraud_repo, fraud_migrations_dir, :up, all: true)

    repo = Core.Repo
    repo.start_link()

    Ecto.Migrator.run(repo, migrations_dir, :up, all: true)

    System.halt(0)
    :init.stop()
  end

  def seed do
    load_app()

    repo = Core.Repo
    repo.start_link()

    repo.delete_all(Dictionary)

    :core
    |> Application.app_dir("priv/repo/fixtures/dictionaries.json")
    |> File.read!()
    |> Jason.decode!()
    |> Enum.map(fn item ->
      Enum.reduce(item, %{}, fn {k, v}, acc ->
        Map.put(acc, String.to_atom(k), v)
      end)
    end)
    |> Enum.map(&struct(%Dictionary{}, &1))
    |> Enum.each(&repo.insert!/1)

    System.halt(0)
    :init.stop()
  end

  defp load_app do
    start_applications([:logger, :postgrex, :ecto])
    :ok = Application.load(:core)
    :ok = Application.load(:ehealth)
  end

  defp start_applications(apps) do
    Enum.each(apps, fn app ->
      {_, _message} = Application.ensure_all_started(app)
    end)
  end
end
