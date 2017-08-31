# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     EHealth.Repo.insert!(%EHealth.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias EHealth.Dictionaries.Dictionary
alias EHealth.Repo

"priv/repo/fixtures/dictionaries.json"
|> File.read!
|> Poison.decode!(as: [%Dictionary{}])
|> Enum.each(&Repo.insert!/1)
