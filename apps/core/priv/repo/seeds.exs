# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Core.Repo.insert!(%Core.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Core.Dictionaries.Dictionary
alias Core.Repo

# truncate table
Repo.delete_all(Dictionary)

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
|> Enum.each(&Repo.insert!/1)
