defmodule :ehealth_tasks do
  @moduledoc """
  Nice way to apply migrations inside a released application.

  Example:

      ehealth/bin/ehealth command ehealth_tasks migrate!
  """

  def migrate! do
    prm_migrations_dir = Path.join(["priv", "prm_repo", "migrations"])
    migrations_dir = Path.join(["priv", "repo", "migrations"])

    load_app()

    prm_repo = EHealth.PRMRepo
    prm_repo.start_link()

    Ecto.Migrator.run(prm_repo, prm_migrations_dir, :up, all: true)

    repo = EHealth.Repo
    repo.start_link()

    Ecto.Migrator.run(repo, migrations_dir, :up, all: true)

    System.halt(0)
    :init.stop()
  end

  defp load_app do
    start_applications([:logger, :postgrex, :ecto])
    :ok = Application.load(:ehealth)
  end

  defp start_applications(apps) do
    Enum.each(apps, fn app ->
      {_ , _message} = Application.ensure_all_started(app)
    end)
  end
end
